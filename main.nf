#!/usr/bin/env nextflow

/*
-------------------------------------------------------------------------------
    lmsbioinformatics/nf_qc
-------------------------------------------------------------------------------
*/

include {module_info; find_samples; get_run_info} from './modules/utils'
include {fastqc; count_undetermined} from './modules/fastqc'
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

    // Determine the undetermined sequencing depth
    count_undetermined(run_dir).n_undetermined
        .map { run_info["Undetermined reads/pairs"] = it.toInteger() }

    // QC and count reads
    fastqc(samples)
    run_info["Demultiplexed reads/pairs"] = 0
    samples =
        samples.join(
            fastqc.out.n_reads
                .map { name, depth ->
                    depth = depth.toInteger()
                    run_info["Demultiplexed reads/pairs"] += depth
                    [name, depth]
                })

    // Contamination screen
    sourmash_gather(samples)

    // Collect all outputs for multiqc
    qc_and_logs =
        channel.of()
        .mix(fastqc.out.files, sourmash_gather.out.files)
        .collect()
    multiqc(qc_and_logs, run_info)

}