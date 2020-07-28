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
suppressMessages(require(RColorBrewer))
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
	HEADER<-gsub("-","_",gsub("atl-","",ATLAS))
	CONTENT[,paste0(HEADER,"_tstat")]<-NA
	CONTENT[,paste0(HEADER,"_zstat")]<-NA
}

for (ROW in 1:nrow(CONTENT)){
	SUB<-CONTENT[ROW,1]
	SES<-CONTENT[ROW,2]
	for (ATLAS in ATLASES){
		OUTPUT<-read.table(FEATQUERY[grep(paste0("sub-",SUB,"_ses-",SES,".feat/",ATLAS),FEATQUERY)])
		T_COL<-grep(gsub("-","_",gsub("atl-","",ATLAS)),names(CONTENT))[1]
		Z_COL<-grep(gsub("-","_",gsub("atl-","",ATLAS)),names(CONTENT))[2]
		CONTENT[ROW,T_COL]<-OUTPUT[3,6]
		CONTENT[ROW,Z_COL]<-OUTPUT[6,6]
	}
}

write.csv(CONTENT,paste0(DIR_PROJECT,"/analyses/IntraFlux/Aggregate_Dataset.csv"),row.names=FALSE)

##############################################################################################################
##### Analyze Individual Differences in Depression and Amygdala Reactivity to Fearful Facial Expressions #####
##############################################################################################################

m1<-lm(datadriven_AMG_pro_cope3_zstat~scl.CDI_MD+AgeAtScan+Gender+FD_MEAN_AMG, data=CONTENT)
m2<-lm(brainnetome_AMG_pro_211_214_zstat~scl.CDI_MD+AgeAtScan+Gender+FD_MEAN_AMG, data=CONTENT)
m3<-lm(datadriven_clust1_bin_cope3_zstat~scl.CDI_MD+AgeAtScan+Gender+FD_MEAN_AMG, data=CONTENT)
m4<-lm(datadriven_clust2_bin_cope3_zstat~scl.CDI_MD+AgeAtScan+Gender+FD_MEAN_AMG, data=CONTENT)
m5<-lm(datadriven_clust3_bin_cope3_zstat~scl.CDI_MD+AgeAtScan+Gender+FD_MEAN_AMG, data=CONTENT)
m6<-lm(datadriven_clust4_bin_cope3_zstat~scl.CDI_MD+AgeAtScan+Gender+FD_MEAN_AMG, data=CONTENT)
m7<-lm(datadriven_clust5_bin_cope3_zstat~scl.CDI_MD+AgeAtScan+Gender+FD_MEAN_AMG, data=CONTENT)
m8<-lm(datadriven_clust6_bin_cope3_zstat~scl.CDI_MD+AgeAtScan+Gender+FD_MEAN_AMG, data=CONTENT)

MODELS<-list(m1,m2,m3,m4,m5,m6,m7,m8)
OUTPUT <- lapply(MODELS, summary)

plotdata <- visreg(MODELS[[6]],'scl.CDI_MD',type = "conditional",scale = "linear", plot = FALSE)
smooths <- data.frame(Variable = plotdata$meta$x,
                      x=plotdata$fit[[plotdata$meta$x]],
                      smooth=plotdata$fit$visregFit,
                      lower=plotdata$fit$visregLwr,
                      upper=plotdata$fit$visregUpr)
predicts <- data.frame(Variable = "dim1",
                       x=plotdata$res$scl.CDI_MD,
                       y=plotdata$res$visregRes)

figures<-ggplot() +
	geom_point(data = predicts, aes(x, y, colour = x), alpha= 1) +
	scale_colour_gradientn(colours = "#000000",  name = "") +
	geom_line(data = smooths, aes(x = x, y = smooth), colour = "#000000",size=3) +
	geom_line(data = smooths, aes(x = x, y=lower), linetype="dashed", colour = "#000000", alpha = 0.9, size = 2) +
	geom_line(data = smooths, aes(x = x, y=upper), linetype="dashed",colour = "#000000", alpha = 0.9, size = 2) +
	theme(legend.position = "none") +
	labs(x = "Symptoms of Depression (CDI Scale)", y = "Reactivity to Fearful Faces (z-score)") +
	theme(axis.title=element_text(size=24,face="bold"), axis.text=element_text(size=18), axis.title.x=element_text(color = "black"), axis.title.y=element_text(color = "black")) + 
	theme_classic()

SUBSET<-CONTENT[,c(3,5:8)]
names(SUBSET)<-c("Age","MoodEnt","MoodLvl","Depression","Motion")
MATRIX<-cor(SUBSET, use="pairwise.complete.obs")
corrplot.mixed(MATRIX, lower.col = "black", number.cex = 1.75)

####################################################################################################
##### Find All Processed Scans And Extract Signal Using Every Available Atlas For Each Subject #####
####################################################################################################

for (DIM in list.files(path=paste0(DIR_PROJECT,"/analyses/IntraFlux/Dual_Regress_Analysis"), pattern="dim")){
	BASE_DIR=paste0(DIR_PROJECT,"/analyses/IntraFlux/Dual_Regress_Analysis/",DIM)
	OUT_FILES=list.files(path=BASE_DIR,full.names=T, recursive=T,pattern="aggregated")
	MASTER<-data.frame(matrix(ncol = dim(read.csv(OUT_FILES[1]))[2], nrow = 0))
	colnames(MASTER)<-names(read.csv(OUT_FILES[1]))
	for (INDEX in 1:length(OUT_FILES)){
		print(paste0(WORKING: ,OUT_FILES[INDEX]))
		CONTENT<-read.csv(OUT_FILES[INDEX])
		MASTER<-rbind(MASTER,CONTENT)
	}
}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
