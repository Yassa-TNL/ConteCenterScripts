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

######################################################
##### Read in Dataset of Brain Development Model #####
######################################################

ModelData<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/F1_sub-51_ses-3_scans-153/n153_Within-Traj_Model.csv")
ModelData$Variable<-NULL
ModelData$Age<-round(ModelData$x,2)

###################################################################
##### Read in Independent Dataset and Select New Participants #####
###################################################################

ModelSample<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/F1_sub-51_ses-3_scans-153/n153_Figure-1_20190912.csv")
T1w<-read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/T1w/20190909/n362_Aseg_volume_20190909.csv")
Demo<-read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/Demo/n275_Age+Sex_20190829.csv")
Combined<-merge(Demo,T1w, by=c("sub","ses"))
SameSubs<-which(Combined$sub %in% ModelSample$sub)
NewSubs<-Combined[-c(SameSubs),]
NEWSUB<-unique(NewSubs$sub)

FinalSample<-as.data.frame(NewSubs[0,])
  for (x in NEWSUB){
  firstscan<-which(NewSubs$sub == x)[1]
  row<-NewSubs[firstscan,]
  FinalSample<-rbind(FinalSample,row)
}
FinalSample$Gender<-as.factor(FinalSample$Gender)

####################################################################
### Make Calculations of Subject-Level Devaitions from Brain Age ###
####################################################################

maxsubs<-dim(FinalSample)[1]
for (x in 1:maxsubs){

  SubjAge<-FinalSample[x,"AgeAtScan"]
  SubjGMV<-FinalSample[x,"TotalGrayVol"]
  AgeBinRow<-which.min(abs(ModelData$Age - SubjAge))
  DevScore <- SubjGMV - ModelData[AgeBinRow,"smooth"]
  FinalSample[x,"GMV_DevScore"]<- DevScore 

}

FinalSample<-FinalSample[order(FinalSample$GMV_DevScore,decreasing=FALSE),]

#######################################################
### Create Figure of Subject-Level Deviation Scores ###
#######################################################

FINAL<-ggplot() + 
     geom_smooth(data=ModelData,aes(Age,smooth),fill="#654321", colour="#654321", size=2.5) + 
     geom_smooth(data=ModelData,aes(Age,lower),fill="#654321",linetype="dashed", colour="#654321", size=1.5) + 
     geom_smooth(data=ModelData,aes(Age,upper),fill="#654321",linetype="dashed", colour="#654321", size=1.5) +
     geom_point(data=FinalSample, aes(AgeAtScan,TotalGrayVol), colour="#0eb302", size=2)  
#     geom_smooth(data=SlopeTP2,aes(x,smooth),fill="#00aaff", colour="#00aaff", size=2.25) + 

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
