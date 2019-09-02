#!/usr/bin/env Rscript
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

print("Reading Arguments")

covaPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/Demo/n275_Age+Sex_20190829.csv"
inputPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/T1w/n360_Aseg_volume_20190829.csv"
OutDirRoot <- "/dfs2/yassalab/rjirsara/NSF/Results"
covsFormula <- "~s(AgeAtScan,k=4)+Gender"
randomFormula <- "~(1|sub)"
subjID <- "sub,ses"

#####################################
### Load Files and Merge Together ###
#####################################

print("Loading Covariates Dataset")
covaData<-read.csv(covaPath)
covaData<-covaData[complete.cases(covaData$AgeAtScan),]
covaData$Gender<-as.factor(covaData$Gender)

print("Loading Input Dataset")
subjID <- unlist(strsplit(subjID, ","))
inputData <- read.csv(inputPath)
if (any(colnames(inputData) == "X")) {
inputData$X<-NULL
}

print("Merging Datasets")
dataSubj <- merge(covaData, inputData, by=subjID)

#####################
### Load Packages ###
#####################

print("Loading Libraries")

suppressMessages(require(ggplot2))
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

#################################################
### Define Cores & Multiple Correction Method ###
#################################################

ncores <- 5
pAdjustMethod <- "fdr"
methods <- c("holm", "hochberg", "hommel", "bonferroni", "BH", "BY","fdr", "none")
if (!any(pAdjustMethod == methods)) {
  print("p.adjust.method is not a valid one, reverting back to 'none'")
  pAdjustMethod <- "none"
}

#########################################
### Defining and Executing GAM Models ###
#########################################

print("Analyzing Dataset")

model.formula <- mclapply((dim(covaData)[2] + 1):dim(dataSubj)[2], function(x) { 
  as.formula(paste(paste0("dataSubj[,",x,"]"), covsFormula, sep="")) 
}, mc.cores=ncores)

print("Executing Models")

m <- mclapply(model.formula, function(x) {
  ANALYZE <- gamm4(formula = x, random=as.formula(randomFormula), data=dataSubj, REML=T)$gam
  summary <- summary(ANALYZE)
  residuals <- ANALYZE$residuals
  missing <- as.numeric(ANALYZE$na.action)
  return(list(summary,residuals, missing))
}, mc.cores=1)

#Error in terms.formula(gf, specials = c("s", "te", "ti", "t2", extra.special)) :
#  argument is not a valid model

#################################
### Creating Output Directory ###
#################################

print("Creating Analysis Directory")

subjDataOut <- strsplit(covaPath, ".csv")[[1]][[1]]
subjDataOut <- strsplit(subjDataOut, "/")[[1]][[length(subjDataOut <- strsplit(subjDataOut, "/")[[1]])]]

inputPathOut <- strsplit(inputPath, ".csv")[[1]][[1]]
inputPathOut <- strsplit(inputPathOut, "/")[[1]][[length(inputPathOut <- strsplit(inputPathOut, "/")[[1]])]]

OutDir <- paste0(OutDirRoot, "/n",dim(dataSubj)[1],"-COVA-",subjDataOut,"-RESP-",inputPathOut)
dir.create(OutDir)
setwd(OutDir)

print("Creating Output File Name")

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

random <- gsub("~", "", randomFormula)
random <- gsub("\\(", "", random)
random <- gsub("\\)", "", random)
random <- gsub("\\|", "", random)

outsubDir <- paste0("gamm4_",outName,"_random_",random)
outsubDir<-paste(OutDir,outsubDir,sep="/")

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