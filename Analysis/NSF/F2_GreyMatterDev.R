#!/usr/bin/env Rscript
###################################################################################################
##########################                   NSF-GRFP                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ####
###################################################################################################

library(mgcv)
library(ggplot2)
library(cowplot)
library(RColorBrewer)
library(visreg)
library(stringr)
suppressMessages(require(ggplot2))
suppressMessages(require(base))
suppressMessages(require(reshape2))
suppressMessages(require(nlme))
suppressMessages(require(lme4))
suppressMessages(require(gamm4))
suppressMessages(require(stats))
suppressMessages(require(knitr))
suppressMessages(require(mgcv))
suppressMessages(require(plyr))
suppressMessages(require(oro.nifti))
suppressMessages(require(parallel))
suppressMessages(require(optparse))
suppressMessages(require(fslr))
suppressMessages(require(voxel))
suppressMessages(require(stringr))

####################################################################
##### Prepare the GAM Model from Baseline Cross-sectional Data #####
####################################################################

baseline<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/COVA-n275_Age+Sex_20190829_RESP-n360_Aseg_volume_20190829/BaselineScans/n100_gam_sAgeAtScank4-Gender_Merged.csv")
baseline$Gender<-as.factor(baseline$Gender)

BrainRegions1 <- names(baseline)[6:67]


Models1 <- lapply(BrainRegions1, function(x) {
  gam(substitute(i ~ s(AgeAtScan, k=4) + Gender, list(i = as.name(x))), method="REML", data = baseline)
})

Results1 <- lapply(Models1, summary)

plotdata1 <- visreg(Models1[[52]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
smooths1 <- data.frame(Variable = plotdata1$meta$x,
                      x=plotdata1$fit[[plotdata1$meta$x]],
                      smooth1=plotdata1$fit$visregFit,
                      lower1=plotdata1$fit$visregLwr,
                      upper1=plotdata1$fit$visregUpr)
predicts1 <- data.frame(Variable = "dim1",
                       x=plotdata1$res$AgeAtScan,
                       y=plotdata1$res$visregRes)

colkey <- "#2e82ff"
lineColor<- "#2e82ff"
p_text <- "p[fdr] == 0.04"

cross<-ggplot() +
  geom_point(data = predicts1, aes(x, y, colour = x), alpha= 1  ) +
  scale_colour_gradientn(colours = colkey,  name = "") +
  geom_line(data = smooths1, aes(x = x, y = smooth1), colour = lineColor,size=2) +
  geom_line(data = smooths1, aes(x = x, y=lower1), linetype="dashed", colour = lineColor, alpha = 0.9, size = 1.5) +
  geom_line(data = smooths1, aes(x = x, y=upper1), linetype="dashed",colour = lineColor, alpha = 0.9, size = 1.5) +
  theme(legend.position = "none") +
  labs(x = "", y = "") +
  theme(axis.title=element_text(size=26,face="bold"), axis.text=element_text(size=14), axis.title.x=element_text(color = "black"), axis.title.y=element_text(color = "black"))

##############################################################
##### Prepare the GAMM4 Model from All Longitudinal Data #####
##############################################################

alltimepoints<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/COVA-n275_Age+Sex_20190829_RESP-n360_Aseg_volume_20190829/AllScans/n268_gamm4_sAgeAtScank4-Gender_random_1sub_Merged.csv")
alltimepoints$Gender<-as.factor(alltimepoints$Gender)

BrainRegions <- names(alltimepoints)[6:67]

Models <- lapply(BrainRegions, function(x) {
  gamm4(substitute(i ~ s(AgeAtScan,k=4) + Gender, list(i = as.name(x))), random=as.formula(~(1|sub)), data=alltimepoints, REML=T)$gam
})

Results <- lapply(Models, summary)
attach(alltimepoints)

plotdata <- visreg(Models[[52]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
smooths <- data.frame(Variable = plotdata$meta$x,
                      x=plotdata$fit[[plotdata$meta$x]],
                      smooth=plotdata$fit$visregFit,
                      lower=plotdata$fit$visregLwr,
                      upper=plotdata$fit$visregUpr)
predicts <- data.frame(Variable = "dim1",
                       x=plotdata$res$AgeAtScan,
                       y=plotdata$res$visregRes)

colkey <- "#2e82ff"
lineColor<- "#2e82ff"
p_text <- "p[fdr] == 0.04"

long<-ggplot() +
  geom_point(data = predicts, aes(x, y, colour = x), alpha= 1  ) +
  scale_colour_gradientn(colours = colkey,  name = "") +
  geom_line(data = smooths, aes(x = x, y = smooth), colour = lineColor,size=2) +
  geom_line(data = smooths, aes(x = x, y=lower), linetype="dashed", colour = lineColor, alpha = 0.9, size = 1.5) +
  geom_line(data = smooths, aes(x = x, y=upper), linetype="dashed",colour = lineColor, alpha = 0.9, size = 1.5) +
  theme(legend.position = "none") +
  labs(x = "", y = "") +
  theme(axis.title=element_text(size=26,face="bold"), axis.text=element_text(size=14), axis.title.x=element_text(color = "black"), axis.title.y=element_text(color = "black"))
detach(alltimepoints)

##################################################
### Overlap the Two Models on the Same Scatter ###
##################################################

FINAL<-ggplot() + 
     geom_point(data=predicts, aes(x,y), colour="#179c00") + 
     geom_smooth(data=smooths,aes(x,smooth),fill="#179c00", colour="#179c00", size=2) + 
     geom_point(data=predicts1, aes(x,y), colour="#0055ff") + 
     geom_smooth(data=smooths1, aes(x,smooth1),method="gam",fill="#0055ff", colour="#0055ff", size=2)

### Save ScatterPlot Combining Both Models ###

ggsave(file="/dfs2/yassalab/rjirsara/NSF/Figures/F2_GreyMatterDev.pdf", device = "pdf", width = 4, height = 5.5)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
