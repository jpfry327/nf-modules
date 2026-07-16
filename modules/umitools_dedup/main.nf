process UMITOOLS_DEDUP {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.dedup.bam"), emit: bam
    tuple val(meta), path("*_stats*")   , emit: stats, optional: true
    path  "versions.yml"                 , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    umi_tools dedup \\
        -I ${bam} \\
        -S ${prefix}.dedup.bam \\
        --output-stats ${prefix}_stats \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        umitools: \$(umi_tools --version 2>&1 | sed 's/^.*UMI-tools version: //')
    END_VERSIONS
    """
}
