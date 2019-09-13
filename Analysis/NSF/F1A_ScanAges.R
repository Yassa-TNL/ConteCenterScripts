#!/usr/bin/env Rscript
###################################################################################################
##########################                   NSF-GRFP                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

library(mgcv)
library(ggplot2)
library(cowplot)
library(RColorBrewer)

######################################################################
##### Read in Data and Define Function to Organize Scan Sessions #####
######################################################################

data<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/COVA-n275_Age+Sex_20190829_RESP-n360_Aseg_volume_20190829/AllScans/n268_gamm4_sAgeAtScank4-Gender_random_1sub_Merged.csv")
data<-data[complete.cases(data$AgeAtScan),]
data<-data[order(data$AgeAtScan),]

GetTimepoint <- function(TPnum){
  SUBJECTS<-unique(data$sub)
  newdata=data.frame()
  for (x in SUBJECTS){	
	row<-which(data$sub==x)[TPnum]
	addrow<-data[row,]
	newdata<-rbind(newdata,addrow)
        newdata<-newdata[complete.cases(newdata$sub),]
  }
  return(newdata)
}

#############################################################################
##### Break Data Into Timepoints Select Those with AtLeast 3 Timepoints #####
#############################################################################

TP1<-GetTimepoint(1)
TP2<-GetTimepoint(2)
TP3<-GetTimepoint(3)
TP4<-GetTimepoint(4)

TP3_All<-data[which(data$sub %in% TP3$sub),]

#####################################################################
##### Break The Sessions For Subjects with AtLeast 3 Timepoints #####
#####################################################################

data<-TP3_All

rTP1<-GetTimepoint(1)
rTP2<-GetTimepoint(2)
rTP3<-GetTimepoint(3)
rTP4<-GetTimepoint(4)

####################################################
##### Remove Extra 15 Scans from 4th Timepoint #####
####################################################

ExcludeExtra4th<-rbind(rTP1,rTP2,rTP3)


Figure<-data[-c(which(rTP1$sub %in% rTP4$sub)),]


ses4persub<-which(TP3_All$sub %in% TP4$sub)
data<-TP3








ses4persubTP1<-which(TP3_All[ses4persub,"ses"]==0)
ses4persubTP2<-which(TP3_All[ses4persub,"ses"]==1)
ses4persubTP3<-which(TP3_All[ses4persub,"ses"]==2)
ses4persubTP4<-which(TP3_All[ses4persub,"ses"]==3)





Figure <- Figure[order(Figure$AgeAtScan),] 
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

ggplot(data=Figure,aes(x=AgeAtScan,y=Sub_Ordered_Age,group=Sub_Ordered_Age,color=Gender)) + geom_line(size=1.1) + geom_point(aes(size=0)) + scale_color_manual(values=c("#e62929", "#2d81f7")) + theme_classic()

### Save Figure and Dataset ###

#write.csv(Figure, "/dfs2/yassalab/rjirsara/NSF/Data/n275_Age+Sex_20190829.csv")

#ggsave(file="/dfs2/yassalab/rjirsara/NSF/Figures/F1_ScanAges.pdf", device = "pdf", width = 4, height = 5.5)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
