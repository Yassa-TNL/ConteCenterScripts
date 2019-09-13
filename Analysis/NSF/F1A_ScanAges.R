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

temp1<-rTP1[-c(which(rTP1$sub %in% rTP4$sub)),]
Figure<-rbind(temp1,rTP2,rTP3,rTP4)

#############################################
##### Redefine Session To Be Consistent #####
#############################################

data<-Figure
fTP1<-GetTimepoint(1)
fTP2<-GetTimepoint(2)
fTP3<-GetTimepoint(3)

fTP1$Session<-1
fTP2$Session<-2
fTP3$Session<-3

Figure<-rbind(fTP1,fTP2,fTP3)
Figure <- Figure[order(Figure$AgeAtScan),] 

###################################################################
##### Prepare Final Dataset for Figure of Scan Age By Session #####
###################################################################


Figure$Gender<-as.factor(Figure$Gender)
Figure$Session<-as.factor(Figure$Session)
Figure$Subject <- 0
maxcol<-dim(Figure)[2]
maxsubs<-length(unique(Figure$sub))

for (x in 1:maxsubs){
  subid<-unique(Figure$sub)[x]
  Figure[which(Figure$sub==subid),maxcol]<-x
}

###########################################################################
##### Plot MRI Timepoints Sorted By Age At Scan and Grouped By Gender #####
###########################################################################

Grp_Gender<-ggplot(data=Figure,aes(x=AgeAtScan,y=Subject,group=Subject,color=Gender)) + geom_line(size=1.1) + geom_point(aes(size=0)) + scale_color_manual(values=c("#e62929", "#2d81f7")) + theme_classic()

Grp_Session<-ggplot(data=Figure,aes(x=AgeAtScan,y=Subject,group=Subject)) + geom_line(size=1.5) + geom_point(aes(color=Session),size=3.5) + scale_color_manual(values=c("#c40000", "#0037ff", "#1db52c")) + theme_classic()

### Save Figure and Dataset ###

dir.create("/dfs2/yassalab/rjirsara/NSF/Data/F1_sub-51_ses-3_scans-153")
write.csv(Figure,"/dfs2/yassalab/rjirsara/NSF/Data/F1_sub-51_ses-3_scans-153/n153_Figure-1_20190912.csv")
Sys.chmod("/dfs2/yassalab/rjirsara/NSF/Data/F1_sub-51_ses-3_scans-153/n153_Figure-1_20190912.csv", mode = "775")

dir.create("/dfs2/yassalab/rjirsara/NSF/Figures")
ggsave(file="/dfs2/yassalab/rjirsara/NSF/Figures/F1A_ScanAges.pdf", device = "pdf", width = 4, height = 5.5)
Sys.chmod("/dfs2/yassalab/rjirsara/NSF/Figures/F1A_ScanAges.pdf", mode = "775")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
