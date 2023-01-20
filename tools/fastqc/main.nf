#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { FASTQC } from '../../modules/nf-core/fastqc/main.nf'

// get input file or test data
input = params.input ? Channel.fromPath(params.input) : params.test ? Channel.fromPath(params.test_data['sarscov2']['illumina']['test_1_fastq_gz']) : Channel.empty()

// remap input to fit the module
input = input.map{ reads -> [ [ id:'test', single_end:true ], reads ]}

// WORKFLOW: wrapper
workflow fastqc {
    FASTQC(input)
}

// WORKFLOW: Execute a single named workflow for the wrapper
// See: https://github.com/nf-core/rnaseq/issues/619
workflow {
    fastqc()
}
