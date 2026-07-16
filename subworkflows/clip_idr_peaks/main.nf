//
// ENCODE eCLIP peak calling + IDR reproducible peaks.
//
// Reproduces the ENCODE eCLIP SOP / merge_peaks (v0.1.0) flow for a 2-replicate
// experiment with size-matched input (SMInput):
//   1. CLIPper peak calling per replicate
//   2. count mapped reads (CLIP + input) per replicate
//   3. input normalisation of CLIPper peaks against SMInput
//   4. compress overlapping peaks
//   5. per-peak entropy (information content)
//   6. entropy .full -> BED for IDR
//   7. IDR across the two replicates
//   8. parse IDR-reproducible peaks
//   9. re-normalise over the IDR peak positions
//  10. reproducible peak set (geomean l2fc / -log10p thresholds in both reps)
//
// Every channel is [ meta, files ]. The per-experiment meta.id groups the two
// replicates; per-replicate meta adds `experiment` and `replicate` so the
// steps can be split apart and rejoined.
//
include { CLIPPER                   } from '../../modules/clipper/main'
include { ECLIP_COUNT_READS         } from '../../modules/eclip_count_reads/main'
include { ECLIP_INPUT_NORM          } from '../../modules/eclip_input_norm/main'
include { ECLIP_INPUT_NORM as ECLIP_IDR_NORM } from '../../modules/eclip_input_norm/main'
include { ECLIP_COMPRESS_PEAKS      } from '../../modules/eclip_compress_peaks/main'
include { ECLIP_PEAK_ENTROPY        } from '../../modules/eclip_peak_entropy/main'
include { ECLIP_FULL_TO_BED         } from '../../modules/eclip_full_to_bed/main'
include { IDR                       } from '../../modules/idr/main'
include { ECLIP_PARSE_IDR           } from '../../modules/eclip_parse_idr/main'
include { ECLIP_REPRODUCIBLE_PEAKS  } from '../../modules/eclip_reproducible_peaks/main'

