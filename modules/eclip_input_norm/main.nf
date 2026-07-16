process ECLIP_INPUT_NORM {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(clip_bam), path(clip_bai), path(input_bam), path(input_bai), path(peaks), path(clip_reads), path(input_reads)

    output:
    tuple val(meta), path("*.normed.bed")     , emit: bed
    tuple val(meta), path("*.normed.bed.full"), emit: full
    path  "versions.yml"                       , emit: versions

    // Normalise CLIPper peaks against the size-matched input (SMInput) with the
    // ENCODE merge_peaks overlap script. A ".full" file is written automatically
    // alongside the ".bed" output.
    script:
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def perl_dir = '/opt/merge_peaks/bin/perl'
    """
    perl ${perl_dir}/overlap_peakfi_with_bam.pl \\
        ${clip_bam} \\
        ${input_bam} \\
        ${peaks} \\
        ${clip_reads} \\
        ${input_reads} \\
        ${prefix}.normed.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl -e 'print substr(\$^V, 1)')
    END_VERSIONS
    """
}
