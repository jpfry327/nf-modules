process ECLIP_PEAK_ENTROPY {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(compressed_full), path(clip_reads), path(input_reads)

    output:
    tuple val(meta), path("*.entropy.full") , emit: full
    tuple val(meta), path("*.excess_reads") , emit: excess
    path  "versions.yml"                     , emit: versions

    // Information-content (entropy) per peak: pi * log2(pi/qi), where pi/qi are the
    // CLIP/input read fractions. Entropy is the ranking metric handed to IDR.
    script:
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def perl_dir = '/opt/merge_peaks/bin/perl'
    """
    perl ${perl_dir}/make_informationcontent_from_peaks.pl \\
        ${compressed_full} \\
        ${clip_reads} \\
        ${input_reads} \\
        ${prefix}.entropy.full \\
        ${prefix}.excess_reads

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl -e 'print substr(\$^V, 1)')
    END_VERSIONS
    """
}
