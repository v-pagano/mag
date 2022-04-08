include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process bwaHostRemoval {

    publishDir "${params.outdir}/",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'bwa', meta:meta, publish_by_meta:['id']) }

    container "docker://quay.io/biocontainers/bwa:0.7.17--h7132678_9"

    input:
        tuple val(meta), path(reads)
        path index

    output:
        tuple val(meta), path("${meta.id}_bwa.bam")          , emit: bam
        tuple val(meta), path("*.bwa.log")                   , emit: log

    script:

    """
    	bwa mem play/combined.fna ${reads[0]} ${reads[1]} -t ${task.cpus} -R "@RG\\tID:${meta.id}\\tSM:${meta.id}" -M 2>${meta.id}.bwa.log > ${meta.id}_bwa.bam
    """
}

process samtoolsSort {

    publishDir "${params.outdir}/",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'samtools', meta:meta, publish_by_meta:['id']) }

    container "docker://quay.io/biocontainers/samtools:1.6--hcd7b337_9"

    input:
        tuple val(meta), path(bam)

    output:
        tuple val(meta), path("${meta.id}_host_aligned.sam") , emit: bam

    script:

    """
		samtools sort ${bam} -O sam --threads ${task.cpus} > ${meta.id}_host_aligned.sam
    """
}

process getCoverage {

    input:
        tuple val(meta), path(bam)

    output:
        path "${meta.id}_coverage.txt", emit: coverage

    container 'docker://quay.io/biocontainers/perl-perl-version:1.013--pl5321hdfd78af_4'

    script:
    """
       	cat ${bam} | SAM_to_alignment_info.pl | perl -lanF/"\\t"/ -e 'if (\$F[1]>=${params.idMin} && \$F[2]>=${params.coverageMin}) {print \$F[0]}' > ${meta.id}_coverage.txt 
    """

}

process filterFastq {

    input:
        tuple val(meta), path(reads)
        path coverage

    output:
        tuple val(meta), path("*_filtered.fastq.gz"), emit: reads

    container 'docker://quay.io/biocontainers/perl-perl-version:1.013--pl5321hdfd78af_4'

    script:
    """
        zcat ${reads[0]} | filter_by_id.pl -include ${coverage} -v | gzip > ${reads[0].simpleName}_filtered.fastq.gz
        zcat ${reads[1]} | filter_by_id.pl -include ${coverage} -v | gzip > ${reads[1].simpleName}_filtered.fastq.gz
    """

}

workflow SEQMORE_HOST_REMOVAL {
    
    take:
        reads
        index

    main:
        bwaHostRemoval(reads, index)
        samtoolsSort(bwaHostRemoval.out.bam)
        getCoverage(samtoolsSort.out.bam)
        filterFastq(reads, getCoverage.out.coverage)

    emit:
        reads = filterFastq.out.reads
        bwaLog = bwaHostRemoval.out.log


}