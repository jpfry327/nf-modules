process UMITOOLS_EXTRACT {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(reads)   // single-end read carrying the in-line UMI

    output:
    tuple val(meta), path("*.umi.fastq.gz"), emit: reads
    tuple val(meta), path("*.umi.log")     , emit: log
    path  "versions.yml"                    , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    umi_tools extract \\
        --stdin ${reads} \\
        --stdout ${prefix}.umi.fastq.gz \\
        --log ${prefix}.umi.log \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        umitools: \$(umi_tools --version 2>&1 | sed 's/^.*UMI-tools version: //')
    END_VERSIONS
    """
}
