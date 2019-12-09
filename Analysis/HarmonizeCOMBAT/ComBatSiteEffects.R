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

InFile <- "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-Two/T1w/n5_APARC+ASEG_Volume_20191203.csv"
OutDirRoot <- "/dfs2/yassalab/rjirsara/HarmonizeCOMBAT"

source("/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/Analysis/HarmonizeCOMBAT/combat_harmonization_functions.R")
source("/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/Analysis/HarmonizeCOMBAT/combat_harmonization_pipeline.R")

################################################
##### Remove Empty or Missing Data Columns #####
################################################

print("Cleaning Raw Data")

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

##############################################
##### Restructure Data For Harmonziation #####
##############################################

print("Restructuing Raw Data")

data<-as.data.frame(t(data))
for (num in 1:dim(data)[2]){
	NAME <- paste0(data[c(1),num],"x",data[c(2),num])
	names(data)[num] <- NAME
}

data[,1:dim(data)[2]] <- lapply(data[,1:dim(data)[2]], as.numeric)
data <- as.matrix(data[-c(1,2),-c(4)])

########################################################
##### Define which columns are from what Timepoint #####
########################################################

print("Defining Batches")

batch = c(1:ncol(data))
batch[grep("UCI",colnames(data))]<-1
batch[grep("UCSD",colnames(data))] <-2

########################################
##### Execute ComBat Harominzation #####
########################################

print("Harmonizing Batches")

data.harmonized <- combat(dat=data, batch=batch, mod=NULL, eb=TRUE)$dat.combat

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

write.csv(as.data.frame(data), OutFileRaw)
write.csv(as.data.frame(data.harmonized), OutFileComBat)
Sys.chmod(list.files(dirname(DataOutDir), full.names=TRUE, recursive=TRUE), "775", use_umask = FALSE)

print("Script Run Successfully")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
