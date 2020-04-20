#!/usr/bin/env Rscript
######################

DATA<-read.csv('/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/Demo/n424_Age+Sex_20191008.csv')
SOURCE1<-read.csv('/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/rawdata/Master_CC_MRI_Database.csv',header=TRUE, na.strings=c("-88"))
SOURCE2<-read.csv('/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/rawdata/Master_CC_Visit_Database.csv',header=TRUE, na.strings=c("-88"))
SOURCE3<-read.csv('/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/rawdata/Master_CC_MRI_Demographics_Database.csv',header=TRUE, na.strings=c("-88"))

####################################
##### Fill in Missing Sex Data #####
#####   Females: 0 Males: 1    #####
####################################

DATA$Gender<-as.integer(as.character(DATA$Gender))
SOURCE2[which(SOURCE3$Sex == 2 ),"Sex"]<-0

for (row in which(!complete.cases(DATA$Gender))){
	
	SUBID<-DATA[row,"sub"]
	SEX_VALUE<-as.integer(as.character(SOURCE2[which(SUBID == SOURCE2$nsub),"Sex"]))
	if (length(SEX_VALUE) == 1){
		DATA$Gender[row]<-SEX_VALUE
	}
}

DATA$Gender<-as.factor(DATA$Gender)

####################################
##### Fill in Missing Age Data #####
####################################

SOURCE_AGE_LABELS<-names(SOURCE1)[grep("age",names(SOURCE1))]

for (row in which(!complete.cases(DATA$AgeAtScan))){
	SUBID<-DATA[row,"sub"]
	INTERESTVAR<-SOURCE_AGE_LABELS[grep(DATA[row,"ses"], SOURCE_AGE_LABELS)]
	INTERESTAGE<-SOURCE1[which(SUBID == SOURCE1$nsub),INTERESTVAR]
	if (length(INTERESTAGE) == 1){
		DATA[row,"AgeAtScan"]<-as.numeric(INTERESTAGE)
	}
}

DATA$AgeAtScan<-as.numeric(DATA$AgeAtScan)

####################
### Save Dataset ###
####################

write.csv(DATA,'/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/Demo/n424_Age+Sex_20191008.csv')
Sys.chmod('/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/Demo/n424_Age+Sex_20191008.csv', mode = "0770", use_umask = TRUE)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
