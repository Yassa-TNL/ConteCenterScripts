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
suppressMessages(require(scatterplot3d))

#######################################################
##### Prepare Data For ScatterPlots of Each Model #####
#######################################################

alltimepoints<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/F1_sub-51_ses-3_scans-153/n153_Figure-1_20190912.csv")
alltimepoints$X.1<-NULL
alltimepoints$Gender<-as.factor(alltimepoints$Gender)
BrainRegions <- names(alltimepoints)[6:67]
TP1<-alltimepoints[which(alltimepoints$Session==1),]
TP2<-alltimepoints[which(alltimepoints$Session==2),]
TP3<-alltimepoints[which(alltimepoints$Session==3),]
attach(alltimepoints)

#############################################################
##### Calculate Longitudinal Model on All Scans (GAMM4) #####
#############################################################

GAMM4_Models <- lapply(BrainRegions, function(x) {
	gamm4(substitute(i ~ s(AgeAtScan,k=4) + Gender, list(i = as.name(x))), random=as.formula(~(1|sub)), data=alltimepoints, REML=T)$gam
})

GAMM4_Results <- lapply(GAMM4_Models, summary)
attach(alltimepoints)
GAMM4_plotdata <- visreg(GAMM4_Models[[52]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
GAMM4_smooths <- data.frame(Variable = GAMM4_plotdata$meta$x,
                      x=GAMM4_plotdata$fit[[GAMM4_plotdata$meta$x]],
                      smooth=GAMM4_plotdata$fit$visregFit,
                      lower=GAMM4_plotdata$fit$visregLwr,
                      upper=GAMM4_plotdata$fit$visregUpr)

####################################################################
##### Calculate Cross-Sectional Models at Each Timepoint (GAM) #####
####################################################################

AnalyzeSlope <- function(Timepoint){
  attach(Timepoint)
  GAM_Models <- lapply(BrainRegions, function(x) {
	gam(substitute(i ~ s(AgeAtScan,k=4) + Gender, list(i = as.name(x))), method="REML", data=Timepoint)
  })
  GAM_Results <- lapply(GAM_Models, summary)
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

#######################################################
### Overlap the Four Models on the Same Scatterplot ###
#######################################################

FINAL<-ggplot() + 
     geom_smooth(data=SlopeTP1,aes(x,smooth),fill="#006eff", colour="#006eff", size=2.25) + 
     geom_point(data=TP1, aes(AgeAtScan,TotalGrayVol), colour="#006eff", size=2) + 
     geom_smooth(data=SlopeTP2,aes(x,smooth),fill="#00aaff", colour="#00aaff", size=2.25) + 
     geom_point(data=TP2, aes(AgeAtScan,TotalGrayVol), colour="#00aaff", size=2) + 
     geom_smooth(data=SlopeTP3,aes(x,smooth),fill="#00ddff", colour="#00ddff", size=2.25) + 
     geom_point(data=TP3, aes(AgeAtScan,TotalGrayVol), colour="#00ddff", size=2) + 
     geom_smooth(data=GAMM4_smooths, aes(x,smooth),fill="#654321", colour="#654321", size=2.75)

### Save Figure ###

dir.create("/dfs2/yassalab/rjirsara/NSF/Figures")
ggsave(file="/dfs2/yassalab/rjirsara/NSF/Figures/F1B_Between-Subs_Dev.pdf", device = "pdf", width = 4, height = 5)
Sys.chmod("/dfs2/yassalab/rjirsara/NSF/Figures/F1B_Between-Subs_Dev.pdf", mode = "775")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
