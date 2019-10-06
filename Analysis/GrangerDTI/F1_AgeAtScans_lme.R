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

#######################################################
##### Prepare Data For ScatterPlots of Each Model #####
#######################################################

alltimepoints<-read.csv("/dfs2/yassalab/rjirsara/GrangerDTI/Data/COVA-n426_Age+Sex_20191005_RESP-n242_GFA+Vol_20191005/Preliminary/n210_gamm4_AgeAtScan_random_1sub_Merged.csv")
alltimepoints$Gender<-as.factor(alltimepoints$Gender)
BrainRegions <- names(alltimepoints)[6:8]
TP1<-alltimepoints[which(alltimepoints$Session==1),]
TP2<-alltimepoints[which(alltimepoints$Session==2),]
TP3<-alltimepoints[which(alltimepoints$Session==3),]
attach(alltimepoints)

#####################################################
##### Calculate Longitudinal Model on All Scans #####
#####################################################

GAMM4_Models <- lapply(BrainRegions, function(x) {
	gamm4(substitute(i ~ AgeAtScan, list(i = as.name(x))), random=as.formula(~(1|sub)), data=alltimepoints, REML=T)$gam
})

GAMM4_Results <- lapply(GAMM4_Models, summary)
attach(alltimepoints)

GAMM4_plotdata1 <- visreg(GAMM4_Models[[1]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
GAMM4_smooths1 <- data.frame(Variable = GAMM4_plotdata1$meta$x,
                      x=GAMM4_plotdata1$fit[[GAMM4_plotdata1$meta$x]],
                      smooth=GAMM4_plotdata1$fit$visregFit,
                      lower=GAMM4_plotdata1$fit$visregLwr,
                      upper=GAMM4_plotdata1$fit$visregUpr)

GAMM4_plotdata2 <- visreg(GAMM4_Models[[2]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
GAMM4_smooths2 <- data.frame(Variable = GAMM4_plotdata2$meta$x,
                      x=GAMM4_plotdata2$fit[[GAMM4_plotdata2$meta$x]],
                      smooth=GAMM4_plotdata2$fit$visregFit,
                      lower=GAMM4_plotdata2$fit$visregLwr,
                      upper=GAMM4_plotdata2$fit$visregUpr)


GAMM4_plotdata3 <- visreg(GAMM4_Models[[3]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
GAMM4_smooths3 <- data.frame(Variable = GAMM4_plotdata3$meta$x,
                      x=GAMM4_plotdata3$fit[[GAMM4_plotdata3$meta$x]],
                      smooth=GAMM4_plotdata3$fit$visregFit,
                      lower=GAMM4_plotdata3$fit$visregLwr,
                      upper=GAMM4_plotdata3$fit$visregUpr)

#######################################################
### Overlap the Four Models on the Same Scatterplot ###
#######################################################

FINAL<-ggplot() + 
    # geom_smooth(data=GAMM4_smooths1,aes(x,smooth),fill="#006eff", colour="#006eff", size=2.25) + 
   #  geom_point(data=alltimepoints, aes(AgeAtScan,GFA_HIPPOCAMPUS), colour="#006eff", size=2) + 
  #   geom_smooth(data=GAMM4_smooths2,aes(x,smooth),fill="#00aaff", colour="#00aaff", size=2.25) + 
 #    geom_point(data=alltimepoints, aes(AgeAtScan,GFA_FASCICULUS), colour="#00aaff", size=2) + 
     geom_smooth(data=GAMM4_smooths3,aes(x,smooth),fill="#c40802", colour="#c40802", size=2.25)  +
     geom_point(data=alltimepoints, aes(AgeAtScan,VOLUME), colour="#c40802", size=2) 

###############################
### Save Figure and Dataset ###
###############################

ggsave(file="/dfs2/yassalab/rjirsara/GrangerDTI/Figures/F1_Between-Subs_Vol.pdf", device = "pdf", width = 4, height = 5)
Sys.chmod("/dfs2/yassalab/rjirsara/GrangerDTI/Figures/F1_Between-Subs_Vol.pdf", mode = "775")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
