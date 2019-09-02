#!/usr/bin/env Rscript
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

print("Reading Arguments")

subjDataName <- "CovariateData.rds"
inputPath <- "NeuroimagingData.csv"
OutDirRoot <- "OutputPath"
covsFormula <- "~s(Age,k=4)+Covariates"
subjID <- "SUBID"

#####################################
### Load Files and Merge Together ###
#####################################

print("Loading Covariates Dataset")
covaData<-readRDS(subjDataName)

print("Loading Input Dataset")
subjID <- unlist(strsplit(subjID, ","))
inputData <- read.csv(inputPath)

print("Merging Datasets")
dataSubj <- merge(covaData, inputData, by=subjID)

####################
### Load Library ###
####################

print("Loading Libraries")

suppressMessages(require(ggplot2))
suppressMessages(require(optparse))
suppressMessages(require(base))
suppressMessages(require(reshape2))
suppressMessages(require(nlme))
suppressMessages(require(lme4))
suppressMessages(require(gamm4))
suppressMessages(require(stats))
suppressMessages(require(knitr))
suppressMessages(require(mgcv))
suppressMessages(require(plyr))
suppressMessages(require(oro.nifti))
suppressMessages(require(parallel))
suppressMessages(require(optparse))
suppressMessages(require(fslr))
suppressMessages(require(voxel))

#########################################
### Define Multiple Correction Method ###
#########################################

ncores <- 5
pAdjustMethod <- "fdr"
methods <- c("holm", "hochberg", "hommel", "bonferroni", "BH", "BY","fdr", "none")
if (!any(pAdjustMethod == methods)) {
  print("p.adjust.method is not a valid one, reverting back to 'none'")
  pAdjustMethod <- "none"
}

#################################
### Creating Output Directory ###
#################################

print("Creating Analysis Directory")

subjDataOut <- strsplit(subjDataName, ".rds")[[1]][[1]]
subjDataOut <- strsplit(subjDataOut, "/")[[1]][[length(subjDataOut <- strsplit(subjDataOut, "/")[[1]])]]

inputPathOut <- strsplit(inputPath, ".csv")[[1]][[1]]
inputPathOut <- strsplit(inputPathOut, "/")[[1]][[length(inputPathOut <- strsplit(inputPathOut, "/")[[1]])]]

OutDir <- paste0(OutDirRoot, "/n",dim(dataSubj)[1],"_rds_",subjDataOut,"_ROI_",inputPathOut)
dir.create(OutDir)
setwd(OutDir)

print("Creating output directory")

outName <- gsub("~", "", covsFormula)
outName <- gsub(" ", "", outName)
outName <- gsub("\\+","_",outName)
outName <- gsub("\\(","",outName)
outName <- gsub("\\)","",outName)
outName <- gsub(",","",outName)
outName <- gsub("\\.","",outName)
outName <- gsub("=","",outName)
outName <- gsub("\\*","and",outName)
outName <- gsub(":","and",outName)

outsubDir <- paste0("gam_",outName)
outsubDir<-paste(OutDir,outsubDir,sep="/")

#########################################
### Defining and Executing GAM Models ###
#########################################

print("Defining Models to be Analyzed")

model.formula <- mclapply((dim(covaData)[2] + 1):dim(dataSubj)[2], function(x) {
  as.formula(paste(paste0(names(dataSubj)[x]), covsFormula, sep=""))
}, mc.cores=ncores)

print("Executing Models")

m <- mclapply(model.formula, function(x) {
  model <- gam(formula = x, data=dataSubj, method="REML")
  summary <- summary(model)
  residuals <- model$residuals
  missing <- as.numeric(model$na.action)
  return(list(summary,residuals, missing))
}, mc.cores=ncores)

##########################################
### Generating Table of Summary Output ###
##########################################

print("Generating parameters")

m <- mclapply(m, function(x) {
  x[[1]]
}, mc.cores=ncores)

length.names.p <- length(rownames(m[[1]]$p.table))

output <- as.data.frame(matrix(NA,
                               nrow = length((dim(covaData)[2] + 1):dim(dataSubj)[2]),
                               ncol= (1+3*length.names.p)))

names(output)[1] <- "names"

for (i in 1:length.names.p) {

  dep.val <- rownames(m[[1]]$p.table)[i]
  names(output)[2 + (i-1)*3 ] <- paste0("tval.",dep.val)
  names(output)[3 + (i-1)*3 ] <- paste0("pval.",dep.val)
  names(output)[4 + (i-1)*3 ] <- paste0("pval.",pAdjustMethod,dep.val)

  val.tp <- t(mcmapply(function(x) {
    x$p.table[which(rownames(x$p.table) == dep.val), 3:4]
  }, m, mc.cores=ncores))

  output[,(2 + (i-1)*3):(3 + (i-1)*3)] <- val.tp
  output[,(4 + (i-1)*3)] <- p.adjust(output[,(3 + (i-1)*3)], pAdjustMethod)

}

output$names <- names(dataSubj)[(dim(covaData)[2] + 1):dim(dataSubj)[2]]
p.output <- output

## If there's a s.table then do the same, merge both datasets and output
## Otherwise just output the p.table dataset (there are no splines in model)

if (is.null(m[[1]]$s.table)) {

  write.csv(p.output, paste0(outsubDir, "_coefficients.csv"), row.names=F)

} else {

  length.names.s <- length(rownames(m[[1]]$s.table))
  output <- as.data.frame(matrix(NA,
                                 nrow = length((dim(covaData)[2] + 1):dim(dataSubj)[2]),
                                 ncol= (1+2*length.names.s)))

  names(output)[1] <- "names"

  for (i in 1:length.names.s) {

    dep.val <- rownames(m[[1]]$s.table)[i]
    names(output)[2 + (i-1)*2 ] <- paste0("pval.",dep.val)
    names(output)[3 + (i-1)*2 ] <- paste0("pval.",pAdjustMethod,dep.val)

    val.tp <- mcmapply(function(x) {
      x$s.table[which(rownames(x$s.table) == dep.val), 4]
    }, m, mc.cores=ncores)

    output[,(2 + (i-1)*2)] <- val.tp
    output[,(3 + (i-1)*2)] <- p.adjust(output[,(2 + (i-1)*2)], pAdjustMethod)

  }

  output$names <- names(dataSubj)[(dim(covaData)[2] + 1):dim(dataSubj)[2]]
  output <- merge(p.output, output, by="names")
  write.csv(output, paste0(outsubDir, "_coefficients.csv"), row.names=F)

}

print("Script Ran Succesfully")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################