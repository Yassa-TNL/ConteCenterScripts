#!/usr/bin/env Rscript
###################################################################################################
##########################                   NSF-GRFP                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ####
###################################################################################################

print("Reading Arguments")

covaPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/Demo/n275_Age+Sex_20190829.csv"
inputPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/T1w/n360_Aseg_volume_20190829.csv"
OutDirRoot <- "/dfs2/yassalab/rjirsara/NSF"
covsFormula <- "~s(AgeAtScan,k=4)+Gender"
subjID <- "sub,ses"

print("Reading Custom Outputting Options")

SubOutDir="BaselineScans"
SortOutFile="AgeAtScan"
SaveDatasets=TRUE

##############################################
### Load and Prepare Datasets for Analyses ###
##############################################

print("Loading Covariates Dataset")
covaData<-read.csv(covaPath)
if (any(colnames(covaData) == "X")) {
	covaData$X<-NULL
}

print("Getting Baseline Data Only")
covaData<-covaData[complete.cases(covaData$AgeAtScan),]
SUBJECTS<-unique(covaData$sub)
BASELINE=data.frame()
for (x in SUBJECTS){
	row<-which(covaData$sub==x)[1]
	addrow<-covaData[row,]
	BASELINE<-rbind(BASELINE,addrow)
}
covaData<-BASELINE

print("Loading Responce Dataset")
subjID <- unlist(strsplit(subjID, ","))
inputData <- read.csv(inputPath)
if (any(colnames(inputData) == "X")) {
	inputData$X<-NULL
}

print("Remove Empty Columns with No Variance")
emptycols<-which(colSums(inputData)==0)
inputData<-inputData[,-c(emptycols)]

print("Merging Datasets")
dataSubj <- merge(covaData, inputData, by=subjID)

####################
### Load Library ###
####################

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
suppressMessages(require(stringr))

#########################################
### Define Multiple Correction Method ###
#########################################

ncores <- 1
pAdjustMethod <- "fdr"
methods <- c("holm", "hochberg", "hommel", "bonferroni", "BH", "BY","fdr", "none")
if (!any(pAdjustMethod == methods)) {
  print("p.adjust.method is not a valid one, reverting back to 'none'")
  pAdjustMethod <- "none"
}

#########################################
### Defining and Executing GAM Models ###
#########################################

print("Defining Models to be Analyzed")

model.formula <- mclapply((dim(covaData)[2] + 1):dim(dataSubj)[2], function(x) {
  as.formula(paste(paste0(names(dataSubj)[x]), covsFormula, sep=""))
}, mc.cores=ncores)

print("Executing Models")

m <- mclapply(model.formula, function(x) {
  ANALYZE <- gam(formula = x, data=dataSubj, method="REML")
  summary <- summary(ANALYZE)
  residuals <-  ANALYZE$residuals
  missing <- as.numeric(ANALYZE$na.action)
  return(list(summary,residuals, missing))
}, mc.cores=ncores)

#################################
### Creating Output Directory ###
#################################

print("Creating Analysis Directory")

subjDataOut <- strsplit(covaPath, ".csv")[[1]][[1]]
subjDataOut <- strsplit(subjDataOut, "/")[[1]][[length(subjDataOut <- strsplit(subjDataOut, "/")[[1]])]]
inputPathOut <- strsplit(inputPath, ".csv")[[1]][[1]]
inputPathOut <- strsplit(inputPathOut, "/")[[1]][[length(inputPathOut <- strsplit(inputPathOut, "/")[[1]])]]
OutDir <-  paste0(OutDirRoot,"/Results/COVA-",subjDataOut,"_RESP-",inputPathOut)
suppressMessages(dir.create(OutDir, recursive = TRUE))
setwd(OutDir)

if (SubOutDir != 'FALSE') {
	print("Adding Custom Sub-Directory")
	OutDir<-paste0(OutDir,"/",SubOutDir)
	suppressMessages(dir.create(OutDir))
	setwd(OutDir)
}

print("Creating output directory")

outName <- gsub("~", "", covsFormula)
outName <- gsub(" ", "", outName)
outName <- gsub("\\+","-",outName)
outName <- gsub("\\(","",outName)
outName <- gsub("\\)","",outName)
outName <- gsub(",","",outName)
outName <- gsub("\\.","",outName)
outName <- gsub("=","",outName)
outName <- gsub("\\*","and",outName)
outName <- gsub(":","and",outName)
outsubDir <- paste0("n",dim(dataSubj)[1],"_gam_",outName)
outsubDir<-paste(OutDir,outsubDir,sep="/")

############################################
### Save Processed Datasets if Specified ###
############################################

if (SaveDatasets == 'TRUE') {
  print("Saving Processed Datasets")
  DataOutDir<-str_replace_all(OutDir, "/Results/", "/Data/")
  suppressMessages(dir.create(DataOutDir, recursive = TRUE))
  FileName<-paste(basename(outsubDir),"Predictors.csv",sep="_")
  write.csv(covaData,paste(DataOutDir,FileName,sep="/"))
  FileName<-paste(basename(outsubDir),"Responces.csv",sep="_")
  write.csv(inputData,paste(DataOutDir,FileName,sep="/"))
  FileName<-paste(basename(outsubDir),"Merged.csv",sep="_")
  write.csv(dataSubj,paste(DataOutDir,FileName,sep="/"))
  Sys.chmod(list.files(DataOutDir, full.names=TRUE), "775", use_umask = FALSE)
}

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

####################################
### Save Final Output of Results ###
####################################

print("Saving Final Results File")

if (is.null(m[[1]]$s.table)) {
  if (SortOutFile != 'FALSE') {
    COLNAME<-grep(SortOutFile, names(p.output), value = TRUE)[1]
    COLNUM<-which(names(p.output) == COLNAME )
    p.output<-p.output[order(p.output[,COLNUM] ),]
  }
  outsubDir<-str_replace_all(outsubDir, "_gam_", "_lm_")
  write.csv(p.output, paste0(outsubDir,".csv"), row.names=F)
  Sys.chmod(list.files(dirname(outsubDir), full.names=TRUE), "775", use_umask = FALSE)

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
  if (SortOutFile != 'FALSE') {
		COLNAME<-grep(SortOutFile, names(output), value = TRUE)[1]
		COLNUM<-which(names(output) == COLNAME )
		output<-output[order(output[,COLNUM] ),]
  }
  write.csv(output, paste0(outsubDir, ".csv"), row.names=F)
  Sys.chmod(list.files(dirname(outsubDir), full.names=TRUE), "775", use_umask = FALSE)
}

print("Script Ran Succesfully")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
