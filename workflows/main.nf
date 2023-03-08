/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
// WorkflowMain.initialise(params, log)

// Check input path parameters to see if they exist
// def checkPathParamList = [
//     params.input,
//     params.test
// ]
// for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// // Check mandatory parameters
// if (params.input) { input = file(params.input) } else { exit 1, 'Input not specified!' }

// MODULES
include { BWA_INDEX }      from '../modules/nf-core/bwa/index/main.nf'

// NF-WRAP WRAPPERS
include { RUN_BWAMEM }     from '../tools/fastq_align_bwa/main.nf'
include { RUN_FASTP }      from '../tools/fastp/main.nf'
include { RUN_FASTQC }     from '../tools/fastqc/main.nf'
include { RUN_MD5SUM }     from '../tools/md5sum/main.nf'
include { RUN_TRIMGALORE } from '../tools/trimgalore/main.nf'
include { RUN_VEP }        from '../tools/vcf_annotate_ensemblvep/main.nf'

if (params.test) {
    params.fasta = params.test_data['sarscov2']['genome']['genome_fasta']
    params.bwa = null
}

// For tools that use FASTQ files as input
if (params.tools && params.tools in ['bwamem', 'fastp', 'fastqc', 'md5sum', 'trimgalore']) {
    // Get real input file or test data
    input = Channel.empty()
    // Real input
    // fromFilePairs works also with a single file, and provides a key, which is used later as id in the meta map
    if (params.input && params.input.toString().endsWith('csv')) {
        input = extract_csv(file(params.input, checkIfExists: true))
    } else if (params.input && !params.input.toString().endsWith('csv')) {
        raw_input = Channel.fromFilePairs(params.input, size: -1).map{ id, reads -> [ [ id:id ], reads ] }
        end_input = raw_input.branch{ meta, reads ->
            // reads is a list, so use reads.size() to asses number of intervals
            single:   reads.size() <= 1
                return [ meta, reads ]
            pair: reads.size() > 1
        }

        input = end_input.single.map{ meta, reads -> [ meta + [ single_end: true ], reads ] }
            .mix(end_input.pair.map{ meta, reads -> [ meta + [ single_end: false ], reads ] })
    } else if (params.test) {
        // Test data
        input = Channel.fromPath(params.test_data['sarscov2']['illumina']['test_1_fastq_gz'])
            .map{ it -> [ [ id:'test_single', single_end: true ], it ] }
            .mix(Channel.fromPath(params.test_data['sarscov2']['illumina']['test_1_fastq_gz']).map{ it -> [ [ id:'test_pair' ], it ] }
                .join(Channel.fromPath(params.test_data['sarscov2']['illumina']['test_2_fastq_gz']).map{ it -> [ [ id:'test_pair' ], it ] })
                .map{ meta, fastq_1, fastq_2 -> [ meta + [ single_end: false ], [fastq_1, fastq_2] ] })
    } else {
        // This should not happen
        log.warn("No input data provided!")
    }
// For tools that use VCF files as input
} else if (params.tools && params.tools in ['vep']) {
    // Get real input file or test data
    input = Channel.empty()
    // Real input
    if (params.input && params.input.toString().endsWith('csv')) {
        input = extract_csv(file(params.input, checkIfExists: true))
    } else if (params.input && !params.input.toString().endsWith('csv')) {
        input = Channel.fromPath(params.input).map{ vcf -> [ [ id:vcf.simpleName() ], vcf ] }
    } else if (params.test) {
        // Test data
        input = Channel.fromPath(params.test_data['sarscov2']['illumina']['test_vcf_gz'])
            .map{ it -> [ [ id:'test_vcf_gz' ], it ] }
    } else {
        // This should not happen
        log.warn("No input data provided!")
    }

}

workflow MAIN {
    if (params.tools) {
        switch (params.tools) {
            case 'bwamem':
                fasta = params.test ? Channel.fromPath(params.test_data['sarscov2']['genome']['genome_fasta']) : params.fasta ? Channel.fromPath(params.fasta) : Channel.value([])
                bwa = params.test ? BWA_INDEX(fasta.map{ fasta -> [ [ id:'fasta' ], fasta ] }).index.collect() : params.bwa ?: BWA_INDEX(fasta.map{ fasta -> [ [ id:'fasta' ], fasta ] }).index.collect()
                RUN_BWAMEM(input, bwa, false, fasta)
                break
            case 'fastp':
                adapter = params.adapter ? Channel.fromPath(params.adapter).collect() : Channel.value([])
                save_trimmed_fail = params.save_trimmed_fail ? true : false
                save_merged = params.save_merged ? true : false
                RUN_FASTP(input, adapter, save_trimmed_fail, save_merged)
                break
            case 'fastqc':
                RUN_FASTQC(input)
                break
            case 'md5sum':
                input = input.map{ meta, files -> files }.flatten().map{ file -> [ [id:file.baseName], file ] }
                RUN_MD5SUM(input)
                break
            case 'trimgalore':
                RUN_TRIMGALORE(input)
                break
            case 'vep':
                vep_cache_version  = params.vep_cache_version  ?: Channel.empty()
                vep_genome         = params.vep_genome         ?: Channel.empty()
                vep_species        = params.vep_species        ?: Channel.empty()
                vep_cache          = params.vep_cache          ? Channel.fromPath(params.vep_cache).collect() : []
                vep_fasta          = params.vep_include_fasta  ? Channel.fromPath(params.fasta).collect() : []
                RUN_VEP(input, vep_fasta, vep_genome, vep_species, vep_cache_version, vep_cache, [])
                break
            default:
                println "No tool selected"
        }
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Function to extract information (meta data + file(s)) from csv file(s)
def extract_csv(csv_file) {
    // check that the sample sheet is not 1 line or less, because it'll skip all subsequent checks if so.
    file(csv_file).withReader('UTF-8') { reader ->
        def line, samplesheet_line_count = 0;
        while ((line = reader.readLine()) != null) {samplesheet_line_count++}
        if (samplesheet_line_count < 2) {
            log.error "Samplesheet had less than two lines. The sample sheet must be a csv file with a header, so at least two lines."
            System.exit(1)
        }
    }

    Channel.of(csv_file).splitCsv(header: true)
        .map{ row ->

        def meta = [:]

        // Meta data to identify samplesheet
        // Sample is mandatory
        if (row.sample) meta.id  = row.sample.toString()

        if (row.fastq_1 && row.fastq_2) {
            def fastq_1     = file(row.fastq_1, checkIfExists: true)
            def fastq_2     = file(row.fastq_2, checkIfExists: true)

            return [ meta, [ fastq_1, fastq_2 ] ]
        } else if (row.fastq_1) {
            meta.single_end = true
            def fastq_1     = file(row.fastq_1, checkIfExists: true)

            return [ meta, fastq_1 ]
        } else if (row.vcf) {
            def vcf     = file(row.vcf, checkIfExists: true)

            return [ meta, vcf ]
        } else {
            log.error "Missing or unknown field in csv file header. Please check your samplesheet"
            System.exit(1)
        }
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
