// FASTP

include { FASTP } from '../../../modules/nf-core/fastp/main.nf'

workflow RUN_FASTP {
    take:
    input             // channel: [mandatory] [ meta, file.fastq.gz ] or [meta, [ file_1.fastq.gz, file_2.fastq.gz ] ]
    adapter           // channel: [optional] [ adapter_fasta ]
    save_trimmed_fail // boolean: [optional] save trimmed fail files
    save_merged       // boolean: [optional] save merged files

    main:
    FASTP(input, adapter, save_trimmed_fail, save_merged)

    emit:
    html         = FASTP.out.html
    json         = FASTP.out.json
    logs         = FASTP.out.log
    reads        = FASTP.out.reads
    reads_fail   = FASTP.out.reads_fail
    reads_merged = FASTP.out.reads_merged
    versions     = FASTP.out.versions
}
