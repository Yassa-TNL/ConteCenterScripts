#! /usr/bin/env Rscript
#$ -q yassalab,free*
#$ -pe openmp 1-4
#$ -R y
#$ -ckpt restart
################

print("Reading Arguments")

args <- commandArgs(trailingOnly=TRUE)
DIR_LOCAL_APPS = args[1]
DIR_LOCAL_DATA = args[2]

suppressMessages(require(ggplot2))
TODAY=gsub("-","",Sys.Date())

################################################################
##### If Not Specified Find All Task Names To Be Processed #####
################################################################

DIR_DATASETS=dirname(list.files(path=DIR_LOCAL_DATA, full.names=T, recursive=T, pattern = "_QA-Summary_"))
for (DIR_TASK in DIR_DATASETS[grep("prestats",DIR_DATASETS)]){
	LABEL_TASK=basename(gsub("prestats","",DIR_TASK))
	FILE_INFO <- file.info(list.files(DIR_TASK, pattern = "_QA-Summary_", full.names = T))
	FILE_QA<-rownames(FILE_INFO)[which.max(FILE_INFO$mtime)]
	CONTENT<-read.csv(FILE_QA)
	CONTENT$X<-NULL
	print(paste0("Curating Confound2 Data From All Pipelines"))
	for (DIR_PIPE in list.files(path = paste0(DIR_LOCAL_APPS,"/xcpengine"), full.names=T, pattern="fc")){
		LABEL_PIPE=basename(gsub("fc-","",DIR_PIPE))
		for (ROW in 1:nrow(CONTENT)){
			IDS<-CONTENT[ROW,which(!is.na(match(colnames(CONTENT), c("sub","ses"))))]
			if (length(IDS) == 1){
				SUB<-IDS[1]
				DIR_ROOT<-paste0(DIR_PIPE,"/sub-",SUB,"/task-",LABEL_TASK)
			} else {
				SUB<-IDS[1]
				SES<-IDS[2]
				DIR_ROOT<-paste0(DIR_PIPE,"/sub-",SUB,"/ses-",SES,"/task-",LABEL_TASK)
			}
			CENSORED<-list.files(DIR_ROOT, recursive=T, full.names=T, pattern="_nVolumesCensored.txt")
			REGRESSED<-list.files(DIR_ROOT, recursive=T, full.names=T, pattern="_modelParameterCount.txt")
			CHECKDIR<-length(which(grepl("combine", CENSORED) == TRUE))
			if (length(CENSORED) == 0 | length(REGRESSED) == 0){
				SKIP<-"Skipping Data Curation Due To Missing Files"
			} else if (length(CENSORED) == 1 & length(REGRESSED) == 1){
				VAL_CEN<-read.table(CENSORED)
				VAL_REG<-read.table(REGRESSED)	
				CONTENT[ROW,paste0("CENSOREDx",LABEL_PIPE)] <- VAL_CEN
				CONTENT[ROW,paste0("REGRESSEDx",LABEL_PIPE)] <- VAL_REG
				CONTENT[ROW,paste0("DOFLOSTx",LABEL_PIPE)] <- VAL_CEN + VAL_REG
			} else if (length(CENSORED)+length(REGRESSED) > 2 & CHECKDIR == 1){
				VAL_CEN<-read.table(CENSORED[grep("combine",CENSORED)])
				VAL_REG<-read.table(REGRESSED[grep("combine",REGRESSED)])
				CONTENT[ROW,paste0("CENSOREDx",LABEL_PIPE)] <- VAL_CEN
				CONTENT[ROW,paste0("REGRESSEDx",LABEL_PIPE)] <- VAL_REG
				CONTENT[ROW,paste0("DOFLOSTx",LABEL_PIPE)] <- VAL_CEN + VAL_REG
			} else {
				CONTENT[ROW,paste0("CENSOREDx",LABEL_PIPE)] <- NA
				CONTENT[ROW,paste0("REGRESSEDx",LABEL_PIPE)] <- NA
				CONTENT[ROW,paste0("DOFLOSTx",LABEL_PIPE)] <- NA
			}
		}
	}


	print(paste0("Creating Figure of DOF Lost From Each Pipeline")
	CONTENT <- CONTENT[,colSums(is.na(CONTENT))<nrow(CONTENT)]
	QADATA<-CONTENT[,c(grep("DOFLOST",names(CONTENT)))]
	QADATA<-QADATA[names(sort(colMeans(QADATA, na.rm=TRUE)))]
	names(QADATA)<-substring(names(QADATA), 9)
	MISS<-colSums(is.na(QADATA))
	for (col in 1:ncol(QADATA)){
		names(QADATA)[col]<-paste0(names(QADATA)[col],"(NAs:",MISS[col],")")
	}
	QADATA<-stack(QADATA)
	suppressWarnings(dir.create(paste0(gsub("prestats","confound2",DIR_TASK))))
	DOF_OUTPUT=paste0(gsub("prestats","confound2",DIR_TASK),"/n",nrow(CONTENT),"_DOFLOST-boxplot_task-",LABEL_TASK,".pdf")
	ggplot(QADATA, aes(x=ind, y=values)) + 
 		geom_boxplot(outlier.shape=NA) +
 		geom_jitter(position=position_jitter(width=.15, height=0)) +
		ggtitle(paste("Degrees of Freedom Used From Each Preprocessing Pipeline For",LABEL_TASK,"Task")) +
		xlab("Preprocessing Pipelines") +
		ylab("Degrees of Freedom Lost") +
  		theme(axis.title.x=element_text(size = rel(1.25),face = "bold"),
		axis.title.y = element_text(size = rel(1.25),face = "bold"),
		plot.title = element_text(size = rel(1.25),face = "bold"),
		axis.text.x = element_text(face="bold", size=12),
		axis.text.y = element_text(face="bold", size=12),
		panel.background = element_rect(fill = "white", colour = "black"),
		legend.position = "top")
	suppressWarnings(ggsave(file=DOF_OUTPUT, device = "pdf",width = 14, height = 7, units = c("in")))
	Sys.chmod(DOF_OUTPUT, mode = "0755")

################################################
### Create Figure of Degrees Of Freedom Lost ###
################################################

	for (DIR_PIPE in list.files(path = paste0(DIR_LOCAL_APPS,"/xcpengine"), full.names=T, pattern="fc")){
		QADATA<-CONTENT[,which(!is.na(match(colnames(CONTENT), c("sub","ses","fdMEAN"))))]
		LABEL_PIPE=basename(gsub("fc-","",DIR_PIPE))
		for (ROW in 1:nrow(QADATA)){
			IDS<-QADATA[ROW,which(!is.na(match(colnames(QADATA), c("sub","ses"))))]
			if (length(IDS) == 1){
				names(QADATA)[1]<-c("id0","motion")
				SUB<-IDS[1]
				DIR_ROOT<-paste0(DIR_PIPE,"/sub-",SUB,"/task-",LABEL_TASK)
			} else {
				names(QADATA)[1:3]<-c("id0","id1","motion")
				SUB<-IDS[1]
				SES<-IDS[2]
				DIR_ROOT<-paste0(DIR_PIPE,"/sub-",SUB,"/ses-",SES,"/task-",LABEL_TASK)
			}
			FCON<-list.files(DIR_ROOT, recursive=T, full.names=T, pattern="_power264_network.txt")
			CHECKDIR<-length(which(grepl("combine", CENSORED) == TRUE))
			if (length(FCON) == 1){
				QADATA[ROW,"connectivity"]<-paste0(FCON)
			} else if (length(FCON) > 1 & CHECKDIR == 1){
				FCON<-FCON[grep("combine",FCON)]
				QADATA[ROW,"connectivity"]<-paste0(FCON)
			} else {
				QADATA[ROW,"connectivity"]<-NA
			}
		}
		QADATA<-QADATA[complete.cases(QADATA$connectivity),]
		suppressWarnings(dir.create(paste0(gsub("prestats","qcfc",DIR_TASK))))
		write.table(QADATA,paste0(gsub("prestats","qcfc",DIR_TASK),"/n",nrow(QADATA),"_fc-",LABEL_PIPE,"_Cohort.csv"),quote = FALSE, sep= ",",row.names=FALSE)
		Sys.chmod(paste0(gsub("prestats","qcfc",DIR_TASK),"/n",nrow(QADATA),"_fc-",LABEL_PIPE,"_Cohort.csv"), mode = "0755")
	}
	write.table(CONTENT,paste0(gsub("prestats","confound2",DIR_TASK),"/n",nrow(CONTENT),"_QA-Summary_task-",LABEL_TASK,".csv"),quote = FALSE, sep= ",",row.names=FALSE)
	Sys.chmod(paste0(gsub("prestats","confound2",DIR_TASK),"/n",nrow(CONTENT),"_QA-Summary_task-",LABEL_TASK,".csv"), mode = "0755")
}

################################################
### Create Figure of Degrees Of Freedom Lost ###
################################################

THRFILES<-grep("evalQC",list.files(path = DIR_LOCAL_DATA, include.dirs=FALSE, pattern = "thr.csv", recursive=TRUE))
THRFILES<-list.files(path = DIR_LOCAL_DATA, include.dirs=FALSE, pattern = "thr.csv", recursive=TRUE)[THRFILES]

for (THRFILE in THRFILES){
	print(paste0("Now Reorganizing The Threshold Dataset From: ",THRFILE))
	DATASET<-read.csv(paste0(DIR_LOCAL_DATA,'/',THRFILE))
	LEN_MATRIX <- 1
	while (((LEN_MATRIX*LEN_MATRIX)+LEN_MATRIX)/2 < dim(DATASET)[1]+1){
		LEN_MATRIX = LEN_MATRIX+1
	}
	NET<-as.data.frame(matrix(NA, nrow=LEN_MATRIX, ncol= LEN_MATRIX))
	for (ROW in 1:dim(DATASET)[1]){
		DIM1<-DATASET[ROW,1]
		DIM2<-DATASET[ROW,2]
		VALUE<-DATASET[ROW,3]
		NET[DIM1,DIM2]<-VALUE
		NET[DIM2,DIM1]<-VALUE
	}
	for (NUM in 1:LEN_MATRIX){
		NET[NUM,NUM]<-0
	}
	write.table(NET, file=paste0(DIR_LOCAL_DATA,"/",gsub("thr.csv","thr.net",THRFILE)), quote=FALSE, sep='\t', col.names = TRUE)
	Sys.chmod(paste0(DIR_LOCAL_DATA,"/",gsub("thr.csv","thr.net",THRFILE)), mode = "0775", use_umask = TRUE)
}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
