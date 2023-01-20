#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { FASTQC } from '../../modules/nf-core/fastqc/main.nf'

workflow fastqc {
    input = params.input ?: params.test_data['sarscov2']['illumina']['test_1_fastq_gz']

    println "Input: " + input

    input = [
                [ id:'test', single_end:true ], // meta map
                [
                    file(input, checkIfExists: true)
                ]
            ]

    FASTQC ( input )
}

workflow {
    fastqc()
}
