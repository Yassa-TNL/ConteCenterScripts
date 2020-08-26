#!/usr/bin/env Rscript
######################

print("Load Libraries and Output Files From Each Model Across All Stages")
RESULTS<-list.files("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux/n138_IntraFlux.mods",recursive=T,full.names=T)
S1<-RESULTS[grepl("COVA-EVCont_RESP-EmoGNG",RESULTS)]
S2_REST1<-RESULTS[grepl("COVA-NetStr_RESP-REST1",RESULTS)]
S2_AMG<-RESULTS[grepl("COVA-NetStr_RESP-EmoGNG",RESULTS)]
S2_REST2<-RESULTS[grepl("COVA-NetStr_RESP-REST2",RESULTS)]
S3<-RESULTS[grepl("COVA-NetStr_RESP-LONG",RESULTS)]
library(lattice)

###############################################################################
### Create First Matix Based on Main Effects of Entropy and Composite Level ###
###############################################################################

print("Creating First Matrix of Main Effects")
MAINS<-c(S1[c(5,1,4)],S2_REST1[c(5,1,4)],S2_AMG[c(5,1,4)],S2_REST2[c(5,1,4)],S3[c(2,1,5)])
MAT_MAIN<-matrix(NA, nrow = 15, ncol = 12)

INDEX=0
for (FILE in MAINS){
	INDEX=INDEX+1
	CONTENT<-read.csv(FILE)
	if (CONTENT[1,1] == "gica_network_1_zstat"){
		CONTENT<-CONTENT[c(1,5:12,2:4),]
	}
	CONTENT<-CONTENT[,grepl("tval.",names(CONTENT))]
	MAT_MAIN[INDEX,1:12]<-t(CONTENT[grepl("tval",names(CONTENT))][ncol(CONTENT)])
}

pdf("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux/n138_IntraFlux.mods/MainEffects.pdf",width=6,height=5,paper='special')
levelplot(MAT_MAIN,col.regions = colorRampPalette(c('darkblue','blue','lightblue','white','orange','orangered','darkred'))(100000), xlab="",ylab="",at=c(5,4,3,2,1,0,-1,-2,-3,-4,-5))
dev.off()

################################################
### Create Second Matix Exploring Covariates ###
################################################

print("Creating First Matrix of Covarying Effects")
COVARS<-MAINS[c(3,6,9,12,15)]
MAT_COVAR<-matrix(NA, nrow = 15, ncol = 12)
 
INDEX=0
for (FILE in COVARS){
	CONTENT<-read.csv(FILE)
	if (CONTENT[1,1] == "gica_network_1_zstat"){
		CONTENT<-CONTENT[c(1,5:12,2:4),]
	}
	CONTENT<-CONTENT[,grepl("tval.",names(CONTENT))]
	INDEX=INDEX+1
	MAT_COVAR[INDEX,1:12]<-t(CONTENT[grepl("tval",names(CONTENT))][2])
	INDEX=INDEX+1
	MAT_COVAR[INDEX,1:12]<-t(CONTENT[grepl("tval",names(CONTENT))][3])
	INDEX=INDEX+1
	MAT_COVAR[INDEX,1:12]<-t(CONTENT[grepl("tval",names(CONTENT))][4])
}

pdf("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux/n138_IntraFlux.mods/CovaryingEffects.pdf",width=6,height=5,paper='special')
levelplot(MAT_COVAR,col.regions = colorRampPalette(c('darkblue','blue','lightblue','white','orange','orangered','darkred'))(100000), xlab="",ylab="",at=c(5,4,3,2,1,0,-1,-2,-3,-4,-5))
dev.off()

##################################################
### Create Second Matix Exploring Interactions ###
##################################################

print("Creating First Matrix of Interaction Effects")
INTERS<-c(S1[c(3,2)],S2_REST1[c(3,2)],S2_AMG[c(3,2)],S2_REST2[c(3,2)],S3[c(4,3)])
MAT_INTERS<-matrix(NA, nrow = 10, ncol = 12)

INDEX=0
for (FILE in INTERS){
	CONTENT<-read.csv(FILE)
	if (CONTENT[1,1] == "gica_network_1_zstat"){
		CONTENT<-CONTENT[c(1,5:12,2:4),]
	}
	CONTENT<-CONTENT[,grepl("tval.",names(CONTENT))]
	INDEX=INDEX+1
	MAT_INTERS[INDEX,1:12]<-t(CONTENT[grepl("tval",names(CONTENT))][ncol(CONTENT)])
}

pdf("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux/n138_IntraFlux.mods/InteractionEffects.pdf",width=6,height=5,paper='special')
levelplot(MAT_INTERS,col.regions = colorRampPalette(c('darkblue','blue','lightblue','white','orange','orangered','darkred'))(100000), xlab="",ylab="",at=c(5,4,3,2,1,0,-1,-2,-3,-4,-5))
dev.off()

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
