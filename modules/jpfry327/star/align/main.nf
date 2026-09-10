process STAR_ALIGN {
    tag "$meta.id"
    label 'process_high'

    // Single image for docker and singularity (Nextflow prefixes docker:// as needed).
    // Override per pipeline in conf/modules.config: withName: 'STAR_ALIGN' { container = '...' }
    container 'community.wave.seqera.io/library/htslib_samtools_star_gawk:ae438e9a604351a4'

    input:
    tuple val(meta), path(reads)   // [ read1, read2 ]
    path  index                    // STAR genome index directory
    path  gtf                      // annotation used for splice junctions

    output:
    tuple val(meta), path("*Aligned.sortedByCoord.out.bam"), emit: bam
    tuple val(meta), path("*Log.final.out")                , emit: log_final
    tuple val(meta), path("*ReadsPerGene.out.tab")         , emit: gene_counts, optional: true
    path  "versions.yml"                                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    STAR \\
        --genomeDir $index \\
        --readFilesIn ${reads[0]} ${reads[1]} \\
        --readFilesCommand zcat \\
        --runThreadN $task.cpus \\
        --sjdbGTFfile $gtf \\
        --outSAMtype BAM SortedByCoordinate \\
        --outFileNamePrefix ${prefix}. \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.Aligned.sortedByCoord.out.bam
    touch ${prefix}.Log.final.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: stub
    END_VERSIONS
    """
}
