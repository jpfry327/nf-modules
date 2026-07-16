process CLIPPER {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.peakClusters.bed"), emit: peaks
    path  "versions.yml"                        , emit: versions

    script:
    def args   = task.ext.args   ?: ''   // e.g. --species GRCh38
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    clipper \\
        --bam ${bam} \\
        --outfile ${prefix}.peakClusters.bed \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        clipper: \$(clipper --version 2>&1 | sed 's/^.*clipper //; s/ .*\$//' || echo unknown)
    END_VERSIONS
    """
}
