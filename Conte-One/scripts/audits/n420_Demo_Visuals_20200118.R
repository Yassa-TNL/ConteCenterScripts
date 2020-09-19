#!/usr/bin/env Rscript
######################

data<-read.csv("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/Audit_Master_ConteMRI.csv")

library(RColorBrewer)
library(ggplot2)
library(cowplot)
library(mgcv)

#######################################################################
##### Define Function To Break Dataset Into Individual Timepoints #####
#######################################################################

GetTimepoint <- function(dataset,TPnum){
	SUBJECTS<-unique(dataset[,"sub"])
	newdata=data.frame()
	for (x in SUBJECTS){	
		row<-which(dataset[,"sub"]== x )[TPnum]
		addrow<-dataset[row,]
		newdata<-rbind(newdata,addrow)
		newdata<-newdata[complete.cases(newdata[,"sub"]),]
	}
	return(newdata)
}

##################################################
##### Distribution For Full Sample T1w Scans #####
##################################################

data<-data[order(data$AgeAtScan),]
PreConte_TP1<-dim(GetTimepoint(data,1))[1]
PreConte_TP2<-dim(GetTimepoint(data,2))[1]
PreConte_TP3<-dim(GetTimepoint(data,3))[1]
PreConte_TP4<-dim(GetTimepoint(data,4))[1]

#################################################
##### Distribution For Post-Conte T1w Scans #####
#################################################

postdata<-data[which(data[,"ses"]!=0),]
PostData_TP1<-dim(GetTimepoint(postdata,1))[1]
PostData_TP2<-dim(GetTimepoint(postdata,2))[1]
PostData_TP3<-dim(GetTimepoint(postdata,3))[1]

################################################
##### Distribution For Resting-State Scans #####
################################################

REST_TASK<-postdata[which(postdata[,"REST"]==1),]
REST_TASK_TP1<-dim(GetTimepoint(REST_TASK,1))[1]
REST_TASK_TP2<-dim(GetTimepoint(REST_TASK,2))[1]
REST_TASK_TP3<-dim(GetTimepoint(REST_TASK,3))[1]

######################################################
##### Distribution For Amygdala Task-Based Scans #####
######################################################

AMG_TASK<-postdata[which(postdata[,"AMG"]==1),]
AMG_TASK_TP1<-dim(GetTimepoint(AMG_TASK,1))[1]
AMG_TASK_TP2<-dim(GetTimepoint(AMG_TASK,2))[1]
AMG_TASK_TP3<-dim(GetTimepoint(AMG_TASK,3))[1]

#########################################################
##### Distribution For Hippocampus Task-Based Scans #####
#########################################################

HIPP_TASK<-postdata[which(postdata[,"HIPP"]==1),]
HIPP_TASK_TP1<-dim(GetTimepoint(HIPP_TASK,1))[1]
HIPP_TASK_TP2<-dim(GetTimepoint(HIPP_TASK,2))[1]
HIPP_TASK_TP3<-dim(GetTimepoint(HIPP_TASK,3))[1]

#####################################################
##### Distribution For Diffusion Weighted Scans #####
#####################################################

DWI<-postdata[which(postdata[,"dwi"]==1),]
DWI_TP1<-dim(GetTimepoint(DWI,1))[1]
DWI_TP2<-dim(GetTimepoint(DWI,2))[1]
DWI_TP3<-dim(GetTimepoint(DWI,3))[1]

#####################################################################
##### Define Function to Plot the Repeated Scan Sessions by Age #####
#####################################################################

CreateDistributionFig <- function(Figure,Title){
	Figure[,"Gender"]<-as.factor(Figure[,"Gender"])
	Figure[,"Subject"] <- 0
	maxcol<-dim(Figure)[2]
	maxsubs<-length(unique(Figure[,"sub"]))

	for (x in 1:maxsubs){
		subid<-unique(Figure[,"sub"])[x]
		Figure[which(Figure[,"sub"]==subid),maxcol]<-x
	}

	OUTPUT<-ggplot(data=Figure, aes(x=AgeAtScan, y = Subject, group = Subject, color = Gender )) +
		ggtitle(paste(Title)) +
		geom_line(size=1.5) +
		geom_point(aes(size=-1.5)) +
		scale_color_manual(values=c("#e62929", "#2d81f7")) + 
		xlab("Age At Scan (Years)") +
		ylab("Subject Number Order by Enrollment") +
  		theme(axis.title.x=element_text(size = rel(1.50),face = "bold"),
		axis.title.y = element_text(size = rel(1.50),face = "bold"),
		plot.title = element_text(size = rel(1.55),face = "bold"),
		axis.text=element_text(size=12, face="bold"),
		panel.background = element_rect(fill = "white", colour = "black"),
		legend.position = "none")
	return(OUTPUT)
}

############################################################################
##### Create Figures of Repeated Scan Sessions Throughout Development  #####
############################################################################

### Full Sample ###

PATH<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/Visuals/Demographics/n420_SesbyAge-Full_20200120.pdf"
FULL_FIGURE<-CreateDistributionFig(data,"Full Sample: n215")
ggsave(file=PATH,device = "pdf", width = 5, height = 7,units = c("in"))
Sys.chmod(PATH, mode = "770")

### Post-Conte Sample ###
 
PATH<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/Visuals/Demographics/n315_SesbyAge-Post_20200120.pdf"
POST_FIGURE<-CreateDistributionFig(postdata,"Post-Conte Sample: n178")
ggsave(file=PATH,device = "pdf", width = 5, height = 7, units = c("in"))
Sys.chmod(PATH, mode = "770")

### At Least 2 Sessions Sample ###

FIRST<-GetTimepoint(postdata,1)
SECOND<-GetTimepoint(postdata,2)
THIRD<-GetTimepoint(postdata,3)
FIRST<-FIRST[(FIRST$sub %in% SECOND$sub),]
LONGITUDINAL<-rbind(FIRST,SECOND,THIRD)
PATH<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/Visuals/Demographics/n238_SesbyAge-Long_20200120.pdf"
LONG_FIGURE<-CreateDistributionFig(LONGITUDINAL,"Longitudinal Sample: n101")
ggsave(file=PATH,device = "pdf", width = 5, height = 7, units = c("in"))
Sys.chmod(PATH, mode = "770")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
