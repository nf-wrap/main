// MD5SUM

include { MD5SUM } from '../../modules/nf-core/md5sum/main.nf'

workflow RUN_MD5SUM {
    take:
    input // channel: [mandatory] [ meta, file ] ]

    main:
    MD5SUM(input)
}
