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

#######################################################
##### Prepare Data For ScatterPlots of Each Model #####
#######################################################

alltimepoints<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/COVA-n275_Age+Sex_20190829_RESP-n360_Aseg_volume_20190829/AllScans/n268_gamm4_sAgeAtScank4-Gender_random_1sub_Merged.csv")
alltimepoints<-alltimepoints[complete.cases(alltimepoints$AgeAtScan),]
alltimepoints$Gender<-as.factor(alltimepoints$Gender)

BrainRegions <- names(alltimepoints)[6:67]

print("Getting Cross-sectional Timepoint Datasets")

GetTimepoint <- function(TPnum){
  SUBJECTS<-unique(alltimepoints$sub)
  newdata=data.frame()
  for (x in SUBJECTS){	
	row<-which(alltimepoints$sub==x)[TPnum]
	addrow<-alltimepoints[row,]
	newdata<-rbind(newdata,addrow)
        newdata<-newdata[complete.cases(newdata$sub),]
  }
  return(newdata)
}

TP1<-GetTimepoint(1)
TP2<-GetTimepoint(2)
TP3<-GetTimepoint(3)
TP4<-GetTimepoint(4)

print("Remove 4th Timepoint because of Too Few Subjects")

Subswith4TP<-which(alltimepoints$sub %in% TP4$sub)
alltimepoints<-alltimepoints[-c(which(alltimepoints[Subswith4TP,3]==2)),]
attach(alltimepoints)

#############################################################
##### Calculate Longitudinal Model on All Scans (GAMM4) #####
#############################################################

GAMM4_Models <- lapply(BrainRegions, function(x) {
	gamm4(substitute(i ~ s(AgeAtScan,k=4) + Gender, list(i = as.name(x))), random=as.formula(~(1|sub)), data=alltimepoints, REML=T)$gam
})

GAMM4_Results <- lapply(GAMM4_Models, summary)

GAMM4_plotdata <- visreg(GAMM4_Models[[52]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
GAMM4_smooths <- data.frame(Variable = GAMM4_plotdata$meta$x,
                      x=GAMM4_plotdata$fit[[GAMM4_plotdata$meta$x]],
                      smooth=GAMM4_plotdata$fit$visregFit,
                      lower=GAMM4_plotdata$fit$visregLwr,
                      upper=GAMM4_plotdata$fit$visregUpr)

##############################################################
##### Calculate Cross-Sectional Model on All Scans (GAM) #####
##############################################################

AnalyzeSlope <- function(Timepoint){

  GAM_Models <- lapply(BrainRegions, function(x) {
	gam(substitute(i ~ s(AgeAtScan,k=4) + Gender, list(i = as.name(x))), method="REML", data=Timepoint)
  })
  GAM_Results <- lapply(GAM_Models, summary)
  attach(Timepoint)
  GAM_plotdata <- visreg(GAM_Models[[52]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
  GAM_smooths <- data.frame(Variable = GAM_plotdata$meta$x,
                      x=GAM_plotdata$fit[[GAM_plotdata$meta$x]],
                      smooth=GAM_plotdata$fit$visregFit,
                      lower=GAM_plotdata$fit$visregLwr,
                      upper=GAM_plotdata$fit$visregUpr)
  detach(Timepoint)
  return(GAM_smooths)
}

SlopeTP1<-AnalyzeSlope(TP1)
SlopeTP2<-AnalyzeSlope(TP2)
SlopeTP3<-AnalyzeSlope(TP3)
SlopeTP4<-AnalyzeSlope(TP4)

##################################################
### Overlap the Two Models on the Same Scatter ###
##################################################

FINAL<-ggplot() + 
     geom_smooth(data=SlopeTP1,aes(x,smooth),fill="#0037ff", colour="#0037ff", size=2) + 
     geom_point(data=TP1, aes(AgeAtScan,TotalGrayVol), colour="#0037ff") + 
     geom_smooth(data=SlopeTP2,aes(x,smooth),fill="#c40000", colour="#c40000", size=2) + 
     geom_point(data=TP2, aes(AgeAtScan,TotalGrayVol), colour="#c40000") + 
     geom_smooth(data=SlopeTP3,aes(x,smooth),fill="#1db52c", colour="#1db52c", size=2) + 
     geom_point(data=TP3, aes(AgeAtScan,TotalGrayVol), colour="#1db52c") + 
#     geom_smooth(data=SlopeTP4,aes(x,smooth),fill="#ff7b00", colour="#ff7b00", size=2) + 
#     geom_point(data=TP4, aes(AgeAtScan,TotalGrayVol), colour="#ff7b00") +
     geom_smooth(data=GAMM4_smooths, aes(x,smooth),fill="#000000", colour="#000000", size=2.5)

### Save ScatterPlot Combining Both Models ###

ggsave(file="/dfs2/yassalab/rjirsara/NSF/Figures/F2_GreyMatterDev.pdf", device = "pdf", width = 4, height = 5.5)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
