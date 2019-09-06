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

#######################################################################
##### Prepare the Data to Create Figure of Sample Characteristics #####
#######################################################################

data<-read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/Demo/n275_Age+Sex_20190829.csv")

Figure <- data[order(data$AgeAtScan),] 
Figure$Gender<-as.factor(Figure$Gender)
Figure$Sub_Ordered_Age <- 0
maxcol<-dim(Figure)[2]
maxsubs<-length(unique(Figure$sub))

for (x in 1:maxsubs){
  subid<-unique(Figure$sub)[x]
  Figure[which(Figure$sub==subid),maxcol]<-x
}

###########################################################################
##### Plot MRI Timepoints Sorted By Age At Scan and Grouped By Gender #####
###########################################################################

ggplot(data=Figure,aes(x=AgeAtScan,y=Sub_Ordered_Age,group=Sub_Ordered_Age,color=Gender)) + \
  geom_line(size=1.1) + \
  geom_point(aes(size=0)) +\
  scale_color_manual(values=c("#e62929", "#2d81f7")) + \
  theme_classic()

### Save Figure and Dataset ###

write.csv(Figure, "/dfs2/yassalab/rjirsara/NSF/Data/n275_Age+Sex_20190829.csv")

ggsave(file="/dfs2/yassalab/rjirsara/NSF/Figures/F1_ScanAges.pdf", device = "pdf", width = 4, height = 5.5)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ####
###################################################################################################



