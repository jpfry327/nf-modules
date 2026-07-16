//
// Trim reads, align to the genome with STAR, index the BAM.
// Reusable across any paired-end RNA assay (RIP-seq, RNA-seq, CLIP, ...).
//
include { FASTP          } from '../../modules/fastp/main'
include { STAR_ALIGN     } from '../../modules/star_align/main'
include { SAMTOOLS_INDEX } from '../../modules/samtools_index/main'

workflow FASTQ_ALIGN_STAR {

    take:
    ch_reads   // channel: [ val(meta), [ read1, read2 ] ]
    ch_index   // channel: path(star_index)
    ch_gtf     // channel: path(gtf)

    main:
    ch_versions = Channel.empty()

    FASTP( ch_reads )
    ch_versions = ch_versions.mix( FASTP.out.versions.first() )

    STAR_ALIGN( FASTP.out.reads, ch_index, ch_gtf )
    ch_versions = ch_versions.mix( STAR_ALIGN.out.versions.first() )

    SAMTOOLS_INDEX( STAR_ALIGN.out.bam )
    ch_versions = ch_versions.mix( SAMTOOLS_INDEX.out.versions.first() )

    emit:
    bam        = STAR_ALIGN.out.bam        // [ meta, bam ]
    bai        = SAMTOOLS_INDEX.out.bai    // [ meta, bai ]
    fastp_json = FASTP.out.json            // [ meta, json ]
    star_log   = STAR_ALIGN.out.log_final  // [ meta, log ]
    versions   = ch_versions
}
