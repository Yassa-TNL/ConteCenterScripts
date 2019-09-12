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

alltimepoints$Gender<-as.factor(alltimepoints$Gender)
attach(alltimepoints)

BrainRegions <- names(alltimepoints)[6:67]

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
GAMM4_predicts <- data.frame(Variable = "dim1",
                       x=GAMM4_plotdata$res$AgeAtScan,
                       y=GAMM4_plotdata$res$visregRes)

##############################################################
##### Calculate Cross-Sectional Model on All Scans (GAM) #####
##############################################################

GAM_Models <- lapply(BrainRegions, function(x) {
  gam(substitute(i ~ s(AgeAtScan,k=4) + Gender, list(i = as.name(x))), method="REML", data=alltimepoints)
})

GAM_Results <- lapply(GAM_Models, summary)

GAM_plotdata <- visreg(GAM_Models[[52]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
GAM_smooths <- data.frame(Variable = GAM_plotdata$meta$x,
                      x=GAM_plotdata$fit[[GAM_plotdata$meta$x]],
                      smooth=GAM_plotdata$fit$visregFit,
                      lower=GAM_plotdata$fit$visregLwr,
                      upper=GAM_plotdata$fit$visregUpr)
GAM_predicts <- data.frame(Variable = "dim1",
                       x=GAM_plotdata$res$AgeAtScan,
                       y=GAM_plotdata$res$visregRes)

##################################################
### Overlap the Two Models on the Same Scatter ###
##################################################

FINAL<-ggplot() + 
     geom_point(data=GAM_predicts, aes(x,y), colour="#179c00") + 
     geom_smooth(data=GAM_smooths,aes(x,smooth),fill="#179c00", colour="#179c00", size=2) + 
     geom_point(data=GAMM4_predicts, aes(x,y), colour="#0055ff") + 
     geom_smooth(data=GAMM4_smooths, aes(x,smooth),fill="#0055ff", colour="#0055ff", size=2)

### Save ScatterPlot Combining Both Models ###

ggsave(file="/dfs2/yassalab/rjirsara/NSF/Figures/F2_GreyMatterDev.pdf", device = "pdf", width = 4, height = 5.5)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
