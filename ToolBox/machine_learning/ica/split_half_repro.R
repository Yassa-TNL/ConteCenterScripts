---
title: "R Notebook"
output:
  word_document: default
  html_notebook: default
  pdf_document: default
  html_document: default
---


```{r split pre-QAed sample into halves based on overall psych}





#Load library.
require('caret')
#Load data. #Pull out only variables of interest for splitting and checking demographics.
subjData <- readRDS("/data/jux/BBL/projects/jirsaraieStructuralIrrit/data/NMF_Loadings/n288_Demo+ARI+QA_20180305.rds")
subjData <- subjData[ which(subjData$T1exclude=='1'),] 
dataToSplit <- subjData[,c('bblid','scanid','ageatscan','sex','rating','T1exclude','Zari_total')]
dataNoNA <- subset(dataToSplit,is.na(dataToSplit$TP2_ZariTotal)==FALSE)
#Count number of subjects before and after removing NAs.
nrow(dataToSplit)
nrow(dataNoNA)
#Set a random number as the seed.
set.seed(1234)
##Split into the train and test data sets using caret.
#p=the percentage of data that goes to training (e.g., 50%)
#list=FALSE (gives a matrix with rows instead of list) 
#times=the number of partitions to create (number of training sets)
trainIndex <- createDataPartition(dataNoNA$TP2_ZariTotal, p=0.5, list=F, times=1)
#Pull the variables into the new train and test matrices.
dataTrain <- dataNoNA[trainIndex,]
dataTest <- dataNoNA[-trainIndex,]
#Count number of subjects in the train and test sets.
nrow(dataTrain)
nrow(dataTest)
#Save the train and test samples with the demographic variables.
write.csv(dataTrain,'/data/jux/BBL/projects/jirsaraieStructuralIrrit/data/NMF_Loadings/n141_T1_train.csv',row.names=FALSE, quote=FALSE)
write.csv(dataTest,'/data/jux/BBL/projects/jirsaraieStructuralIrrit/data/NMF_Loadings/n140_T1_test.csv',row.names=FALSE, quote=FALSE)
#Save the bblids and scanids only for NMF.
IDs <- c("bblid", "scanid")
bblidsScanids_train <- dataTrain[IDs]
bblidsScanids_test <- dataTest[IDs]
#Remove header.
names(bblidsScanids_train) <- NULL
names(bblidsScanids_test) <- NULL
#Save lists.
write.csv(bblidsScanids_train, file="/data/jux/BBL/projects/jirsaraieStructuralIrrit/data/NMF_Loadings/n141_T1_train_bblids_scanids.csv", row.names=FALSE)
write.csv(bblidsScanids_test, file="/data/jux/BBL/projects/jirsaraieStructuralIrrit/data/NMF_Loadings/n140_T1_test_bblids_scanids.csv", row.names=FALSE)





CovaDataset <- "/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/Audit_Master_ConteMRI.csv"
InterestVar <- c('sub','ses','AgeAtScan','Gender')
ExcludeVar <- c('Inclusion_Cross')
#!/usr/bin/env Rscript
#$ -q yassalab,free*
#$ -pe openmp 16-64
#$ -R y
#$ -ckpt restart
################

args <- commandArgs(trailingOnly=TRUE)
CovaDataset = args[1]
InterestVar = args[2]
ExcludeVar = args[3]

require('caret')

#################################################################################
##### Read in Processed/Denoised fMRI Scans from XCPEngine Output Directory #####
#################################################################################

CONTENT<-read.csv(CovaDataset)

if (){

	which(names(CONTENT) == ExcludeVar)

}


subjData <- readRDS("/data/jux/BBL/projects/jirsaraieStructuralIrrit/data/NMF_Loadings/n288_Demo+ARI+QA_20180305.rds")
subjData <- subjData[ which(subjData$T1exclude=='1'),] 
dataToSplit <- subjData[,c('bblid','scanid','ageatscan','sex','rating','T1exclude','Zari_total')]
dataNoNA <- subset(dataToSplit,is.na(dataToSplit$TP2_ZariTotal)==FALSE)



###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
