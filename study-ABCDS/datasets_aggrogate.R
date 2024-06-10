#!/usr/bin/env Rscript
######################

LABELS<-read.csv("/dfs8/yassalab/rjirsara/ConteCenterScripts/ToolBox/atlases/ATL-Gordon_Parcels.1D",header=FALSE)
invisible(lapply(c("stringr","tidyr","plyr","dplyr"), require, character.only=TRUE))
XCP<-"pipelines/xcpengine/pipe-36p_despike_smo0_task-rest"
TODAY<-format(Sys.time(), "%Y%m%d")
ROOT<-"/dfs8/yassalab/ABCDS"

###### 
### Anatomical Features
######

#Gordon
DFs <- list() ; index = 0
MAX=length(list.files(paste0(ROOT,"/datasets"),pattern='gordon',full.names=T))
for (F in list.files(paste0(ROOT,"/datasets"),pattern='gordon',full.names=T)){
        index = index + 1 ; print(F) ; DFs[[index]]<-read.csv(F,row.names = 1)
        DFs[[index]]['sub']<-row.names(DFs[[index]]) 
        row.names(DFs[[index]])<-NULL ; DFs[[index]]<-DFs[[index]][-1]
        DFs[[index]]<-DFs[[index]][,c(ncol(DFs[[index]]),2:ncol(DFs[[index]])-1)]
        if (index != MAX){
                DFs[[index]]['BrainSegVolNotVent']<-NULL 
                DFs[[index]]['eTIV']<-NULL
        }
} ; GORDON<-Reduce(function(x, y) merge(x, y, by=c("sub"), all=TRUE), DFs)
names(GORDON)<-gsub("_Parcel_","_",names(GORDON))
for (INDEX in 1:333){
        LABEL<-LABELS[INDEX,]
        names(GORDON)<-gsub(paste0("_",INDEX,"_"),paste0("_",LABEL,"_"),names(GORDON))
} ; write.csv(GORDON,paste0(ROOT,"/datasets/anat-gordon_276x1006_20240302.csv"),row.names=FALSE)

#APARC
DFs <- list() ; index = 0
MAX=length(list.files(paste0(ROOT,"/datasets"),pattern='aparc',full.names=T))
for (F in list.files(paste0(ROOT,"/datasets"),pattern='aparc',full.names=T)){
        index = index + 1 ; print(F) ; DFs[[index]]<-read.csv(F,row.names = 1)
        DFs[[index]]['sub']<-row.names(DFs[[index]]) 
        row.names(DFs[[index]])<-NULL ; DFs[[index]]<-DFs[[index]][-1]
        DFs[[index]]<-DFs[[index]][,c(ncol(DFs[[index]]),2:ncol(DFs[[index]])-1)]
        if (index != MAX){
                DFs[[index]]['BrainSegVolNotVent']<-NULL 
                DFs[[index]]['eTIV']<-NULL
        }
} ; APARC<-Reduce(function(x, y) merge(x, y, by=c("sub"), all=TRUE), DFs)
write.csv(APARC,paste0(ROOT,"/datasets/anat-aparc_276x205_20240302.csv"),row.names=FALSE)

#ALFF
DFs <- list() ; index = 0
for (F in list.files(paste0(ROOT,'/',XCP), pattern='gordon333_mean_alff.csv', full.names=T, recursive=T)){
        index = index + 1 ; print(F) ; DFs[[index]]<-read.csv(F,row.names = 1)
        DFs[[index]]['sub']<-gsub("sub-","",row.names(DFs[[index]]))
        row.names(DFs[[index]])<-NULL ; DFs[[index]]<-DFs[[index]][-1]
        DFs[[index]]<-DFs[[index]][,c(ncol(DFs[[index]]),2:ncol(DFs[[index]])-1)]
} ; ALFF<-bind_rows(DFs)
names(ALFF)<-gsub("anatomical_alff_mean_gordon333_","alff_",names(ALFF))
write.csv(ALFF,paste0(ROOT,"/datasets/func-alff_gordon_239x332_20240320.csv"),row.names=FALSE)

#ReHo
DFs <- list() ; index = 0
for (F in list.files(paste0(ROOT,'/',XCP), pattern='gordon333_mean_reho.csv', full.names=T, recursive=T)){
        index = index + 1 ; print(F) ; DFs[[index]]<-read.csv(F,row.names = 1)
        DFs[[index]]['sub']<-gsub("sub-","",row.names(DFs[[index]]))
        row.names(DFs[[index]])<-NULL ; DFs[[index]]<-DFs[[index]][-1]
        DFs[[index]]<-DFs[[index]][,c(ncol(DFs[[index]]),2:ncol(DFs[[index]])-1)]
} ; REHO<-bind_rows(DFs)
names(REHO)<-gsub("anatomical_reho_mean_gordon333_","alff_",names(REHO))
write.csv(REHO,paste0(ROOT,"/datasets/func-reho_gordon_239x332_20240320.csv"),row.names=FALSE)

