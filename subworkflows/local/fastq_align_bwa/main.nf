// BWAMEM

include { FASTQ_ALIGN_BWA } from '../../nf-core/fastq_align_bwa/main.nf'

workflow RUN_BWAMEM {
    take:
    reads             // channel: [mandatory] [ meta, [ reads ] ]
    bwa               // channel: [mandatory] [ meta, [ index ]  ]
    sort_bam          // val
    fasta             // channel: [optional] [ fasta ]

    main:
    FASTQ_ALIGN_BWA(reads, bwa, sort_bam, fasta)

    emit:
    bai      = FASTQ_ALIGN_BWA.out.bai
    bam      = FASTQ_ALIGN_BWA.out.bam
    bam_orig = FASTQ_ALIGN_BWA.out.bam_orig
    csi      = FASTQ_ALIGN_BWA.out.csi
    flagstat = FASTQ_ALIGN_BWA.out.flagstat
    idxstats = FASTQ_ALIGN_BWA.out.idxstats
    stats    = FASTQ_ALIGN_BWA.out.stats
    versions = FASTQ_ALIGN_BWA.out.versions
}
