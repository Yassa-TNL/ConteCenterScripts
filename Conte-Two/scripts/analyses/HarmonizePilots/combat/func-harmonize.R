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
source("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/scripts/analyses/HarmonizePilots/combat/harmonization_pipeline.R")
source("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/scripts/analyses/HarmonizePilots/combat/harmonization_functions.R")
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

UCIxREST<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/apps/xcpengine/fc-36p/sub-Pilot2T/ses-UCI/task-REST/fcon/schaefer100x7/sub-Pilot2T_ses-UCI_task-REST_schaefer100x7_network.txt"
tc <- as.matrix(unname(read.table(UCIxREST,header=F)))
tc[is.na(tc)]   <- NaN
UCIxREST<-c(tc)

UCSDxREST<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/apps/xcpengine/fc-36p/sub-Pilot2T/ses-UCSD/task-REST/fcon/schaefer100x7/sub-Pilot2T_ses-UCSD_task-REST_schaefer100x7_network.txt"
tc <- as.matrix(unname(read.table(UCSDxREST,header=F)))
tc[is.na(tc)]   <- NaN
UCSDxREST<-c(tc)

UCIxDOORS<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/apps/xcpengine/fc-36p/sub-Pilot2T/ses-UCI/task-doors/sub-Pilot2T_ses-UCI_task-doors_schaefer100x7_ts.1D"
tc <- as.matrix(unname(read.table(UCIxDOORS,header=F)))
adjmat                  <- suppressWarnings(cor(tc))
adjmat[is.na(adjmat)]   <- NaN
TEMPLATE<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/apps/xcpengine/fc-36p/sub-Pilot2T/ses-UCI/task-doors/run-01/fcon/schaefer100x7/sub-Pilot2T_ses-UCI_task-doors_run-01_schaefer100x7.net"
tc <- as.(read.table(file = TEMPLATE, sep = '\t', header = TRUE))

tc<-tc[-c(1),]
for 
UCIxDOORS<-c(adjmat)

UCSD<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/apps/xcpengine/fc-36p/sub-Pilot2T/ses-UCSD/task-REST/fcon/schaefer100x7/sub-Pilot2T_ses-UCSD_task-REST_schaefer100x7_network.txt"
tc <- as.matrix(unname(read.table(UCSD,header=F)))
tc[is.na(tc)]   <- NaN
UCSDxREST<-c(tc)



data<-t(rbind(UCI,UCSD))
data<-data[complete.cases(data),]
data<-data[which(rowSums(data) != 2),]
data<-t(data)

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

write.csv(as.data.frame(data), OutFileRaw)
write.csv(as.data.frame(data.harmonized), OutFileComBat)
Sys.chmod(list.files(dirname(DataOutDir), full.names=TRUE, recursive=TRUE), "775", use_umask = FALSE)

print("Script Run Successfully")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
