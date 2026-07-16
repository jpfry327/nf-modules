process CUTADAPT {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(reads)   // single-end: 1 file; paired-end: [ read1, read2 ]

    output:
    tuple val(meta), path("*.trim.fastq.gz"), emit: reads
    tuple val(meta), path("*.cutadapt.log") , emit: log
    path  "versions.yml"                     , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if (meta.single_end) {
        """
        cutadapt \\
            $args \\
            -o ${prefix}.trim.fastq.gz \\
            ${reads} \\
            > ${prefix}.cutadapt.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cutadapt: \$(cutadapt --version)
        END_VERSIONS
        """
    } else {
        """
        cutadapt \\
            $args \\
            -o ${prefix}_1.trim.fastq.gz \\
            -p ${prefix}_2.trim.fastq.gz \\
            ${reads[0]} ${reads[1]} \\
            > ${prefix}.cutadapt.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cutadapt: \$(cutadapt --version)
        END_VERSIONS
        """
    }
}
