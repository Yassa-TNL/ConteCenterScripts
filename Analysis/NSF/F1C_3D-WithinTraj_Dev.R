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
suppressMessages(require(plot3D))

#######################################################
##### Prepare Data For ScatterPlots of Each Model #####
#######################################################

alltimepoints<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/F1_sub-51_ses-3_scans-153/n153_Figure-1_20190912.csv")
alltimepoints$X.1<-NULL
attach(alltimepoints)

slopes <- read.csv("/dfs2/yassalab/rjirsara/NSF/Data/F1_sub-51_ses-3_scans-153/n101_Slopes_20190912.csv")
slopes$X<-NULL
slopes$Variable<-1
slopes$Ses1<-slopes$Variable
slopes$Variable.1<-2
slopes$Ses2<-slopes$Variable.1
slopes$Variable.2<-3
slopes$Ses3<-slopes$Variable.2
slopes$Variable.3<-9
slopes$Ses9<-slopes$Variable.3

##########################################################
##### Adds Points From Each Timepoint to the 3D Plot #####
##########################################################

scatter3D(alltimepoints$AgeAtScan,alltimepoints$Session,alltimepoints$TotalGrayVol, 
           colvar= as.integer(alltimepoints$Session),
           col = c("#006eff","#00aaff","#00ddff"),
           xlim=c(6,16),
           ylim=c(1,3.5),
           zlim=c(400000,900000),
           pch =19,
           cex = 0.30,
           bty="b",
           theta=120,
           phi=30,
           ticktype="detailed",
           type="p")

##########################################################
##### Adds Slopes From Each Timepoint to the 3D plot #####
##########################################################

scatter3D(slopes$x,slopes$Ses1,slopes$TP1vol, 
           colvar= NULL,
           col = c("#006eff"),
           pch =19,
           cex = 1.35,
           add=TRUE,
           type="b")

scatter3D(slopes$x.1,slopes$Ses2,slopes$TP2vol, 
           colvar= NULL,
           col = c("#00aaff"),
           pch =19,
           cex = 1.35,
           add=TRUE,
           type="b")

scatter3D(slopes$x.2,slopes$Ses3,slopes$TP3vol, 
           colvar= NULL,
           col = c("#00ddff"),
           pch =19,
           cex = 1.35,
           add=TRUE,
           type="b")

######################################################
##### Caculate and Add Subject-level Trajecories #####
######################################################

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
  scatter3D(DATA$AGE,DATA$SES,DATA$VOL, 
           colvar= NULL,
           col = c("#654321"),
           pch =19,
           cex = 0.05,
           add=TRUE,
           type="b",
           data="DATA")
}

#######################
##### Save Figure #####
#######################

ggsave(file="/dfs2/yassalab/rjirsara/NSF/Figures/F1C_3D-WithinTraj_Dev.pdf", device = "pdf", width = 4, height = 5.5)
Sys.chmod("/dfs2/yassalab/rjirsara/NSF/Figures/F1C_3D-WithinTraj_Dev.pdf", mode = "775")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
