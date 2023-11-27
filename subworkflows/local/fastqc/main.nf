// FASTQC

include { FASTQC } from '../../../modules/nf-core/fastqc/main.nf'

workflow RUN_FASTQC {
    take:
    input // channel: [mandatory] [ meta, file.fastq.gz ] or [meta, [ file_1.fastq.gz, file_2.fastq.gz ] ]

    main:
    FASTQC(input)

    emit:
    html         = FASTQC.out.html
    zip          = FASTQC.out.zip
    versions     = FASTQC.out.versions
}
