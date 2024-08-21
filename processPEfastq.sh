#!/bin/sh

# Source conda
eval "$(/risapps/rhel8/miniconda3/py39_4.12.0/bin/conda shell.bash hook)"

# Command-line arguments
THREADS="${1}"
DIR_PROJECT="${2}"
TXINDEX_star="${3}"
REFFLAT="${4}"
RIBO="${5}"
GENOMEFASTA="${6}"
TXINDEX_salmon="${7}"
LIBID="${8}"
READ1="${9}"
READ2="${10}"

echo "Running processPEfastq.sh with arguments:"
printf "THREADS=${1}\nDIR_PROJECT=${2}\nTXINDEX_star=${3}\nREFFLAT=${4}\nRIBO=${5}\nGENOMEFASTA=${6}\nTXINDEX_salmon=${7}\nLIBID=${8}\nREAD1=${9}\nREAD2=${10}\n\n"

# Check if all arguments supplied
if [ ! $# -eq 10 ]
  then
    echo "processPEfastq.sh required arguments:"
    echo "THREADS DIR_PROJECT TXINDEX_star REFFLAT RIBO GENOMEFASTA TXINDEX_salmon LIBID READ1 READ2"
    echo "not all arguments were provided. aborting."
fi

# Check if all files and indexes exist
if [[ ! -f ${READ1} ]] ; then
    echo 'Read 1 file does not exist. Aborting.'
    exit
fi

if [[ ! -f ${READ2} ]] ; then
    echo 'Read 2 file does not exist. Aborting.'
    exit
fi

if [[ ! -f ${TXINDEX_star}/Genome ]] ; then
    echo 'Transcriptome index for STAR does not exist. Aborting.'
    exit
fi

if [[ ! -f ${REFFLAT} ]] ; then
    echo 'refFlat file for picard does not exist. Aborting.'
    exit
fi

if [[ ! -f ${RIBO} ]] ; then
    echo 'Ribosomal intervals file for picard does not exist. Aborting.'
    exit
fi

if [[ ! -f ${GENOMEFASTA} ]] ; then
    echo 'Genome FASTA does not exist. Aborting.'
    exit
fi

if [[ ! -f ${TXINDEX_salmon}/ctable.bin ]] ; then
    echo 'Transcriptome index for Salmon does not exist. Aborting.'
    exit
fi


# Create directories if they do not exist
DIR_TRIM="${DIR_PROJECT}/TRIM"
mkdir -p ${DIR_TRIM}

DIR_ALIGN="${DIR_PROJECT}/ALIGN"
mkdir -p ${DIR_ALIGN}

DIR_METRICS="${DIR_PROJECT}/METRICS"
mkdir -p ${DIR_METRICS}

DIR_REPORTS="${DIR_PROJECT}/REPORTS"
mkdir -p ${DIR_REPORTS}

DIR_TEMP="${DIR_PROJECT}/TEMP"
mkdir -p ${DIR_TEMP}
mkdir -p ${DIR_TEMP}/${LIBID}_temp

DIR_COUNTS="${DIR_PROJECT}/COUNTS"
mkdir -p ${DIR_COUNTS}


# Catalog QC metrics with fastQC
conda activate fastqc-0.11.9

fastqc \
  -o ${DIR_REPORTS} -t ${THREADS} -d ${DIR_TEMP}/${LIBID}_temp \
  ${READ1} ${READ2}

conda deactivate


# Trim reads with fastp
conda activate fastp-0.23.2

fastp \
  -i ${DIR_RAW}/${READ1} -o ${DIR_TRIM}/${LIBID}_1.fastq.gz \
  -I ${DIR_RAW}/${READ2} -O ${DIR_TRIM}/${LIBID}_2.fastq.gz \
  -j ${DIR_REPORTS}/${LIBID}.fastp.json \
  -w ${THREADS} 
  
conda deactivate


# Align reads to transcriptome with star
conda activate star-2.7.10b
rm -r ${DIR_TEMP}/${LIBID}_temp # delete temp directory (STAR will remake)

STAR --genomeDir ${TXINDEX_star} \
     --readFilesIn ${DIR_TRIM}/${LIBID}_1.fastq.gz ${DIR_TRIM}/${LIBID}_2.fastq.gz \
     --readFilesCommand zcat --runThreadN ${THREADS} \
     --genomeLoad NoSharedMemory --outFilterMultimapNmax 20 \
     --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 \
     --outFilterMismatchNmax 999 --outFilterMismatchNoverReadLmax 0.04 \
     --alignIntronMin 20 --alignIntronMax 1000000 \
     --alignMatesGapMax 1000000 --outSAMheaderHD @HD VN:1.4 SO:coordinate \
     --outSAMunmapped Within --outFilterType BySJout \
     --outSAMattributes NH HI AS NM MD --outSAMtype BAM SortedByCoordinate \
     --sjdbScore 1 --outTmpDir ${DIR_TEMP}/${LIBID}_temp \
     --outFileNamePrefix ${DIR_ALIGN}/${LIBID}
    
conda deactivate


# Catalog alignment stats with picard
conda activate picard-2.27.4

picard CollectAlignmentSummaryMetrics \
 -I ${DIR_ALIGN}/${LIBID}Aligned.sortedByCoord.out.bam \
 -O ${DIR_METRICS}/${LIBID}_genomeMetrics.txt
 
picard CollectRnaSeqMetrics \
 -I ${DIR_ALIGN}/${LIBID}Aligned.sortedByCoord.out.bam \
 -O ${DIR_METRICS}/${LIBID}_txomeMetrics.txt \
 --REF_FLAT ${REFFLAT} --STRAND_SPECIFICITY FIRST_READ_TRANSCRIPTION_STRAND \
 --RIBOSOMAL_INTERVALS ${RIBO}
 
picard CollectGcBiasMetrics \
 -I ${DIR_ALIGN}/${LIBID}Aligned.sortedByCoord.out.bam \
 -O ${DIR_METRICS}/${LIBID}_gcBiasMetrics.txt \
 -S ${DIR_METRICS}/${LIBID}_gcSummaryMetrics.txt \
 -CHART ${DIR_METRICS}/${LIBID}_gcBias.pdf \
 -R ${GENOMEFASTA}

conda deactivate


# Count reads to transcripts with salmon
conda activate salmon-1.10.2 

salmon quant \
  -i ${TXINDEX_salmon} --libType A \
  --validateMappings --seqBias --gcBias \
  -p ${THREADS} --numBootstraps 100 --dumpEq \
  -1 ${DIR_TRIM}/${LIBID}_1.fastq.gz -2 ${DIR_TRIM}/${LIBID}_2.fastq.gz \
  -o ${DIR_COUNTS}/${LIBID}
  
conda deactivate
rm -r ${DIR_TEMP}/${LIBID}_temp # Remove temp directories
