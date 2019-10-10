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
Master<-read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/Audit_Master_ConteMRI.csv")
Demo<-Master[,c("subid","Session","AgeAtScan","Gender")]
names(Demo)[1]<-"sub"
names(Demo)[2]<-"ses"

###############################
### Clean Both DTI Datasets ###
###############################

maxcol<-dim(Unicate)[2]
Unicate[,c(1:maxcol)] <- lapply(Unicate[,c(1:maxcol)], as.character)
Unicate<-Unicate[-c(1),]
Unicate[1,1]<- "sub"
Unicate[1,2]<- "Visit"
Unicate[1,3]<- "ses"
names(Unicate)<-Unicate[1,]
Unicate<-Unicate[-c(1),]
Unicate$Sex<-recode(Unicate$Sex,"c('Male')=1")
Unicate$Sex<-recode(Unicate$Sex,"c('Female')=0")
Unicate[,c(2:maxcol)] <- lapply(Unicate[,c(2:maxcol)], as.numeric)
Unicate$Visit<-NULL
Unicate$'MRI Date'<-NULL
Unicate$Sex<-as.factor(Unicate$Sex)
Unicate$sub<-gsub("=", "", as.character(Unicate$sub))
Unicate$sub<-sub("_.*", "", Unicate$sub)


maxcol<-dim(Subcort)[2]
Subcort[,c(1:maxcol)] <- lapply(Subcort[,c(1:maxcol)], as.character)
Subcort[1,1]<- "sub"
Subcort[1,2]<- "Visit"
Subcort[1,3]<- "ses"
names(Subcort)<-Subcort[1,]
Subcort<-Subcort[-c(1),]
Subcort$Sex<-recode(Subcort$Sex,"c('Male')=1")
Subcort$Sex<-recode(Subcort$Sex,"c('Female')=0")
Subcort[,c(2:maxcol)] <- lapply(Subcort[,c(2:maxcol)], as.numeric)
Subcort$'MRI Date'<-NULL
Subcort$Visit<-NULL
Subcort$Sex<-as.factor(Subcort$Sex)
Subcort$sub<-gsub("=", "", as.character(Subcort$sub))
Subcort$sub<-sub("_.*", "", Subcort$sub)

#############################################
### Find Which Rows Are Missing in Master ###
#############################################

Demo$Audit<-paste(Demo$sub,Demo$ses)
Unicate$Audit<-paste(Unicate$sub,Unicate$ses)
Subcort$Audit<-paste(Subcort$sub,Subcort$ses)

MissingUnicate<-which(!Unicate$Audit %in% Demo$Audit)
Unicate[MissingUnicate,c(1,2)]
Unicate[MissingSubcort[1],c(2)]<-"1"

MissingSubcort<-which(!Subcort$Audit %in% Demo$Audit)
Subcort[MissingSubcort,c(1,2)]
Subcort[MissingSubcort[1],c(2)]<-"1"

### 575_2_2 Needs Further Investgiation ###
### BIDS Exists for T1w, but not DTI ###
### Needs Relabeling of Dicoms ###

######################################
### Add Demographic Data To Master ###
######################################

UNICATE<-Unicate[,c("sub","ses","Ages","Sex")]
DEMO<-merge(Demo,UNICATE, by=c("sub","ses"), all=TRUE)
MissingAge<-which(is.na(DEMO$AgeAtScan))
MissingIndex<-length(MissingAge)
DEMO$Gender<-as.character(DEMO$Gender)
DEMO$Sex<-as.character(DEMO$Sex)

for (x in 1:MissingIndex){
  row<-MissingAge[x]
  AGE<-DEMO[row,"Ages"]
  SEX<-DEMO[row,"Sex"]
  DEMO[row,"AgeAtScan"] <- AGE
  DEMO[row,"Gender"] <- SEX
}

DEMO$Gender<-as.factor(DEMO$Gender)
DEMO$Sex<-as.factor(DEMO$Sex)
DEMO<-DEMO[,c("sub","ses","AgeAtScan","Gender")]


SUBCORT<-Subcort[,c("sub","ses","Age","Sex")]
DEMO<-merge(DEMO,SUBCORT, by=c("sub","ses"), all=TRUE)
MissingAge<-which(is.na(DEMO$AgeAtScan))
MissingIndex<-length(MissingAge)
DEMO$Gender<-as.character(DEMO$Gender)
DEMO$Sex<-as.character(DEMO$Sex)

for (x in 1:MissingIndex){
  row<-MissingAge[x]
  AGE<-DEMO[row,"Age"]
  SEX<-DEMO[row,"Sex"]
  DEMO[row,"AgeAtScan"] <- AGE
  DEMO[row,"Gender"] <- SEX
}

DEMO$Gender<-as.factor(DEMO$Gender)
DEMO$Sex<-as.factor(DEMO$Sex)
DEMO<-DEMO[,c("sub","ses","AgeAtScan","Gender")]

####################################
### Save Master Demographic Data ###
####################################

write.csv(DEMO, "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/Demo/n424_Age+Sex_20191008.csv")

#########################################
### Prepare the DTI Data For Analysis ###
#########################################

VolCol<-which((names(Unicate) == "Volume mm^3") == TRUE)
Unicate$VOLUME<-Unicate[,VolCol[1]]+Unicate[,VolCol[2]]
maxcol<-dim(Unicate)[2]
Unicate<-Unicate[,c(1:2,maxcol)]

Subcort$GFA_HIPPOCAMPUS<-Subcort$"GFA_Cingulum_(hippocampus)_L"+Subcort$"GFA_Cingulum_(hippocampus)_R"
Subcort$GFA_FASCICULUS<-Subcort$"GFA_Uncinate_fasciculus_L"+Subcort$"GFA_Uncinate_fasciculus_R"
maxcol<-dim(Subcort)[2]
Subcort<-Subcort[,c(1:2,maxcol-1,maxcol)]
DTI<-merge(Subcort,Unicate, by=c("sub","ses"), all=TRUE)

################################
### Simplify and Save Output ###
################################

write.csv(DTI, "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/DTI/n240_GFA+Vol_20191005.csv")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
