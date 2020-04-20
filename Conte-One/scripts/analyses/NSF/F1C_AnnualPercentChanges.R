#!/usr/bin/env Rscript
###################################################################################################
##########################                   NSF-GRFP                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

suppressMessages(require(ggplot2))
suppressMessages(require(cowplot))
suppressMessages(require(visreg))
suppressMessages(require(nlme))
suppressMessages(require(stats))
suppressMessages(require(knitr))
suppressMessages(require(mgcv))
suppressMessages(require(plyr))
suppressMessages(require(fslr))
suppressMessages(require(voxel))

#####################
##### Load Data #####
#####################

alltimepoints<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/F1_sub-51_ses-3_scans-153/n153_Figure-1_20190912.csv")
alltimepoints$X.1<-NULL
attach(alltimepoints)
alltimepoints$APR<-0

#########################################################
##### Caculate Subject Level Annual Percent Changes #####
#########################################################

Subjects<-unique(alltimepoints$sub)

for (x in Subjects){
  Single<-alltimepoints[which(alltimepoints$sub==x),]
  fit <- gam(TotalGrayVol ~ Session, method="REML", data=Single)
  Output<-visreg(fit, "Session",scale = "linear", plot = FALSE)
  age1<-Single$AgeAtScan[1]
  age3<-Single$AgeAtScan[3]
  increments<-(age3-age1)/101
  Output$fit$AgeSlope<-0
  for (y in 1:101){
    INCREASE<-y*increments
    Output$fit$AgeSlope[y]<-age1+INCREASE
  }
  DATA<-data.frame(Output$fit$Session,Output$fit$visregFit,Output$fit$AgeSlope)
  names(DATA)<-c("SES","VOL","AGE")
  startVOL<-DATA[1,2]
  endVOL<-DATA[101,2]
  DeltaVOL<-endVOL-startVOL
  startAGE<-DATA[1,3]
  endAGE<-DATA[101,3]
  DeltaAGE<-endAGE-startAGE
  APR<-(DeltaVOL/startVOL)/DeltaAGE
  alltimepoints[which(alltimepoints$sub==x),"APR"] <- APR
}

#####################################################
##### See Distribution of Annual Percent Change #####
#####################################################

summary(alltimepoints$APR)
sd(alltimepoints$APR)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
