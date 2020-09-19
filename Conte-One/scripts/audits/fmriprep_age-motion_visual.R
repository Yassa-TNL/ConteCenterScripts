#!/usr/bin/env Rscript
#$ -q yassalab,free*
#$ -pe openmp 4
#$ -R y
#$ -ckpt restart
################

print("Reading Arguments")

args <- commandArgs(trailingOnly=TRUE)
DIR_LOCAL_DATA <- args[1]
FILES_QA_EPI <- args[2]
FILE_DEMO_AGE <-args[3] 

#############################################################
##### Quality of Life Check To Ensure Input Files Exist #####
#############################################################

print("Searching for Input Files & Defining Output Paths")

QualityofLife<-0
FILES_QA_EPI=strsplit(FILES_QA_EPI, "_")[[1]]
ALLFILES<-list.files(DIR_LOCAL_DATA, pattern="Quality-Assurance", full.names=TRUE, recursive=TRUE)
MASTER<-list.files(DIR_LOCAL_DATA, pattern=FILE_DEMO_AGE, full.names=TRUE, recursive=TRUE)
for (sequence in FILES_QA_EPI){
	NUM<-length(grep(sequence, ALLFILES))
	QualityofLife<-QualityofLife+NUM
}

if (length(ALLFILES) == 0){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	print(paste("No Files Found Within Your Input Path - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	quit(save="no")

} else if (length(MASTER) == 0){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	print(paste("Master File Not Found - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	quit(save="no")

} else if (QualityofLife < length(FILES_QA_EPI)){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡  ! ⚡ ! ⚡ ! ⚡ "))
	print(paste("Missing Specific BOLD QA File As Defined By Task Label(s)  - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡  ! ⚡ ! ⚡ ! ⚡ "))
	quit(save="no")	

} else {

	GrpFig<-paste0(DIR_LOCAL_DATA,"/Visuals/QA_fmriprep_BOLD/GrpTraj-Scatter_Age-FD_BOLD.pdf")
	MainEffectTable<-paste0(DIR_LOCAL_DATA,"/Visuals/QA_fmriprep_BOLD/GrpTraj-lme_Age_BOLD.csv")
	InteractionTable<-paste0(DIR_LOCAL_DATA,"/Visuals/QA_fmriprep_BOLD/GrpTraj-lme_AgeandGender_BOLD.csv")
	dir.create(dirname(GrpFig), showWarnings = FALSE, recursive = TRUE, mode = "0775")

}

######################################################
##### Merge All Input Files and Save Merged File #####
######################################################

print("Curating Input Files and Save Master Spreadsheet")

MASTER<-read.csv(MASTER)
MASTER<-MASTER[,c(!grepl("^X",names(MASTER)))]

for (sequence in FILES_QA_EPI){
	MASTER<-MASTER[,c(!grepl(paste0("_",sequence),names(MASTER)))]
	FileNum <- grep(sequence, ALLFILES)
	if (length(FileNum) > 1){
		INTEREST<-ALLFILES[grep(sequence, basename(ALLFILES))]
		PrefixFileNum <- grep("^n", unlist(strsplit(basename(INTEREST), "_", fixed = FALSE)))
		PrefixFileName <- unlist(strsplit(basename(INTEREST), "_", fixed = FALSE))[PrefixFileNum]
		FilewithMAXSubs <- max(as.numeric(gsub("n","",PrefixFileName)))
		IndNum <- grep(paste0("^n",FilewithMAXSubs),basename(ALLFILES))
		FileNum<-IndNum[which(IndNum %in% FileNum)]
	}
	data <- read.csv(ALLFILES[FileNum])
	data <- data[,colnames(data)[c(2,3,4,6)]]
	colnames(data)[3:4] <- paste(colnames(data)[3:4],sequence, sep = "_")
	data[3:4] <- round((data)[3:4], digits=3)
	MASTER <- merge(MASTER, data, by=c("sub","ses"), all=TRUE)
}

MASTER$Gender<-as.factor(MASTER$Gender)
write.csv(MASTER,list.files(DIR_LOCAL_DATA, pattern=FILE_DEMO_AGE, full.names=TRUE, recursive=TRUE))
attach(MASTER)

##################################
##### Load Required Packages #####
##################################

print("Loading Required Packages")

suppressMessages(require(ggplot2))
suppressMessages(require(cowplot))
suppressMessages(require(RColorBrewer))
suppressMessages(require(visreg))
suppressMessages(require(nlme))
suppressMessages(require(lme4))
suppressMessages(require(gamm4))
suppressMessages(require(stats))
suppressMessages(require(knitr))
suppressMessages(require(mgcv))

####################################################################
##### Calculate Cross-Sectional Models at Each Timepoint (GAM) #####
####################################################################

print("Processing Models To Generate Scatterplot")

AnalyzeSlope <- function(EPI_TASK){
	MODEL <- lapply(EPI_TASK, function(x){
		gamm4(substitute(i ~ AgeAtScan, list(i = as.name(x))), random=as.formula(~(1|sub)), data=MASTER, REML=T)$gam
	})
	Results <- lapply(MODEL, summary)
	PlotData <- visreg(MODEL[[1]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
	GAM_smooths <- data.frame(Variable = PlotData$meta$x,
		x=PlotData$fit[[PlotData$meta$x]],
		smooth=PlotData$fit$visregFit,
		lower=PlotData$fit$visregLwr,
		upper=PlotData$fit$visregUpr)
	return(GAM_smooths)
}

SlopeREST<-AnalyzeSlope("fdMEAN_REST")
SlopeAMG<-AnalyzeSlope("fdMEAN_AMG")
SlopeHIPP<-AnalyzeSlope("fdMEAN_HIPP")

##############################################
### Overlap Models on the Same Scatterplot ###
##############################################

print("Plotting Models In Single Scatterplot")

FINAL<-ggplot() + 
	geom_smooth(data=SlopeREST,aes(x,smooth),fill="#01193f", colour="#01193f", size=2.75) + 
	geom_point(data=MASTER, aes(AgeAtScan,fdMEAN_REST), colour="#01193f", size=1.1) + 
	geom_smooth(data=SlopeAMG,aes(x,smooth),fill="#6baddf", colour="#6baddf", size=2.75) + 
	geom_point(data=MASTER, aes(AgeAtScan,fdMEAN_AMG), colour="#6baddf", size=1.1) + 
	geom_smooth(data=SlopeHIPP,aes(x,smooth),fill="#d2b486", colour="#d2b486", size=2.75) + 
	geom_point(data=MASTER, aes(AgeAtScan,fdMEAN_HIPP), colour="#d2b486", size=1.1) +
	ggtitle(paste("Age-Related Changes in Head Motion During Functional Scans")) +
	xlab("Scan Age (Years)") +
	ylab("Head Motion (Mean Framewise Displacement)") +
	xlim(8.5, 16) +
	ylim(0.0, 3.0) +
	theme_classic() +
  	theme(plot.title = element_text(size = rel(1.1),face = "bold"),
	axis.title.x=element_text(size = rel(1.25)),
	axis.title.y=element_text(size = rel(1.25))) +
	annotate("text", x = 15, y = 2.85, label = paste0("Resting-State"),colour = "#01193f",size = 4.5) +
	annotate("text", x = 15, y = 2.75, label = paste0("Amygdala-Task"),colour = "#6baddf",size = 4.5) +
	annotate("text", x = 15, y = 2.65, label = paste0("Hippocampus-Task"),colour = "#d2b486",size = 4.5)
suppressWarnings(suppressMessages(ggsave(file= GrpFig, plot = FINAL, device = "pdf",width = 7, height = 7, units = c("in"))))
Sys.chmod(GrpFig, mode = "0775")

####################################
### Create Table of Main Effects ###
####################################

print("Creating Table of Results For Age-Related Changes")

rMASTER<-MASTER[complete.cases(MASTER$AgeAtScan),]
MAIN_OUTPUT<-data.frame(matrix(NA, nrow = 0, ncol = 7))

AnalyzeMainEffects <- function(EPI_TASK){
	MODEL <- lapply(EPI_TASK, function(x){
		gamm4(substitute(i ~ AgeAtScan, list(i = as.name(x))), random=as.formula(~(1|sub)), data=MASTER, REML=T)$gam
	})
	Results <- lapply(MODEL, summary)
	REDUCED<-rMASTER[complete.cases(rMASTER[,grep(EPI_TASK,names(rMASTER))]),]
	TASKNAME<-gsub("fdMEAN_","",EPI_TASK)
	nSUB<-length(unique(REDUCED$sub))
	nSES<-nrow(REDUCED)
	RSQ<-round(Results[[1]]$r.sq, digits=3)
	STDERR<-as.numeric(round(Results[[1]]$se[2], digits=3))
	TVAL<-as.numeric(round(Results[[1]]$p.t[2], digits=3))
	PVAL<-as.numeric(round(Results[[1]]$p.pv[2], digits=3))
	addrow <- t(as.matrix(c(TASKNAME,nSUB,nSES,RSQ,STDERR,TVAL,PVAL)))
	MAIN_OUTPUT<-as.matrix(MAIN_OUTPUT)	
	MAIN_OUTPUT<-as.data.frame(rbind(MAIN_OUTPUT,addrow))
	names(MAIN_OUTPUT)<-c("Task","Subjects","Sessions", "R-squared", "Standard Error", "t-value", "p-value")
	return(MAIN_OUTPUT)
}


MAIN_OUTPUT<-AnalyzeMainEffects("fdMEAN_REST")
MAIN_OUTPUT<-AnalyzeMainEffects("fdMEAN_AMG")
MAIN_OUTPUT<-AnalyzeMainEffects("fdMEAN_HIPP")

write.csv(MAIN_OUTPUT, MainEffectTable)
Sys.chmod(MainEffectTable, mode = "0775")

#######################################################
### Overlap the Four Models on the Same Scatterplot ###
#######################################################

print("Creating Table of Results For Potential Moderating Effects of Sex")

INTER_OUTPUT<-data.frame(matrix(NA, nrow = 0, ncol = 7))

AnalyzeInteractionEffects <- function(EPI_TASK){
	MODEL <- lapply(EPI_TASK, function(x){
		gamm4(substitute(i ~ AgeAtScan*Gender, list(i = as.name(x))), random=as.formula(~(1|sub)), data=MASTER, REML=T)$gam
	})
	Results <- lapply(MODEL, summary)
	REDUCED<-rMASTER[complete.cases(rMASTER[,grep(EPI_TASK,names(rMASTER))]),]
	TASKNAME<-gsub("fdMEAN_","",EPI_TASK)
	nSUB<-length(unique(REDUCED$sub))
	nSES<-nrow(REDUCED)
	RSQ<-round(Results[[1]]$r.sq, digits=3)
	STDERR<-as.numeric(round(Results[[1]]$se[4], digits=3))
	TVAL<-as.numeric(round(Results[[1]]$p.t[4], digits=3))
	PVAL<-as.numeric(round(Results[[1]]$p.pv[4], digits=3))
	addrow <- t(as.matrix(c(TASKNAME,nSUB,nSES,RSQ,STDERR,TVAL,PVAL)))
	INTER_OUTPUT<-as.matrix(INTER_OUTPUT)	
	INTER_OUTPUT<-as.data.frame(rbind(INTER_OUTPUT,addrow))
	names(INTER_OUTPUT)<-c("Task","Subjects","Sessions", "R-squared", "Standard Error", "t-value", "p-value")
	return(INTER_OUTPUT)
}


INTER_OUTPUT<-AnalyzeInteractionEffects("fdMEAN_REST")
INTER_OUTPUT<-AnalyzeInteractionEffects("fdMEAN_AMG")
INTER_OUTPUT<-AnalyzeInteractionEffects("fdMEAN_HIPP")

write.csv(INTER_OUTPUT,InteractionTable)
Sys.chmod(InteractionTable, mode = "0775")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
