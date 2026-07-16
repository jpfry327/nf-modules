process STAR_ALIGN {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(reads)   // single-end: 1 file; paired-end: [ read1, read2 ]
    path  index                    // STAR genome index directory
    path  gtf                      // annotation for splice junctions; pass [] to skip

    output:
    tuple val(meta), path("*Aligned*.bam")        , emit: bam
    tuple val(meta), path("*Unmapped.out.mate*")  , emit: unmapped   , optional: true
    tuple val(meta), path("*Log.final.out")       , emit: log_final
    tuple val(meta), path("*ReadsPerGene.out.tab"), emit: gene_counts, optional: true
    path  "versions.yml"                          , emit: versions

    script:
    def args    = task.ext.args   ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def reads_in = meta.single_end ? "${reads}" : "${reads[0]} ${reads[1]}"
    def gtf_arg  = gtf ? "--sjdbGTFfile ${gtf}" : ''
    // Decompression is a tool option: set --readFilesCommand zcat via ext.args for
    // gzipped input, and leave it out when reading uncompressed reads (e.g. STAR
    // Unmapped.out.mate FASTX passed between alignment stages).
    """
    STAR \\
        --genomeDir $index \\
        --readFilesIn $reads_in \\
        --runThreadN $task.cpus \\
        --outFileNamePrefix ${prefix}. \\
        $gtf_arg \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version)
    END_VERSIONS
    """
}
