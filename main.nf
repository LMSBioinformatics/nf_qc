#!/usr/bin/env nextflow

/*
-------------------------------------------------------------------------------
    lmsbioinformatics/nf_qc
-------------------------------------------------------------------------------
*/

import static groovy.json.JsonOutput.*

// Compile and present help text if requested
if (params.containsKey('help')) {
    include {module_info} from './modules/utils'
    params._submodules
        .each { module_info(it, show_all=true) }
    exit 0
}

// Ensure required arguments are present
params.required_arguments
    .each{
        if (! params.containsKey(it)) {
            exit 1, "Required parameter missing: ${it}!"
        }
    }

// println prettyPrint(toJson(params))

// Scrape the sample names and file paths
// include {find_samples} from './modules/utils'
// samples = find_samples(params.run_dir)

workflow {

    // Determine the sequencing depth for each sample
    include {find_samples; count_reads} from './modules/utils'
    samples =
        find_samples(params.run_dir)
            .join(count_reads(samples))

    samples.view()

}