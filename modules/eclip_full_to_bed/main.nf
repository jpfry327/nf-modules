process ECLIP_FULL_TO_BED {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(entropy_full)

    output:
    tuple val(meta), path("*.entropy.bed"), emit: bed
    path  "versions.yml"                  , emit: versions

    // Convert an entropy ".full" table to BED for IDR: col4 = l2fc (name),
    // col5 = entropy (score, the IDR rank).
    script:
    def args    = task.ext.args   ?: ''   // e.g. --enrichment_filter 0
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def bin_dir = '/opt/merge_peaks/bin'
    """
    python ${bin_dir}/full_to_bed.py \\
        --input ${entropy_full} \\
        --output ${prefix}.entropy.bed \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """
}
