# Paired-end RNAseq workflow
Pipeline for QC, trimming, alignment, and transcript-level quantification of paired-end RNAseq data + concatenation of alignment metrics produced by Picard tools.

## Scripts

**submit_loop.sh**:
Batch submit array, calling run_processPEfastq.lsf (below) for each **SAMPLEID** listed in a user-supplied file

**run_processPEfastq.lsf**
Example batch submit script, calling processPEfastq.sh (below)

**processPEfastq.sh**: 
1) *fastQC* to catalog pre-trimmed QC metrics
2) *fastp* to trim and catalog post-trimmed QC metrics
3) *STAR* for alignment to reference genome
4) *picard CollectAlignmentSummaryMetrics*, *CollectRnaSeqMetrics*, and *CollectGcBiasMetrics* to catalog alignment metrics
5) *Salmon* for transcript-level quantification

*Note 1:* sources and uses names of conda environments specific to MD Anderson HPC at `/risapps/rhel8/miniconda3`

*Note 2:* expects paired-end sequence reads following the file name convention: **SAMPLEID**_R1_001.fastq.gz **SAMPLEID**_R2_001.fastq.gz

**PicardMetrics2Matrix.R**:
Combines output of step 4 above for all files within a given directory specified by a list of sample IDs

## Workflow:

1) Modify run_processPEfastq.lsf to update BSUB arguments and paths to your HPC directories
2) Run `sh submit_loop.sh SAMPLEIDs.txt` where `SAMPLEIDS.txt` is a single-column file listing the **SAMPLEID** of paired-end sequence reads
3) Run `Rscript PicardMetrics2Matrix.R` to combine the output of the Picard tools into tables

## Usage:

**submit_loop.sh**:
```shell
usage: sh submit_loop.sh SAMPLEIDs.txt
arguments:
  SAMPLEIDS.txt              Path to a single-column file listing the SAMPLEID of paired-end sequence reads
```

**processPEfastq.sh**:
```shell
usage: sh processPEfastq.sh THREADS DIR_PROJECT TXINDEX_star REFFLAT RIBO GENOMEFASTA TXINDEX_salmon LIBID READ1 READ2
arguments:
  THREADS                    Integer number of threads for running fastQC, fastp, STAR, & salmon
  DIR_PROJECT                Path to project directory to create for saving output of each tool
  TXINDEX_star               Path to STAR index for alignment
  REFFLAT                    Path to annotation refflat file
  RIBO                       Path to ribosomal intervals file
  GENOMEFASTA                Path to reference genome fasta
  TXINDEX_salmon             Path to salmon index for transcript-level quantification
  LIBID                      Library ID for sample (e.g., same as in SAMPLEIDS.txt)
  READ1                      SAMPLEID_R1_001.fastq.gz
  READ2                      SAMPLEID_R2_001.fastq.gz
```

**PicardMetrics2Matrix.R**:
```shell
usage: Rscript PicardMetrics2Matrix.R DIR_METRICS sample_IDs DIR_OUT OUT_FILE_PREFIX
arguments:
  DIR_METRICS                Path to directory containing Picard metrics (e.g., DIR_PROJECT/METRICS from processPEfastq.sh)
  sample_IDs                 Path to a single-column file listing the SAMPLEID of paired-end sequence reads (same as submit_loop.sh)
  DIR_OUT                    Path to directory for saving combined tables
  OUT_FILE_PREFIX            Name of project for output file prefix ("FOO" will generate FOO_txomeMetrics.txt, etc.)
```


