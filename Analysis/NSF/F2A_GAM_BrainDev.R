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
############################################
#### Gather ARI RESULTS To be Published ####
############################################

#Pull p-values# ENSURE IT IS THE CORRECT COVARIATE
p_ari <- sapply(NmfModels, function(v) summary(v)$p.table[5,4])
#Convert to data frame
p_ari <- as.data.frame(p_ari)
#Print original p-values to three decimal places
p_ari_round <- round(p_ari,3)
#FDR correct p-values
p_ari_fdr <- p.adjust(p_ari[,1],method="fdr")
#Convert to data frame
p_ari_fdr <- as.data.frame(p_ari_fdr)
#To print fdr-corrected p-values to three decimal places
p_ari_fdr_round <- round(p_ari_fdr,3)
#List the NMF components that survive FDR correction
Nmf_ARI_fdr <- row.names(p_ari_fdr)[p_ari_fdr<0.05]
#Name of the NMF components that survive FDR correction
Nmf_ARI_fdr_names <- nmfComponents[as.numeric(Nmf_ARI_fdr)]
#To check direction of coefficient estimates
ARI_coeff <- models[as.numeric(Nmf_ARI_fdr)]



#######################################################################
##### Prepare the Data to Create Figure of Sample Characteristics #####
#######################################################################

baseline<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/COVA-n275_Age+Sex_20190829_RESP-n360_Aseg_volume_20190829/BaselineScans/n100_gam_sAgeAtScank4-Gender_Merged.csv")

BrainRegions <- names(baseline)[6:67]

Models <- lapply(BrainRegions, function(x) {
  gam(substitute(i ~ s(AgeAtScan, k=4) + Gender, list(i = as.name(x))), method="REML", data = baseline)
})

Results <- lapply(Models, summary)

maxindex<-length(Models)

for (x in 1:maxindex){
  plotname<-paste("plot",x)
  plotname<-visreg(Models[[x]],'AgeAtScan')
}



################################################
### PLOT ARI as a Predictor of CT Network 18 ### 
################################################

plotdata <- visreg(Models[[18]],'AgeAtScan',type = "conditional",scale = "linear", plot = FALSE)
smooths <- data.frame(Variable = plotdata$meta$x,
                      x=plotdata$fit[[plotdata$meta$x]],
                      smooth=plotdata$fit$visregFit,
                      lower=plotdata$fit$visregLwr,
                      upper=plotdata$fit$visregUpr)
predicts <- data.frame(Variable = "dim1",
                       x=plotdata$res$ari_log,
                       y=plotdata$res$visregRes)

colkey <- "#2e82ff"
lineColor<- "#2e82ff"
p_text <- "p[fdr] == 0.04"

Limbic<-ggplot() +
  geom_point(data = predicts, aes(x, y, colour = x), alpha= 1  ) +
  scale_colour_gradientn(colours = colkey,  name = "") +
  geom_line(data = smooths, aes(x = x, y = smooth), colour = lineColor,size=2) +
  geom_line(data = smooths, aes(x = x, y=lower), linetype="dashed", colour = lineColor, alpha = 0.9, size = 1.5) +
  geom_line(data = smooths, aes(x = x, y=upper), linetype="dashed",colour = lineColor, alpha = 0.9, size = 1.5) +
  annotate("text",x = -Inf, y = Inf, hjust = -0.1,vjust = 1,label = p_text, parse=TRUE,size = 8, colour = "black",fontface ="italic" ) +
  theme(legend.position = "none") +
  labs(x = "", y = "") +
  theme(axis.title=element_text(size=26,face="bold"), axis.text=element_text(size=14), axis.title.x=element_text(color = "black"), axis.title.y=element_text(color = "black"))
  
### Save Scatterplot ###

ggsave(file="/data/jux/BBL/projects/jirsaraieStructuralIrrit/output/NMF_Figures/F4_Rate/ScatterPlot_ctRATE_Network18.pdf", device = "pdf", width = 4, height = 5.5)

###############################################
### PLOT ARI as a Predictor of CT Network 1 ### 
###############################################

plotdata <- visreg(NmfModels[[9]],'ari_log',type = "conditional",scale = "linear", plot = FALSE)
smooths <- data.frame(Variable = plotdata$meta$x,
                      x=plotdata$fit[[plotdata$meta$x]],
                      smooth=plotdata$fit$visregFit,
                      lower=plotdata$fit$visregLwr,
                      upper=plotdata$fit$visregUpr)

predicts <- data.frame(Variable = "dim1",
                       x=plotdata$res$ari_log,
                       y=plotdata$res$visregRes)

colkey <- "#2ebeff"
lineColor<- "#2ebeff"
p_text <- "p[fdr] == 0.008"

Limbic<-ggplot() +
  geom_point(data = predicts, aes(x, y, colour = x), alpha= 1  ) +
  scale_colour_gradientn(colours = colkey,  name = "") +
  geom_line(data = smooths, aes(x = x, y = smooth), colour = lineColor,size=2) +
  geom_line(data = smooths, aes(x = x, y=lower), linetype="dashed", colour = lineColor, alpha = 0.9, size = 1.5) +
  geom_line(data = smooths, aes(x = x, y=upper), linetype="dashed",colour = lineColor, alpha = 0.9, size = 1.5) +
  annotate("text",x = -Inf, y = Inf, hjust = -0.1,vjust = 1,label = p_text, parse=TRUE,size = 8, colour = "black",fontface ="italic" ) +
  theme(legend.position = "none") +
  labs(x = "", y = "") +
  theme(axis.title=element_text(size=26,face="bold"), axis.text=element_text(size=14), axis.title.x=element_text(color = "black"), axis.title.y=element_text(color = "black"))

### Save Scatterplot ###

ggsave(file="/data/jux/BBL/projects/jirsaraieStructuralIrrit/output/NMF_Figures/F4_Rate/ScatterPlot_ctRATE_Network9.pdf", device = "pdf", width = 4, height = 5.5)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
