#!/usr/bin/env Rscript
###################################################################################################
##########################                 GrangerDTI                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

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
suppressMessages(require(plyr))
suppressMessages(require(fslr))
suppressMessages(require(voxel))
suppressMessages(require(stringr))
suppressMessages(require(plotly))

#######################################################
##### Prepare Data For ScatterPlots of Each Model #####
#######################################################

alltimepoints<-read.csv("/dfs2/yassalab/rjirsara/GrangerDTI/Data/COVA-n424_Age+Sex_20191008_RESP-n240_GFA+Vol_20191005/Preliminary/n206_gamm4_sAgeAtScank4_random_1sub_Merged.csv")
alltimepoints$Gender<-as.factor(alltimepoints$Gender)
BrainRegions <- names(alltimepoints)[6:8]
TP1<-alltimepoints[which(alltimepoints$Session==1),]
TP2<-alltimepoints[which(alltimepoints$Session==2),]
TP3<-alltimepoints[which(alltimepoints$Session==3),]
attach(alltimepoints)

####################################################
##### Calculate Non-Linear Longitudinal Models #####
####################################################

GAMM4_Models <- lapply(BrainRegions, function(x) {
	gamm4(substitute(i ~ s(AgeAtScan, k=4), list(i = as.name(x))), random=as.formula(~(1|sub)), data=alltimepoints, REML=T)$gam
})

GAMM4_Results <- lapply(GAMM4_Models, summary)


nonGFA_HIPPOCAMPUS <- visreg(GAMM4_Models[[1]],'AgeAtScan',type = "conditional",scale = "linear", plot = TRUE)
nonGFA_FASCICULUS <- visreg(GAMM4_Models[[2]],'AgeAtScan',type = "conditional",scale = "linear", plot = TRUE)
nonVOLUME <- visreg(GAMM4_Models[[3]],'AgeAtScan',type = "conditional",scale = "linear", plot = TRUE)

################################################
##### Calculate Linear Longitudinal Models #####
################################################

lme4_Models <- lapply(BrainRegions, function(x) {
	gamm4(substitute(i ~ AgeAtScan, list(i = as.name(x))), random=as.formula(~(1|sub)), data=alltimepoints, REML=T)$gam
})

lme_Results <- lapply(lme4_Models, summary)

linGFA_HIPPOCAMPUS <- visreg(lme4_Models[[1]],'AgeAtScan',type = "conditional",scale = "linear", plot = TRUE)
linGFA_FASCICULUS <- visreg(lme4_Models[[2]],'AgeAtScan',type = "conditional",scale = "linear", plot = TRUE)
linVOLUME <- visreg(lme4_Models[[3]],'AgeAtScan',type = "conditional",scale = "linear", plot = TRUE)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
