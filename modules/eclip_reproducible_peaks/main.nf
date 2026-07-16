process ECLIP_REPRODUCIBLE_PEAKS {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(rep1_idr_normed_full), path(rep2_idr_normed_full), path(rep1_entropy_full), path(rep2_entropy_full), path(idr_out)

    output:
    tuple val(meta), path("*.reproducible_peaks.bed")      , emit: bed
    tuple val(meta), path("*.reproducible_peaks.custombed"), emit: custombed
    tuple val(meta), path("*.reproducing.full")            , emit: reproducing_full, optional: true
    path  "versions.yml"                                    , emit: versions

    // Final ENCODE reproducible peak set: geomean(l2fc) >= 3 and -log10p >= 3 in
    // both replicates over the IDR-reproducible regions.
    script:
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def perl_dir = '/opt/merge_peaks/bin/perl'
    """
    perl ${perl_dir}/get_reproducing_peaks.pl \\
        ${rep1_idr_normed_full} \\
        ${rep2_idr_normed_full} \\
        ${prefix}.rep1.reproducing.full \\
        ${prefix}.rep2.reproducing.full \\
        ${prefix}.reproducible_peaks.bed \\
        ${prefix}.reproducible_peaks.custombed \\
        ${rep1_entropy_full} \\
        ${rep2_entropy_full} \\
        ${idr_out}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl -e 'print substr(\$^V, 1)')
    END_VERSIONS
    """
}
