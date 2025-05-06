# nf_qc

**MRC LMS Nextflow Illumina QC pipeline**

`nf_qc` automates running
[`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
and
[`sourmash`](https://sourmash.readthedocs.io/en/latest/)
(in place of FastQ Screen), pulling together the results in a
[`MultiQC`](https://seqera.io/multiqc/)
report. Where they're available, the pipeline also automatically scrapes the XML
files produced by the Illumina machine to fill in run information and will parse
the `Undetermined_*.fastq.gz` files to report the frequency of barcode combinations
not included in the sample sheet.

## Running

`nextflow` will automatically pull the pipeline if the it's referenced using its
full GitHub name (`lmsbioinformatics/nf_qc`), though it's good practice to also
specify the revision of the pipeline in any case (`-r`). The pipeline then just
requires a `--rundir` and an `--outdir` to be specified .

### Interactive

```bash
module load nextflow
nextflow run lmsbioinformatics/nf_qc -r v0.1.9 --run_dir ~/mnt/network/isilon_miseq/Runs/240719_M01823_0626_000000000-DMHVJ --outdir 240719_M01823_0626_000000000-DMHVJ
```

### As a SLURM Job

The above command can be passed to `sbatch` using `--wrap`:

```bash
sbatch --job-name nf_qc --partition ctrl --qos qos_ctrl --ntasks 1 --cpus-per-task 1 --mem 512M --time 06:00:00 --parsable --wrap 'module load nextflow; nextflow run lmsbioinformatics/nf_qc -r v0.1.9 --run_dir ~/mnt/network/isilon_nextseq/Runs/240730_VH00504_220_2223JLLNX --outdir 240730_VH00504_220_2223JLLNX'
```

### Tidy Up

A pipeline run will create a `work` directory and one or more `.nextflow.log` files
that should be deleted after the pipeline has completed:

```bash
rm -r work .nextflow.log*
```

### Purging Old Pipeline Versions

For a clean slate, cached versions of the pipeline can be deleted if necessary:

```bash
module load nextflow
nextflow drop lmsbioinformatics/nf_qc
```