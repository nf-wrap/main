#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { FASTQC } from '../../modules/nf-core/fastqc/main.nf'

// get input file or test data
input = Channel.empty()
if (params.input) input = Channel.fromFilePairs(params.input)
else if (params.test) input = Channel.fromPath(params.test_data['sarscov2']['illumina']['test_1_fastq_gz']).map{ it -> ["test", it ] }
else log.warn("No input data provided!")

// remap input to fit the module
input = input.map{ id, reads -> [ [ id:id ], reads ]}

// WORKFLOW: wrapper
workflow fastqc {
    FASTQC(input)
}

// WORKFLOW: Execute a single named workflow for the wrapper
// See: https://github.com/nf-core/rnaseq/issues/619
workflow {
    fastqc()
}
