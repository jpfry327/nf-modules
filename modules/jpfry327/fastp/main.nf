process FASTP {
    tag "$meta.id"
    label 'process_medium'

    // Single image for docker and singularity (Nextflow prefixes docker:// as needed).
    // Override per pipeline in conf/modules.config: withName: 'FASTP' { container = '...' }
    container 'community.wave.seqera.io/library/fastp:1.3.6--4df8d6c11b471bde'

    input:
    tuple val(meta), path(reads)   // expects [ read1, read2 ]

    output:
    tuple val(meta), path("*.trim.fastq.gz"), emit: reads
    tuple val(meta), path("*.fastp.json")   , emit: json
    tuple val(meta), path("*.fastp.html")   , emit: html
    path  "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fastp \\
        --in1 ${reads[0]} \\
        --in2 ${reads[1]} \\
        --out1 ${prefix}_1.trim.fastq.gz \\
        --out2 ${prefix}_2.trim.fastq.gz \\
        --json ${prefix}.fastp.json \\
        --html ${prefix}.fastp.html \\
        --thread $task.cpus \\
        $args \\
        2> ${prefix}.fastp.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo '' | gzip > ${prefix}_1.trim.fastq.gz
    echo '' | gzip > ${prefix}_2.trim.fastq.gz
    touch ${prefix}.fastp.json
    touch ${prefix}.fastp.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: stub
    END_VERSIONS
    """
}
