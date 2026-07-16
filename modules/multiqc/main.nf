process MULTIQC {
    label 'process_low'

    input:
    path '*'

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data"       , emit: data
    path "versions.yml"       , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    multiqc -f $args .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}
