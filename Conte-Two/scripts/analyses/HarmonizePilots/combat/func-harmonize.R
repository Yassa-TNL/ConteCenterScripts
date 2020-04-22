###################################################################################################
##########################               HarmonizeCOMBAT                 ##########################
##########################               Robert Jirsaraie                ##########################
##########################               rjirsara@uci.edu                ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
# Use #

# Conte-Two is multi-site study with different brands of scanners (UCI Seimens/UCSD GE), which can confound
# Group Differences Across Sites. This script applies the COMBAT Algorithm to harmonize data between sites.

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

#DWI

OutDirRoot <- "/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/datasets"
source("/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/data_analysis/combat/harmonization_pipeline.R")
source("/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/data_analysis/combat/harmonization_functions.R")
require(mgcv)

##############################################################
##### Remove Empty or Missing Data Columns For Anat Data #####
##############################################################

print("Cleaning Raw Data")'

InFile <- "/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/datasets/T1w/n4_APARC+ASEG_Volume-RAW_20191209.csv"

data<-read.csv(InFile)
CleanData <- function(data){
	data[3:ncol(data)] <- lapply(data[3:ncol(data)], as.numeric)
	DATA<-rbind(data,NA)
	NewRowNum<-dim(DATA)[1]
	for (col in 3:dim(DATA)[2]){
		DATA[NewRowNum,col]<-sd(DATA[-c(NewRowNum),col])
	}
	CleanColNumbers<-suppressWarnings(which(DATA[c(NewRowNum),]>1))
	DATA<-DATA[-c(NewRowNum),c(1,2,CleanColNumbers)]
 	return(DATA)
}


data<-CleanData(data)

print("Restructuing Raw Data")

data<-as.data.frame(t(data))
for (num in 1:dim(data)[2]){
	NAME <- paste0(data[c(1),num],"x",data[c(2),num])
	names(data)[num] <- NAME
}

data[,1:dim(data)[2]] <- lapply(data[,1:dim(data)[2]], as.numeric)
data <- as.matrix(data[-c(1,2),-c(4)])

##############################################################
##### Remove Empty or Missing Data Columns For FUNC Data #####
##############################################################

FILES<-list.files("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/apps/xcpengine/fc-36p_despike/sub-Pilot2T", recursive=T, full.names=T, pattern="schaefer100x7_network.txt")
FILES<-FILES[!grepl("run-", FILES)]

DATA<-as.data.frame("")
for (file in FILES){
	temp <- as.matrix(unname(read.table(file,header=F)))
	temp[is.na(temp)]   <- NaN
	DATA<-cbind(DATA,temp)
}
DATA<-DATA[,-c(1)]
names(DATA)<-c("UCIxDOORS","UCIxREST","UCSDxDOORS","UCSDxREST")
data<-as.matrix(DATA)

########################################################
##### Define which columns are from what Timepoint #####
########################################################

print("Defining Batches")

batch = c(1:ncol(DATA))
batch[grep("UCI",colnames(DATA))]<-1
batch[grep("UCSD",colnames(DATA))] <-2

########################################
##### Execute ComBat Harominzation #####
########################################

print("Harmonizing Batches")

data.harmonized <- combat(dat=data, batch=batch, mod=NULL, eb=FALSE)$dat.combat

##########################################################################
##### Save Unharmonized and Harmonized Data For Subsequent Analyses  #####
##########################################################################

print("Saving Output Files")

Sequence<-strsplit(InFile, "/")[[1]][8]
DataOutDir<-paste(OutDirRoot,"Data",Sequence, sep="/")
suppressMessages(dir.create(DataOutDir, recursive = TRUE))

SubNum<-ncol(data)
Date<-format(Sys.time(), "%Y%m%d")
CoreFileName<-strsplit(basename(InFile), "_")[[1]]
OutFileRaw<-paste0(DataOutDir,'/n',SubNum,"_",CoreFileName[2],"_",CoreFileName[3],"-RAW_",Date,".csv")
OutFileComBat<-gsub("RAW", "ComBat", OutFileRaw)

write.csv(as.data.frame(data), "/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/datasets/REST/raw.csv")
write.csv(as.data.frame(data.harmonized), "/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/datasets/REST/combat.csv")
Sys.chmod(list.files(dirname(DataOutDir), full.names=TRUE, recursive=TRUE), "775", use_umask = FALSE)

print("Script Run Successfully")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
