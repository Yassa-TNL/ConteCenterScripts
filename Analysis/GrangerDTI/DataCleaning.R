#!/usr/bin/env Rscript
###################################################################################################
##########################                  GrangerDTI                   ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

library(car)

##################################
### Load Datasets for Analyses ###
##################################

Unicate<-read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/RawData/GrangerDTI_Uncinate.csv", header=FALSE)
Subcort<-read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/RawData/GrangerDTI_SubCort.csv", header=FALSE)
Demo<-read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/Demo/n275_Age+Sex_20190829.csv")

#############################
### Clean Unicate Dataset ###
#############################

maxcol<-dim(Unicate)[2]
Unicate[,c(1:maxcol)] <- lapply(Unicate[,c(1:maxcol)], as.character)
Unicate<-Unicate[-c(1),]
Unicate[1,1]<- "sub"
Unicate[1,2]<- "Visit"
Unicate[1,3]<- "ses"
names(Unicate)<-Unicate[1,]
Unicate<-Unicate[-c(1),]
Unicate$Sex<-recode(Unicate$Sex,"c('Male')=1")
Unicate$Sex<-recode(Unicate$Sex,"c('Female')=2")
Unicate[,c(2:maxcol)] <- lapply(Unicate[,c(2:maxcol)], as.numeric)
Unicate$'MRI Date'<-NULL
Unicate$Sex<-as.factor(Unicate$Sex)
Unicate$sub<-gsub("=", "", as.character(Unicate$sub))
Unicate$sub<-sub("_.*", "", Unicate$sub)
Subcort$Visit<-NULL

#############################
### Clean Subcort Dataset ###
#############################

maxcol<-dim(Subcort)[2]
Subcort[,c(1:maxcol)] <- lapply(Subcort[,c(1:maxcol)], as.character)
Subcort[1,1]<- "sub"
Subcort[1,2]<- "Visit"
Subcort[1,3]<- "ses"
names(Subcort)<-Subcort[1,]
Subcort<-Subcort[-c(1),]
Subcort$Sex<-recode(Subcort$Sex,"c('Male')=1")
Subcort$Sex<-recode(Subcort$Sex,"c('Female')=2")
Subcort[,c(2:maxcol)] <- lapply(Subcort[,c(2:maxcol)], as.numeric)
Subcort$'MRI Date'<-NULL
Subcort$Sex<-as.factor(Subcort$Sex)
Subcort$sub<-gsub("=", "", as.character(Subcort$sub))
Subcort$sub<-sub("_.*", "", Subcort$sub)
Subcort$Visit<-NULL

#################################
### Merge and Simply Datasets ###
#################################

VolCol<-which((names(Unicate) == "Volume mm^3") == TRUE)
Unicate$VOLUME<-Unicate[,VolCol[1]]+Unicate[,VolCol[2]]
Unicate<-Unicate[,-c(4:19)]

Subcort$GFA_HIPPOCAMPUS<-Subcort[,28]+Subcort[,29]
Subcort$GFA_FASCICULUS<-Subcort[,32]+Subcort[,33]
Subcort<-Subcort[,-c(8:33)]

Final<-merge(Subcort,Unicate, by=c("sub","ses"), all=TRUE)
Final<-merge(Final,Demo, by=c("sub","ses"), all=TRUE)
Final<-Final[complete.cases(Final$GFA_FASCICULUS),]

MissingAge<-which(is.na(Final$Age) ==TRUE)

MaxIndex=length(MissingAgeAtScan)

for (x in 1:MaxIndex){
  row<-MissingAgeAtScan[x]
  val<-Final[row,"Age"]
  print(val)
}

###################################
### Check QQ-Plot For Normality ###
###################################

attach(Final)
plot(lm(GFA_HIPPOCAMPUS~AgeAtScan))
plot(lm(GFA_FASCICULUS~AgeAtScan)) 
plot(lm(VOLUME~AgeAtScan)) 

################################
### Simplify and Save Output ###
################################

FINAL<-Final[,c(1:2,8:10)]
write.csv(FINAL, "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/DTI/n170_Aseg_volume_20190910.csv")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
