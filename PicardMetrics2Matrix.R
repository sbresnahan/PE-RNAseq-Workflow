#!/usr/bin/env Rscript
## PicardMetrics2Matrix.R combines output of Picard tools: 
### CollectAlignmentSummaryMetrics, CollectRnaSeqMetrics, and CollectGcBiasMetrics summaries,
### and creates tables for each with columns as metrics and rows as samples listed in sample_IDs
### which are supplied as a single-column text file (the same as provided to processPEfastq.sh)

args = commandArgs(trailingOnly=TRUE)


# Check if all arguments supplied
if (!length(args)==4) {
  stop("PicardMetrics2Matrix requires arguments: DIR_METRICS, sample_IDs, DIR_OUT, OUT_FILE_PREFIX.n", call.=FALSE)
}

DIR_METRICS <- args[1]
sample_IDs <- read.table(args[2])[,1]
DIR_OUT <- args[3]
OUT_FILE_PREFIX <- args[4]

print("Running PicardMetrics2Matrix.R with arguments:")
print(paste0("DIR_METRICS=",DIR_METRICS))
print(paste0("sample_IDs=",args[2]))
print(paste0("DIR_OUT=",DIR_OUT))
print(paste0("OUT_FILE_PREFIX=",OUT_FILE_PREFIX))


# Genome metrics
GMets.list <- list()
for(sample in 1:length(sample_IDs)){
  GMets <- read.table(paste0(DIR_METRICS,"/",sample_IDs[sample],"_genomeMetrics.txt"),
                      skip=6,nrow=3,fill=NA,header=T)[3,]
  GMets <- GMets[,!names(GMets)%in%c("CATEGORY","SAMPLE","LIBRARY","READ_GROUP")]
  GMets$sample_ID <- sample_IDs[sample]
  GMets <- GMets[,c("sample_ID",names(GMets)[1:(length(names(GMets))-1)])]
  GMets.list[[sample]] <- GMets
}
GMets <- do.call("rbind", GMets.list)
write.table(GMets,paste0(DIR_OUT,"/",OUT_FILE_PREFIX,"_genomeMetrics.txt"),
            row.names=F,sep="\t",quote=F)
print(paste0("Combined Picard CollectAlignmentSummaryMetrics for ",length(sample_IDs)," samples"))


# Transcriptome metrics
TMets.list <- list()
for(sample in 1:length(sample_IDs)){
  TMets <- read.table(paste0(DIR_METRICS,"/",sample_IDs[sample],"_txomeMetrics.txt"),
                      skip=6,nrow=1,fill=NA,header=T)
  TMets <- TMets[,!names(TMets)%in%c("CATEGORY","SAMPLE","LIBRARY","READ_GROUP")]
  TMets$sample_ID <- sample_IDs[sample]
  TMets <- TMets[,c("sample_ID",names(TMets)[1:(length(names(TMets))-1)])]
  TMets.list[[sample]] <- TMets
}
TMets <- do.call("rbind", TMets.list)
write.table(TMets,paste0(DIR_OUT,"/",OUT_FILE_PREFIX,"_txomeMetrics.txt"),
            row.names=F,sep="\t",quote=F)
print(paste0("Combined Picard CollectRnaSeqMetrics for ",length(sample_IDs)," samples"))


# GC metrics
GCMets.list <- list()
for(sample in 1:length(sample_IDs)){
  GCMets <- read.table(paste0(DIR_METRICS,"/",sample_IDs[sample],"_gcSummaryMetrics.txt"),
                       skip=6,nrow=1,fill=NA,header=T)
  GCMets <- GCMets[,!names(GCMets)%in%c("CATEGORY","SAMPLE","LIBRARY","READ_GROUP")]
  GCMets$sample_ID <- sample_IDs[sample]
  GCMets <- GCMets[,c("sample_ID",names(GCMets)[1:(length(names(GCMets))-1)])]
  GCMets.list[[sample]] <- GCMets
}
GCMets <- do.call("rbind", GCMets.list)
write.table(GCMets,paste0(DIR_OUT,"/",OUT_FILE_PREFIX,"_gcSummaryMetrics.txt"),
            row.names=F,sep="\t",quote=F)
print(paste0("Combined Picard CollectGcBiasMetrics summaries for ",length(sample_IDs)," samples"))

print("Done.")
