#!/usr/bin/env nextflow

/*
-------------------------------------------------------------------------------
    lmsbioinformatics/nf_qc
-------------------------------------------------------------------------------
*/

include {module_info; find_samples; get_run_info; count_reads;
        count_undetermined} \
    from './modules/utils'
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

// import static groovy.json.JsonOutput.*
// println prettyPrint(toJson(params))

workflow {

    (run_info, run_dir) = get_run_info(params.run_dir)
    // Scrape the sample names and file paths,
    samples = find_samples(run_dir, params.glob)

    // Determine the on-target sequencing depth
    run_info["Demultiplexed reads"] = 0
    samples =
        samples.join(count_reads(samples).map { name, depth ->
            depth = depth.toInteger()
            run_info["Demultiplexed reads"] += depth
            [name, depth]
        })
    // Determine the undetermined sequencing depth
    run_info["Undetermined reads"] = 0
    count_undetermined(run_dir)
        .map { run_info["Undetermined reads"] += it.toInteger() }

    fastqc(samples)
    sourmash_gather(samples)

    // Collect all outputs for multiqc
    qc_and_logs =
        channel.of()
        .mix(fastqc.out, sourmash_gather.out)
        .collect()
    multiqc(qc_and_logs, run_info)

}