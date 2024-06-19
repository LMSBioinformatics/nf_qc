#!/usr/bin/env nextflow

/*
-------------------------------------------------------------------------------
    lmsbioinformatics/nf_qc
-------------------------------------------------------------------------------
*/

import static groovy.json.JsonOutput.*

include {module_info; find_samples; count_reads} from './modules/utils'
include {fastqc} from './modules/fastqc'
include {sourmash_gather} from './modules/sourmash'
include {multiqc} from './modules/multiqc'

// Compile and present help text if requested
if (params.containsKey('help')) {
    params._submodules
        .each { module_info(it, show_all=true) }
    exit 0
}

// Ensure required arguments are present
params._required_arguments
    .each{
        if (! params.containsKey(it)) {
            exit 1, "Required parameter missing: ${it}!"
        }
    }

// println prettyPrint(toJson(params))

workflow {

    // Scrape the sample names and file paths, determine the sequencing depth
    samples = find_samples(params.run_dir)
    samples =
        samples.join(count_reads(samples).map { [it[0], it[1].toInteger()] })

    fastqc(samples)
    sourmash_gather(samples)

    // Collect all outputs for multiqc
    qc_and_logs =
        channel.of()
        .mix(fastqc.out, sourmash_gather.out)
        .collect()
    multiqc(qc_and_logs)

}