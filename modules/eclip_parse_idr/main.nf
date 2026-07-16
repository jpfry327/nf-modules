process ECLIP_PARSE_IDR {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(idr_out), path(rep1_entropy_full), path(rep2_entropy_full)

    output:
    tuple val(meta), path("*.idr.parsed.bed"), emit: bed
    path  "versions.yml"                      , emit: versions

    // Keep peaks that overlap IDR-reproducible regions and pass l2fc >= 3 and
    // -log10p >= 3 (ENCODE merge_peaks parse step).
    script:
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def perl_dir = '/opt/merge_peaks/bin/perl'
    """
    perl ${perl_dir}/parse_idr_peaks.pl \\
        ${idr_out} \\
        ${rep1_entropy_full} \\
        ${rep2_entropy_full} \\
        ${prefix}.idr.parsed.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl -e 'print substr(\$^V, 1)')
    END_VERSIONS
    """
}