workflow CLIP_IDR_PEAKS {

    take:
    // [ meta, [clip_rep1_bam, clip_rep1_bai], [clip_rep2_bam, clip_rep2_bai],
    //         [input_rep1_bam, input_rep1_bai], [input_rep2_bam, input_rep2_bai] ]
    // meta.id identifies the experiment (RBP / condition).
    ch_replicates

    main:
    ch_versions = Channel.empty()

    //
    // Split each experiment into two per-replicate records:
    //   [ meta_rep, clip_bam, clip_bai, input_bam, input_bai ]
    //
    ch_reps = ch_replicates.flatMap { meta, clip1, clip2, input1, input2 ->
        [
            [ meta + [ id: "${meta.id}.rep1", experiment: meta.id, replicate: 1 ], clip1[0], clip1[1], input1[0], input1[1] ],
            [ meta + [ id: "${meta.id}.rep2", experiment: meta.id, replicate: 2 ], clip2[0], clip2[1], input2[0], input2[1] ]
        ]
    }

    //
    // 1. CLIPper peak calling (CLIP bam only)
    //
    CLIPPER( ch_reps.map { meta, cb, ci, ib, ii -> [ meta, cb, ci ] } )
    ch_versions = ch_versions.mix( CLIPPER.out.versions.first() )

    //
    // 2. Mapped-read counts (CLIP + input)
    //
    ECLIP_COUNT_READS( ch_reps )
    ch_versions = ch_versions.mix( ECLIP_COUNT_READS.out.versions.first() )

    //
    // 3. Input normalisation of CLIPper peaks against SMInput
    //
    ch_norm_in = ch_reps
        .join( ECLIP_COUNT_READS.out.counts )   // + clip_reads, input_reads
        .join( CLIPPER.out.peaks )              // + peaks
        .map { meta, cb, ci, ib, ii, clip_reads, input_reads, peaks ->
            [ meta, cb, ci, ib, ii, peaks, clip_reads, input_reads ]
        }
    ECLIP_INPUT_NORM( ch_norm_in )
    ch_versions = ch_versions.mix( ECLIP_INPUT_NORM.out.versions.first() )

    //
    // 4. Compress overlapping peaks
    //
    ECLIP_COMPRESS_PEAKS( ECLIP_INPUT_NORM.out.full )
    ch_versions = ch_versions.mix( ECLIP_COMPRESS_PEAKS.out.versions.first() )

    //
    // 5. Per-peak entropy (needs compressed .full + read counts)
    //
    ch_entropy_in = ECLIP_COMPRESS_PEAKS.out.full
        .join( ECLIP_COUNT_READS.out.counts )   // + clip_reads, input_reads
    ECLIP_PEAK_ENTROPY( ch_entropy_in )
    ch_versions = ch_versions.mix( ECLIP_PEAK_ENTROPY.out.versions.first() )

    //
    // 6. entropy .full -> BED for IDR
    //
    ECLIP_FULL_TO_BED( ECLIP_PEAK_ENTROPY.out.full )
    ch_versions = ch_versions.mix( ECLIP_FULL_TO_BED.out.versions.first() )

    //
    // Regroup the two replicates by experiment, ordered rep1 then rep2, carrying
    // both the entropy BED (for IDR) and the entropy .full (for downstream steps).
    //
    ch_by_experiment = ECLIP_FULL_TO_BED.out.bed
        .join( ECLIP_PEAK_ENTROPY.out.full )                      // [ meta_rep, entropy_bed, entropy_full ]
        .map { meta, bed, full -> [ meta.experiment, meta.replicate, bed, full ] }
        .groupTuple()                                             // [ exp, [reps], [beds], [fulls] ]
        .map { exp, reps, beds, fulls ->
            def order = (0..<reps.size()).sort { reps[it] }       // indices ordered by replicate number
            [ [ id: exp ], beds[order[0]], beds[order[1]], fulls[order[0]], fulls[order[1]] ]
        }

    //
    // 7. IDR across replicates
    //
    IDR( ch_by_experiment.map { meta, bed1, bed2, full1, full2 -> [ meta, bed1, bed2 ] } )
    ch_versions = ch_versions.mix( IDR.out.versions.first() )

    //
    // 8. Parse IDR-reproducible peaks (needs idr.out + both entropy .full)
    //
    ch_parse_in = IDR.out.idr
        .join( ch_by_experiment.map { meta, bed1, bed2, full1, full2 -> [ meta, full1, full2 ] } )
    ECLIP_PARSE_IDR( ch_parse_in )
    ch_versions = ch_versions.mix( ECLIP_PARSE_IDR.out.versions.first() )

    //
    // 9. Re-normalise each replicate over the IDR peak positions. The parsed IDR
    //    BED is per-experiment, so fan it back out to both replicates.
    //
    ch_idr_norm_in = ch_reps
        .join( ECLIP_COUNT_READS.out.counts )                     // [ meta_rep, cb, ci, ib, ii, clip_reads, input_reads ]
        .map { meta, cb, ci, ib, ii, clip_reads, input_reads ->
            [ meta.experiment, meta, cb, ci, ib, ii, clip_reads, input_reads ]
        }
        .combine( ECLIP_PARSE_IDR.out.bed.map { meta, bed -> [ meta.id, bed ] }, by: 0 )
        .map { exp, meta, cb, ci, ib, ii, clip_reads, input_reads, idr_bed ->
            [ meta, cb, ci, ib, ii, idr_bed, clip_reads, input_reads ]
        }
    ECLIP_IDR_NORM( ch_idr_norm_in )
    ch_versions = ch_versions.mix( ECLIP_IDR_NORM.out.versions.first() )

    //
    // 10. Reproducible peak set. Regroup the IDR-normed .full per experiment,
    //     then join with the entropy .full pair and idr.out.
    //
    ch_idr_normed_by_exp = ECLIP_IDR_NORM.out.full
        .map { meta, full -> [ meta.experiment, meta.replicate, full ] }
        .groupTuple()
        .map { exp, reps, fulls ->
            def order = (0..<reps.size()).sort { reps[it] }
            [ [ id: exp ], fulls[order[0]], fulls[order[1]] ]
        }

    ch_repro_in = ch_idr_normed_by_exp
        .join( ch_by_experiment.map { meta, bed1, bed2, full1, full2 -> [ meta, full1, full2 ] } )
        .join( IDR.out.idr )
        .map { meta, idr_full1, idr_full2, ent_full1, ent_full2, idr_out ->
            [ meta, idr_full1, idr_full2, ent_full1, ent_full2, idr_out ]
        }
    ECLIP_REPRODUCIBLE_PEAKS( ch_repro_in )
    ch_versions = ch_versions.mix( ECLIP_REPRODUCIBLE_PEAKS.out.versions.first() )

    emit:
    clipper_peaks     = CLIPPER.out.peaks                    // [ meta_rep, bed ]
    idr_out           = IDR.out.idr                          // [ meta_exp, idr.out ]
    idr_peaks         = ECLIP_PARSE_IDR.out.bed              // [ meta_exp, idr.parsed.bed ]
    reproducible_bed  = ECLIP_REPRODUCIBLE_PEAKS.out.bed     // [ meta_exp, reproducible_peaks.bed ]
    reproducible_full = ECLIP_REPRODUCIBLE_PEAKS.out.custombed
    versions          = ch_versions
}
