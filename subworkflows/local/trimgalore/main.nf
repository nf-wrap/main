// FASTP

include { TRIMGALORE } from '../../../modules/nf-core/trimgalore/main.nf'

workflow RUN_TRIMGALORE {
    take:
    input             // channel: [mandatory] [ meta, file.fastq.gz ] or [meta, [ file_1.fastq.gz, file_2.fastq.gz ] ]

    main:
    TRIMGALORE(input)

    emit:
    reads    = TRIMGALORE.out.reads
    logs     = TRIMGALORE.out.log
    unpaired = TRIMGALORE.out.unpaired
    html     = TRIMGALORE.out.html
    zip      = TRIMGALORE.out.zip
    versions = TRIMGALORE.out.versions

}
