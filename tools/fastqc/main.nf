// FASTQC

include { FASTQC } from '../../modules/nf-core/fastqc/main.nf'

workflow RUN_FASTQC {
    take:
    reads // channel: [mandatory] [file.fastq.gz] or [file_1.fastq.gz, file_2.fastq.gz]

    main:
    // Get real input file or test data
    input = Channel.empty()
    // Real input
    // fromFilePairs works also with a single file, and provides a key, which is used later as id in the meta map
    if (reads) input = Channel.fromFilePairs(reads)
    // Test data
    else if (params.test) input = Channel.fromPath(params.test_data['sarscov2']['illumina']['test_1_fastq_gz']).map{ it -> ["test", it ] }
    // This should not happen
    else log.warn("No input data provided!")

    // remap input to fit the module
    input = input.map{ id, reads -> [ [ id:id ], reads ]}

    FASTQC(input)
}
