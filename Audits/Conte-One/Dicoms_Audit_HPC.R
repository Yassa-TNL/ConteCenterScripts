#!/usr/bin/env Rscript
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

############################################################################
### Create New Variable to see the Expected CONTE Center Dataset Numbers ###
############################################################################

data<-read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/ConteMRI_All_Timepoints_Keator_2019.csv")
data$MRI_Sums_Expected<-rowSums(data[, c("MRI0", "MRI1", "MRI2", "MRI3")], na.rm = TRUE)
data$X<-NULL

dim(data)[1] #216 Individual Participants Expected
sum(data$MRI_Sums_Expected) #423 Total Scans Expected

##################################################################
### Create New Variable to see Actual CONTE Center Data on HPC ###
##################################################################

NumSubs<-dim(data)[1]
NewCol<-dim(data)[2]+1
data$MRI_Sums_Existing_HPC<-NA

for (x in 1:NumSubs){

  sub<-data[x,1]
  print(sub)

  subpath<-print(paste0("/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/sub-",sub,""))
  Directory<-list.files(path=subpath, recursive=FALSE, full.names=TRUE)
  SumofSessions<-length(Directory)

  print(paste0(sub," has a total of ",SumofSessions," Scans"))
  data[x,NewCol]<-SumofSessions
  
}

length(which(data$MRI_Sums_Existing_HPC > 0) #176 Individual Participants Expected
sum(data$MRI_Sums_Existing_HPC) #302 Total Scans Expected

############################################
### See which Subjects are Missing Scans ###
############################################

data$MRI_Scans_Missing_HPC <-data$MRI_Sums_Existing_HPC - data$MRI_Sums_Expected
sum(data$MRI_Scans_Missing_HPC) # Missing 121 Scans
length(which(data$MRI_Scans_Missing_HPC < 0)) # From 114 Individuals

##################################################################
### Check to see if Subjects are on HPC that were not Expected ###
##################################################################

dcmpath<-print(paste0("/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/dicoms"))
SUBSonHPC<-list.files(path=dcmpath, recursive=FALSE, full.names=FALSE)
SUBSonHPC<-sub('sub-', '', SUBSonHPC)

UNEXPECTEDSUBS<-which(!SUBSonHPC %in% data$nsubid)
length(UNEXPECTEDSUBS) #1 Subject Found
FoundSubject<-SUBSonHPC[UNEXPECTEDSUBS]

### Add this Additonal Subject to the CSV File ###

subpath<-print(paste0("/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/sub-",FoundSubject,""))
Directory<-list.files(path=subpath, recursive=FALSE, full.names=TRUE)
SumofSessions<-length(Directory)
Newrow<-c(FoundSubject,NA,NA,NA,NA,NA,NA,NA,NA,0,SumofSessions)
data<-rbind(data,Newrow)

### Save Spreadsheet ###

write.csv(data, "/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/ConteMRI_All_Timepoints_Keator_2019.csv")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
