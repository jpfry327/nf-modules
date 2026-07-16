process DEEPTOOLS_BAMCOVERAGE {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.bw"), emit: bigwig
    path  "versions.yml"         , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bamCoverage \\
        --bam ${bam} \\
        --outFileName ${prefix}.bw \\
        --numberOfProcessors $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$(bamCoverage --version | sed -e "s/bamCoverage //g")
    END_VERSIONS
    """
}
