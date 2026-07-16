process ECLIP_COUNT_READS {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(clip_bam), path(clip_bai), path(input_bam), path(input_bai)

    output:
    tuple val(meta), path("*.clip.readnum.txt"), path("*.input.readnum.txt"), emit: counts
    path  "versions.yml"                                                     , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools view -cF 4 ${clip_bam}  > ${prefix}.clip.readnum.txt
    samtools view -cF 4 ${input_bam} > ${prefix}.input.readnum.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """
}
