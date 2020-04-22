#!/usr/bin/env Rscript
######################

source("/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/data_analysis/levelplot/dwi_connmat_streamlines.R")

#####################
### 90 Plus Data ####
#####################

RESPONCE<-list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="90Plus.csv", full.names=TRUE)

INDEXES<-which(grepl(".csv",list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="90Plus", full.names=TRUE)) == FALSE )

for (INDEX in INDEXES){
	
	PREDICTOR<-list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="90Plus", full.names=TRUE)[INDEX]
	ConnMat(PREDICTOR,RESPONCE,"/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/analyses/GrangerDTI","~RAVLT.Learning.Sum.x","pearson",list("as.numeric"),NULL,NULL)

}


####################
### Beacon Data ####
####################

RESPONCE<-list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="BEACoN.csv", full.names=TRUE)

INDEXES<-which(grepl(".csv",list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="BEACoN", full.names=TRUE)) == FALSE )

for (INDEX in INDEXES){
	
	PREDICTOR<-list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="BEACoN", full.names=TRUE)[INDEX]
	ConnMat(PREDICTOR,RESPONCE,"/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/analyses/GrangerDTI","~RAVLT.Learning.Sum","pearson",list("as.numeric"),NULL,NULL)

}

###############################
### Beacon Data - RAVLT.A7 ####
###############################

RESPONCE<-list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="MERGED.csv", full.names=TRUE)

INDEXES<-which(grepl(".csv",list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="MERGED", full.names=TRUE)) == FALSE )

for (INDEX in INDEXES){
	
	PREDICTOR<-list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="MERGED", full.names=TRUE)[INDEX]
	ConnMat(PREDICTOR,RESPONCE,"/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/analyses/GrangerDTI","~RAVLT.A7","pearson",list("as.numeric"),NULL,NULL)

}

###############################
### Beacon Data - RAVLT.A7 ####
###############################

RESPONCE<-list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="MERGED.csv", full.names=TRUE)

INDEXES<-which(grepl(".csv",list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="MERGED", full.names=TRUE)) == FALSE )

for (INDEX in INDEXES){
	
	PREDICTOR<-list.files(path= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi", pattern="MERGED", full.names=TRUE)[INDEX]
	ConnMat(PREDICTOR,RESPONCE,"/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/analyses/GrangerDTI","~RAVLT.A7","pearson",list("as.numeric"),NULL,c("CA1","CA2","DG","CA3","SUB","ERC"))

}





DIR_RESPONCE_PATH<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi/n55_right_MERGED"
DIR_COVARIATE_PATH<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi/Covariates_MERGED.csv"
DIR_OUTPUT_PAT<-"/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/analyses/GrangerDTI"
FORMULA<-"~RAVLT.A7"
OPT_CORR_TYPE<-"pearson"
OPT_CHANGE_TYPE<-list("as.numeric")
OPT_SUBDIR_PATH<-"TESTING"
OPT_VARS_OF_INTEREST<-c("CA1","CA2","DG","CA3","SUB","ERC")




source("/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/data_analysis/levelplot/dwi_connmat_streamlines.R")

ConnMat(MATRICES = "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi/n55_left_MERGED",DIR_OUT="/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets/dwi/Covariates_MERGED.csv",IN_CSV= "/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/analyses/GrangerDTI",FORMULA="~RAVLT.A7",CORR_TYPE="pearson",CHANGE_CLASS=DIR_=list("as.numeric"),DIR_SUBOUT="TESTING",VARS_INTETREST=c("CA1","CA2","DG","CA3","SUB","ERC"))

ConnMat <- function(MATRICES, IN_CSV, DIR_OUT, FORMULA, CORR_TYPE="pearson", CHANGE_CLASS = NULL, DIR_SUBOUT = NULL , VARS_INTETREST = NULL){




