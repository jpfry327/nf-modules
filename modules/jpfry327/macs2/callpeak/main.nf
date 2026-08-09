process MACS2_CALLPEAK {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/macs2:2.2.9.1--py39hff71179_1'
        : 'quay.io/biocontainers/macs2:2.2.9.1--py39hff71179_1' }"

    input:
    tuple val(meta), path(ipbam), path(controlbam)
    val   macs2_gsize

    output:
    tuple val(meta), path("*.narrowPeak"), emit: peak,      optional: true
    tuple val(meta), path("*.broadPeak") , emit: broadpeak, optional: true
    tuple val(meta), path("*_peaks.xls") , emit: xls
    path  "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

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

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_peaks.narrowPeak
    touch ${prefix}_peaks.xls

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        macs2: stub
    END_VERSIONS
    """
}
