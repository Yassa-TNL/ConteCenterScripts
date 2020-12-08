#!/usr/bin/env Rscript
######################

print("Reading Arguments")
DIR_PROJECT="/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One"
suppressMessages(require(mgcv))
suppressMessages(require(visreg))
suppressMessages(require(svglite))
suppressMessages(require(cowplot))
suppressMessages(require(reshape))
suppressMessages(require(ggplot2))
suppressMessages(require(corrplot))
suppressMessages(require(interactions))
suppressMessages(require(RColorBrewer))
suppressMessages(require(gamm4))
suppressMessages(require(nlme))
suppressMessages(require(lme4))
TODAY=gsub("-","",Sys.Date())

#################################################################################################
##### Find T-values and Z-values Extracted From the Contrasts Maps Calculated with FSL FEAT #####
#################################################################################################

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
	HEADER<-gsub("-","_",gsub("atl-","",ATLAS))
	CONTENT[,paste0(HEADER,"_tstat")]<-NA
	CONTENT[,paste0(HEADER,"_zstat")]<-NA
}

for (ROW in 1:nrow(CONTENT)){
	SUB<-CONTENT[ROW,1]
	SES<-CONTENT[ROW,2]
	for (ATLAS in ATLASES){
		OUTPUT<-read.table(FEATQUERY[grep(paste0("sub-",SUB,"_ses-",SES,".feat/",ATLAS,"/"),FEATQUERY)])
		T_COL<-grep(gsub("-","_",gsub("atl-","",ATLAS)),names(CONTENT))[1]
		Z_COL<-grep(gsub("-","_",gsub("atl-","",ATLAS)),names(CONTENT))[2]
		CONTENT[ROW,T_COL]<-OUTPUT[3,6]
		CONTENT[ROW,Z_COL]<-OUTPUT[6,6]
	}
}

write.csv(CONTENT,paste0(DIR_PROJECT,"/analyses/IntraFlux/Aggregate_EVCont_AMG.csv"),row.names=FALSE)

##############################################################################################################
##### Find Mean and Eigenvariate Values From the Dual Regression Stage 2 Maps Cacluated with FSL MELODIC #####
##############################################################################################################

MDD<-read.csv(paste0(DIR_PROJECT,"/analyses/IntraFlux/Aggregate_EVCont_AMG.csv"))
MDD<-MDD[,c("sub","AgeAtScan","Gender","PreMood_Ent","PreMood_Lvl","scl.CDI_MD","FD_MEAN_AMG","FD_MEAN_REST1","FD_MEAN_REST2")]

for (DIM in list.files(path=paste0(DIR_PROJECT,"/analyses/IntraFlux/n138_IntraFlux.dualreg"), pattern="dim-12_sm3")){
	BASE_DIR=paste0(DIR_PROJECT,"/analyses/IntraFlux/n138_IntraFlux.dualreg/",DIM)
	MEAN_FILES=list.files(path=BASE_DIR,full.names=T, recursive=T,pattern="aggregated_mean")
	EIGEN_FILES=list.files(path=BASE_DIR,full.names=T, recursive=T,pattern="aggregated_eigen")
	MEAN_MASTER<-data.frame(matrix(ncol = dim(read.csv(MEAN_FILES[1]))[2], nrow = 0))
	EIGEN_MASTER<-data.frame(matrix(ncol = dim(read.csv(EIGEN_FILES[1]))[2], nrow = 0))
	colnames(MEAN_MASTER)<-names(read.csv(MEAN_FILES[1]))
	colnames(EIGEN_MASTER)<-names(read.csv(EIGEN_FILES[1]))
	for (INDEX in 1:length(MEAN_FILES)){
		print(paste0("WORKING: ",MEAN_FILES[INDEX]))
		MEAN_CONTENT<-read.csv(MEAN_FILES[INDEX])
		MEAN_MASTER<-rbind(MEAN_MASTER,MEAN_CONTENT)
		print(paste0("WORKING: ",EIGEN_FILES[INDEX]))
		EIGEN_CONTENT<-read.csv(EIGEN_FILES[INDEX])
		EIGEN_MASTER<-rbind(EIGEN_MASTER,EIGEN_CONTENT)
	}
	MEAN_MASTER$X<-NULL
	EIGEN_MASTER$X<-NULL
	names(MEAN_MASTER)<-gsub("_","_MEAN_",names(MEAN_MASTER))
	names(EIGEN_MASTER)<-gsub("_","_EIGEN_",names(EIGEN_MASTER))
	MASTER<-merge(MEAN_MASTER,EIGEN_MASTER,by=c("sub"))
	AMG<-MASTER[,c(1,grep("_AMG",names(MASTER)))]
	REST1<-MASTER[,c(1,grep("_REST1",names(MASTER)))]
	REST2<-MASTER[,c(1,grep("_REST2",names(MASTER)))]
	colnames(AMG)[2:ncol(AMG)] <- sub("_AMG", "", colnames(AMG)[2:ncol(AMG)])
	colnames(REST1)[2:ncol(REST1)] <- sub("_REST1", "", colnames(REST1)[2:ncol(REST1)])
	colnames(REST2)[2:ncol(REST2)] <- sub("_REST2", "", colnames(REST2)[2:ncol(REST2)])
	AMG$TASK<-"AMG" ; REST1$TASK<-"REST1" ; REST2$TASK<-"REST2"
	FIGURE<-rbind(REST1,AMG,REST2)
	FIGURE$TASK<-factor(FIGURE$TASK, levels=c("REST1","AMG","REST2"))
	FIGURE<-merge(FIGURE,MDD,by='sub')
	REST1<-FIGURE[which(FIGURE$TASK == "REST1"),]
	REST1$FD_MEAN<-REST1$FD_MEAN_REST1
	REST1<-REST1[,!grepl("FD_MEAN_",names(REST1))]
	AMG<-FIGURE[which(FIGURE$TASK == "AMG"),]
	AMG$FD_MEAN<-AMG$FD_MEAN_AMG
	AMG<-AMG[,!grepl("FD_MEAN_",names(AMG))]
	REST2<-FIGURE[which(FIGURE$TASK == "REST2"),]
	REST2$FD_MEAN<-REST2$FD_MEAN_REST2
	REST2<-REST2[,!grepl("FD_MEAN_",names(REST2))]
	REST1FD<-REST1[,c("sub","TASK","FD_MEAN")]
	AMGFD<-AMG[,c("sub","TASK","FD_MEAN")]
	REST2FD<-REST2[,c("sub","TASK","FD_MEAN")]
	MOTION<-rbind(REST1FD,AMGFD,REST2FD)
	FIGURE<-merge(FIGURE,MOTION,by=c("sub","TASK"),all=TRUE)
	FIGURE<-FIGURE[,!grepl("FD_MEAN_",names(FIGURE))]
	write.csv(REST1,paste0(DIR_PROJECT,"/analyses/IntraFlux/Aggregate_NetStr_REST1.csv"),row.names=FALSE)
	write.csv(AMG,paste0(DIR_PROJECT,"/analyses/IntraFlux/Aggregate_NetStr_AMG.csv"),row.names=FALSE)
	write.csv(REST2,paste0(DIR_PROJECT,"/analyses/IntraFlux/Aggregate_NetStr_REST2.csv"),row.names=FALSE)
	write.csv(FIGURE,paste0(DIR_PROJECT,"/analyses/IntraFlux/Aggregate_NetStr_Longitudinal.csv"),row.names=FALSE)

}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
