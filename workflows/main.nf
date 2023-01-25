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

include { RUN_FASTP  } from '../tools/fastp/main.nf'
include { RUN_FASTQC } from '../tools/fastqc/main.nf'

// For tools that use FASTQ files as input
if (params.tools && params.tools in ['fastp', 'fastqc']) {
    // Get real input file or test data
    input = Channel.empty()
    // Real input
    // fromFilePairs works also with a single file, and provides a key, which is used later as id in the meta map
    if (params.input) {
        raw_input = Channel.fromFilePairs(params.input).map{ id, reads -> [ [ id:id ], reads ] }
        end_input = raw_input.branch{ meta, reads ->
            // reads is a list, so use reads.size() to asses number of intervals
            single:   reads.size() <= 1
                return [ meta, reads ]
            pair: reads.size() > 1
        }

        input = end_input.single.map{ meta, reads -> [ meta + [single_end: true], reads ] }
            .mix(end_input.pair.map{ meta, reads -> [ meta + [single_end: false], reads ] })
    } else if (params.test) {
        // Test data
        input = Channel.fromPath(params.test_data['sarscov2']['illumina']['test_1_fastq_gz']).map{ it -> [ [ id:'test', single_end: true ], it ] }
    } else {
        // This should not happen
        log.warn("No input data provided!")
    }

}

workflow MAIN {
    if (params.tools) {
        switch (params.tools) {
            case 'fastp':
                adapter = params.adapter ? Channel.fromPath(params.adapter).collect() : Channel.value([])
                RUN_FASTP(input, adapter, params.save_trimmed_fail, params.save_merged)
                break
            case 'fastqc':
                RUN_FASTQC(input)
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
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
