process MACS2_CALLPEAK {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(ipbam), path(controlbam)
    val   macs2_gsize

    output:
    tuple val(meta), path("*.narrowPeak"), emit: peak,      optional: true
    tuple val(meta), path("*.broadPeak") , emit: broadpeak, optional: true
    tuple val(meta), path("*_peaks.xls") , emit: xls
    path  "versions.yml"                 , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    macs2 callpeak \\
        --treatment $ipbam \\
        --control $controlbam \\
        --format BAMPE \\
        --gsize $macs2_gsize \\
        --name $prefix \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        macs2: \$(macs2 --version 2>&1 | sed 's/macs2 //')
    END_VERSIONS
    """
}