#FCON
NETWORK_FCON<-NULL
PARCEL_FCON<-as.data.frame(matrix(ncol=3,nrow=1)); names(PARCEL_FCON)<-c("edge","fcon","sub")
for (F in list.files(paste0(ROOT,'/',XCP), pattern='gordon333.net$', full.names=T, recursive=T)){
        SUBID<-gsub("sub-","",strsplit(basename(F),"_")[[1]][1])
        print(paste0("FCON: ", SUBID))
        FCON<-read.table(F, header=T, skip = 2)
        FCON<-rbind(gsub("X","",names(FCON)),FCON) ; names(FCON)<-c("V1","V2","V3")
        FCON[,"HEADER"]<-paste0("edge_",FCON$V1,"x",FCON$V2,"_fcon")
        for (ROW in 1:nrow(FCON)){
                PARC1<-FCON[ROW,"V1"]
                LABEL1<-unlist(strsplit(LABELS[PARC1,],"x"))[2]
                PARC2<-FCON[ROW,"V2"]
                LABEL2<-unlist(strsplit(LABELS[PARC2,],"x"))[2]
                FCON[ROW,"LABELER"]<-paste0("edge_",LABEL1,"x",LABEL2,"_fcon")
        }
        FCON$V3<-as.numeric(FCON$V3) ; PARCELS<-FCON[,c("HEADER","V3")] 
        PARCELS[,"sub"]<-SUBID; names(PARCELS)<-names(PARCEL_FCON)
        NODES<-unique(gsub(".*x", "", LABELS$V1)) ; NETWORKS<-NULL 
        for (REGION1 in NODES){
                for (REGION2 in NODES[seq(which(NODES==REGION1),13)]){
                        EDGE<-paste0("edge_",REGION1,'x',REGION2,"_fcon")
                        STRENGTH<-mean(FCON[which(FCON$LABELER==EDGE),"V3"], na.rm = TRUE) #ABSOLUTE FCON?
                        NETWORKS<-rbind(NETWORKS,cbind(SUBID,EDGE,STRENGTH))
                }
        }
        NETWORKS<-as.data.frame(pivot_wider(as.data.frame(NETWORKS),names_from=EDGE,values_from=STRENGTH))
        NETWORK_FCON<-rbind(NETWORK_FCON,NETWORKS)
        PARCEL_FCON<-rbind(PARCEL_FCON,PARCELS)
} 
PARCEL_FCON<-PARCEL_FCON[-c(1),]; names(NETWORK_FCON)[1]<-"sub"
PARCELS_FCON<-as.data.frame(pivot_wider(PARCEL_FCON,names_from=edge,values_from=fcon))
write.csv(NETWORK_FCON,paste0(ROOT,"/datasets/func-fcon_gordon-networks_239x92_20240320.csv"),row.names=FALSE)
write.csv(PARCELS_FCON,paste0(ROOT,"/datasets/func-fcon_gordon-parcels_239x54947_20240320.csv"),row.names=FALSE)

#BOLD Timeseries
DFs<-NULL; INDEX=0
for (F in list.files(paste0(ROOT,'/',XCP), pattern='gordon333_ts.1D', full.names=T, recursive=T)){
        SUBID<-gsub("sub-","",strsplit(basename(F),"_")[[1]][1])
        INDEX = INDEX + 1 ; print(SUBID) ; DFs[[INDEX]]<-read.table(F)
        DFs[[INDEX]]$sub<-SUBID; DFs[[INDEX]]$volume<-row.names(DFs[[INDEX]])
        DFs[[INDEX]]<-DFs[[INDEX]][,c(334,335,1:333)]
} ; TIME<-bind_rows(DFs) ; names(TIME)<-gsub("V","parc-",names(TIME))
write.csv(TIME,paste0(ROOT,"/datasets/func-timeseries_87479x335_20240320.csv"),row.names=FALSE)

#Quality Assurance
QA<-NULL; INDEX=0
VARS<-c("sub","EulerNumber","motionDVCorr","dvarsMean","relRMSMean",'DegreesFreedom')
QA<-setNames(data.frame(matrix(ncol=length(VARS), nrow=0)),VARS) 
for (SUB in list.files(paste0(ROOT,'/',XCP), pattern='sub')){
        SUBID<-gsub("sub-","",SUB)
        print(paste0("QA: ", SUBID)) ; INDEX=INDEX+1
        QA[INDEX,"sub"]<-SUBID
        QA[INDEX,"EulerNumber"]<-read.table(list.files(paste0(ROOT,'/pipelines/freesurfer/',SUB),pattern='nofix.euler',recursive=T,full.names=T))[1,1]
        QA[INDEX,"motionDVCorr"]<-read.table(list.files(paste0(ROOT,'/',XCP,'/',SUB),pattern='_motionDVCorr.txt$',recursive=T,full.names=T)[2])[1,1]
        QA[INDEX,"dvarsMean"]<-read.table(list.files(paste0(ROOT,'/',XCP,'/',SUB),pattern='_dvars-mean.txt$',recursive=T,full.names=T)[2])[1,1]
        QA[INDEX,"relRMSMean"]<-read.table(list.files(paste0(ROOT,'/',XCP,'/',SUB),pattern='_relMeanRMS.txt$',recursive=T,full.names=T))[1,1]
        QA[INDEX,"DegreesFreedom"]<-read.table(list.files(paste0(ROOT,'/',XCP,'/',SUB),pattern='_tdof.txt$',recursive=T,full.names=T))[1,1]
} ; write.csv(QA,paste0(ROOT,"/datasets/qualvars_239x6_20240320.csv"),row.names=FALSE)

########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######