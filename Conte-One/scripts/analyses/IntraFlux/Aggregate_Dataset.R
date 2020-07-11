#!/usr/bin/env Rscript
######################

print("Reading Arguments")

args <- commandArgs(trailingOnly=TRUE)
#DIR_PROJECT = args[1]
DIR_PROJECT="/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One"

suppressMessages(require(reshape))
suppressMessages(require(gtools))
suppressMessages(require(ggplot2))
TODAY=gsub("-","",Sys.Date())

####################################################################################################
##### Find All Processed Scans And Extract Signal Using Every Available Atlas For Each Subject #####
####################################################################################################

CONTENT<-read.csv(list.files(path=paste0(DIR_PROJECT,"/datasets"), full.names=T, recursive=T, pattern = "aggregate_df.csv"))
CONTENT<-CONTENT[which(CONTENT$IntraFlux_Inclusion == 1),c(1:2,17,18,20:22)]
CONTENT$scl.CDI_MD<-as.numeric(CONTENT$scl.CDI_MD)
CONTENT$Gender<-as.factor(CONTENT$Gender)

QA_SUMMARY<-list.files(path=paste0(DIR_PROJECT,"/datasets"), full.names=T, recursive=T, pattern = "QA-Summary")
QA_SUMMARY<-QA_SUMMARY[grep("prestats",QA_SUMMARY)][c(1,4:5)]
for (FILE in QA_SUMMARY){
	CONTENT_QA<-read.csv(FILE)
	CONTENT_QA<-CONTENT_QA[,c("sub","ses","fdMEAN")]
	LABEL<-unlist(strsplit(FILE,'_'))[grep('task-',unlist(strsplit(FILE,'_')))]
	LABEL<-paste0("FD_MEAN_",gsub(".csv","",gsub("task-","",LABEL)))
	names(CONTENT_QA)[3]<-LABEL
	CONTENT<-merge(CONTENT,CONTENT_QA,by=c("sub","ses"))
}
names(CONTENT)[9]<-"FD_MEAN_REST1"
names(CONTENT)[10]<-"FD_MEAN_REST2"

FEATQUERY<-list.files(path=paste0(DIR_PROJECT,"/apps/xcp-feat/pipe-aromaXcluster_task-AMG_emotion/group"), full.names=T, recursive=T, pattern = "report.txt")
ATLASES<-unique(unlist(strsplit(FEATQUERY,"/"))[grep("atl-",unlist(strsplit(FEATQUERY,"/")))])
for (ATLAS in ATLASES){
	HEADER<-gsub("atl-","",ATLAS)
	CONTENT[,paste0(HEADER,"_tstat")]<-NA
	CONTENT[,paste0(HEADER,"_zstat")]<-NA
}

for (ROW in 1:nrow(CONTENT)){
	SUB<-CONTENT[ROW,1]
	SES<-CONTENT[ROW,2]
	for (ATLAS in ATLASES){
		OUTPUT<-read.table(FEATQUERY[grep(paste0("sub-",SUB,"_ses-",SES,".feat/",ATLAS),FEATQUERY)])
		T_COL<-grep(gsub("atl-","",ATLAS),names(CONTENT))[1]
		Z_COL<-grep(gsub("atl-","",ATLAS),names(CONTENT))[2]
		CONTENT[ROW,T_COL]<-OUTPUT[3,6]
		CONTENT[ROW,Z_COL]<-OUTPUT[6,6]
	}
}

write.csv(CONTENT,paste0(DIR_PROJECT,"/analyses/IntraFlux/Aggregate_Dataset.csv",row.names=FALSE))

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
