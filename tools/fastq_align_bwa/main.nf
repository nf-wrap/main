// BWAMEM

include { FASTQ_ALIGN_BWA } from '../../subworkflows/nf-core/fastq_align_bwa/main.nf'

workflow RUN_BWAMEM {
    take:
    reads             // channel: [mandatory] [ meta, [ reads ] ]
    bwa               // channel: [mandatory] [ meta, [ index ]  ]
    sort_bam          // val
    fasta             // channel: [optional] [ fasta ]

    main:
    FASTQ_ALIGN_BWA(reads, bwa, sort_bam, fasta)
}
