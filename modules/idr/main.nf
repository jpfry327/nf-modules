process IDR {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(rep1_bed), path(rep2_bed)

    output:
    tuple val(meta), path("*.idr.out")     , emit: idr
    tuple val(meta), path("*.idr.out.png") , emit: plot, optional: true
    path  "versions.yml"                   , emit: versions

    script:
    def args   = task.ext.args   ?: ''   // e.g. --idr-threshold 0.01 --plot
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    idr \\
        --samples ${rep1_bed} ${rep2_bed} \\
        --input-file-type bed \\
        --rank score \\
        --output-file ${prefix}.idr.out \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        idr: \$(idr --version 2>&1 | sed 's/IDR //')
    END_VERSIONS
    """
}
