#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { FASTQC } from '../../modules/nf-core/fastqc/main.nf'

workflow fastqc {
    input = params.input ? Channel.fromPath(params.input) : params.test ? Channel.fromPath(params.test_data['sarscov2']['illumina']['test_1_fastq_gz']) : Channel.empty()

    input = input.map{ reads -> [ [ id:'test', single_end:true ], reads ]}

    FASTQC(input)
}

workflow {
    fastqc()
}
