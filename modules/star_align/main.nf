process STAR_ALIGN {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(reads)   // [ read1, read2 ]
    path  index                    // STAR genome index directory
    path  gtf                      // annotation used for splice junctions

    output:
    tuple val(meta), path("*Aligned.sortedByCoord.out.bam"), emit: bam
    tuple val(meta), path("*Log.final.out")                , emit: log_final
    tuple val(meta), path("*ReadsPerGene.out.tab")         , emit: gene_counts, optional: true
    path  "versions.yml"                                    , emit: versions

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
}
