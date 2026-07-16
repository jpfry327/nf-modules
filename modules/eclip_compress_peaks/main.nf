process ECLIP_COMPRESS_PEAKS {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(normed_full)

    output:
    tuple val(meta), path("*.compressed.bed") , emit: bed
    tuple val(meta), path("*.compressed.full"), emit: full
    path  "versions.yml"                       , emit: versions

    // Collapse overlapping normalised peaks, keeping the most significant peak
    // per cluster (ENCODE merge_peaks compress step).
    script:
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def perl_dir = '/opt/merge_peaks/bin/perl'
    """
    perl ${perl_dir}/compress_l2foldenrpeakfi_for_replicate_overlapping_bedformat_outputfull.pl \\
        ${normed_full} \\
        ${prefix}.compressed.bed \\
        ${prefix}.compressed.full

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl -e 'print substr(\$^V, 1)')
    END_VERSIONS
    """
}
