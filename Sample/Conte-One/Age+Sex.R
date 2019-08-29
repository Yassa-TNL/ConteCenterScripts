#!/usr/bin/env Rscript
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

library(mgcv)
library(ggplot2)
library(cowplot)
library(RColorBrewer)

###################################################################
##### Break Sessions into Datasets To Be Combined & Processed #####
###################################################################

data<-read.csv('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/RawData/Age+Sex.csv')
data<-data[complete.cases(data$SUBJID),]
ses0<-data[,c(1,2,3)]
ses0$ses<-0
names(ses0)[3]<-"AgeAtScan"

ses1<-data[,c(1,2,4)]
ses1$ses<-1
names(ses1)[3]<-"AgeAtScan"

ses2<-data[,c(1,2,5)]
ses2$ses<-2
names(ses2)[3]<-"AgeAtScan"

ses3<-data[,c(1,2,6)]
ses3$ses<-3
names(ses3)[3]<-"AgeAtScan"

data<-rbind(ses0,ses1)
data<-rbind(data,ses2)
data<-rbind(data,ses3)

data<-data[,c(1,4,3,2)]
names(data)[1]<-"sub"
names(data)[4]<-"Gender"

data$Gender<-as.numeric(data$Gender)
data[which(data$Gender=='2'),4]<-'0'
data[which(data$Gender=='3'),4]<-'1'
data$Gender<-as.factor(data$Gender) #Females: 0 Males: 1
data$AgeAtScan<-as.numeric(data$AgeAtScan)

####################
### Save Dataset ###
####################

TotalRows<-dim(data)[1]
MissingAge<-summary(data$AgeAtScan)[7]
SamplewithAge=TotalRows-MissingAge

write.csv(data,'/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/Demo/n275_Age+Sex_20190829.csv')

#######################################################################
##### Prepare the Data to Create Figure of Sample Characteristics #####
#######################################################################

Figure <- data[order(data$AgeAtScan),] 
Figure$Sub_Ordered_Age <- 0
maxcol<-dim(Figure)[2]
maxsubs<-length(unique(Figure$sub))

Figure=[]
for (x in 1:maxsubs){
  subid<-unique(Figure$sub)[x]
  Figure[which(Figure$sub==subid),maxcol]<-x
}

###########################################################################
##### Plot MRI Timepoints Sorted By Age At Scan and Grouped By Gender #####
###########################################################################

ggplot(data=Figure,aes(x=AgeAtScan,y=Sub_Ordered_Age,group=Sub_Ordered_Age,color=Gender)) + geom_point()+geom_line()

#colkey <- "#2ebeff"
#lineColor<- "#2ebeff"
#p_text <- "p[fdr] == 0.008"
#Figure<-ggplot() +
#  geom_point(data = Sample, aes(x, y, colour = x), alpha= 1  ) +
#  scale_colour_gradientn(colours = colkey,  name = "") +
#  geom_line(data = Sample, aes(x = x, y = smooth), colour = lineColor,size=2) +
#  annotate("text",x = -Inf, y = Inf, hjust = -0.1,vjust = 1,label = p_text, parse=TRUE,size = 8, colour = "black",fontface ="italic" ) +
#  theme(legend.position = "none") +
#  labs(x = "", y = "") +
#  theme(axis.title=element_text(size=26,face="bold"), axis.text=element_text(size=14), axis.title.x=element_text(color = "black"), #axis.title.y=element_text(color = "black"))
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
