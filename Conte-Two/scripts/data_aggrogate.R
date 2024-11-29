#!/usr/bin/env Rscript
######################

invisible(lapply(c("stringr","tidyr","plyr","dplyr","purrr","reshape2"), require, character.only=TRUE))
ATLDIR="/dfs9/yassalab/rjirsara/ConteCenterScripts/ToolBox/atlases"
ROOT<-"/dfs9/yassalab/CONTE2"; TODAY<-format(Sys.time(), "%Y%m%d")
NAMES200<-read.table(paste0(ATLDIR,"/atl-MelbourneP200S4.1D"),header=FALSE)
NAMES400<-read.table(paste0(ATLDIR,"/atl-MelbourneP400S4.1D"),header=FALSE)
LoadDFs <- function(file_paths, ...) {
        if (length(grep("PVT",file_paths)) == 0){
                DF <- do.call(rbind, lapply(file_paths, read.csv, ...))
                names(DF)<-gsub("mean_zmap_","",gsub("mean_tmap_","",names(DF)))
                names(DF)[1]<-'sub'
        } else {
                DF <- do.call(rbind, lapply(file_paths, read.table, ...)) 
                INDEX<-0
                for (FILE in file_paths){
                        INDEX=INDEX+1
                        DF[INDEX,"sub"]<-gsub("sub-","",gsub(".gfeat","",strsplit(FILE,'/')[[1]][8]))
                }
                names(DF)[1]<-"PVT"; DF<-DF[,c("sub","PVT")]
        }
        return(DF)
}

#ANAT
DFs <- list() ; index = 0
MAX=length(list.files(paste0(ROOT,"/datasets"),pattern='Schaefer400',full.names=T))
for (F in list.files(paste0(ROOT,"/datasets"),pattern='Schaefer400',full.names=T)){
        index = index + 1 ; print(F) ; DFs[[index]]<-read.csv(F,row.names = 1)
        DFs[[index]]['sub']<-row.names(DFs[[index]]) 
        row.names(DFs[[index]])<-NULL ; DFs[[index]]<-DFs[[index]][-1]
        DFs[[index]]<-DFs[[index]][,c(ncol(DFs[[index]]),2:ncol(DFs[[index]])-1)]
        if (index != MAX){
                DFs[[index]]['BrainSegVolNotVent']<-NULL 
                DFs[[index]]['eTIV']<-NULL
        }
}
Schaefer<-Reduce(function(x, y) merge(x, y, by=c("sub"), all=TRUE), DFs)
Schaefer<-Schaefer[,!grepl("FreeSurfer_Defined_Medial", names(Schaefer))]
write.csv(Schaefer,paste0(ROOT,"/datasets/anat-Schaefer400_296x1207_20240719.csv"),row.names=FALSE)

#ASEG
ASEG<-read.csv("/dfs9/yassalab/CONTE2/datasets/anat-aseg.csv")
HYPO<-read.csv("/dfs9/yassalab/CONTE2/datasets/anat-hypothalamic.csv")
names(ASEG)[1]<-"sub"; ASEG$sub<-gsub("sub-","",ASEG$sub)
names(HYPO)[1]<-"sub"; HYPO$sub<-gsub("sub-","",HYPO$sub)
ASEG<-merge(ASEG,HYPO,by="sub",all=TRUE)
ASEG<-ASEG[which(ASEG$sub %in% Schaefer$sub),]
write.csv(ASEG,paste0(ROOT,"/datasets/anat-ASEG_296x77_20240719.csv"),row.names=FALSE)

#ALFF/ReHo
for (PIPE in c("pipe-36despike_task-rest","pipe-36despike_task-bandit_runs")){
        lPIPE<-gsub("task-","",strsplit(PIPE,'_')[[1]][2])
        for (METRIC in c("alff","reho")){
                FILENAME<-paste0(METRIC,"_quantifyAtlas.csv")
                FILES<-list.files(paste0(ROOT,'/pipelines/xcpengine/',PIPE), pattern=FILENAME, full.names=T, recursive=T)
                for (ATLAS in c("MelbourneP200S4","MelbourneP400S4")){
                        DFs <- list() ; index = 0
                        for (F in FILES[grep(ATLAS, FILES)]){
                                index = index + 1 ; print(F)
                                DFs[[index]]<-read.csv(F,row.names = 1)
                                DFs[[index]]['sub']<-gsub("sub-","",row.names(DFs[[index]]))
                                DFs[[index]]<-DFs[[index]][,c(ncol(DFs[[index]]),2:ncol(DFs[[index]])-1)]
                                row.names(DFs[[index]])<-NULL
                        }
                        DATASET<-bind_rows(DFs) 
                        DATASET<-DATASET[,which(colSums(is.na(DATASET))<100)]
                        names(DATASET)<-gsub(paste0("mean_",METRIC,"_"),"",names(DATASET))
                        ATLAS_LABEL<-gsub("P","",gsub("S4","",ATLAS))
                        write.csv(DATASET, paste0(ROOT,"/datasets/",METRIC,"-",lPIPE,"_",ATLAS_LABEL,"_",nrow(DATASET),"x",ncol(DATASET),"_",TODAY,".csv"), row.names=FALSE)
                }
        }
}

#Beta/Contrast - Missing 5 scans because they only had 1 of 4 bandit runs
FILES<-list.files(paste0(ROOT,'/pipelines/xcpfeat/pipe-feat2_task-bandit'), pattern="quantifyAtlas.csv", full.names=T, recursive=T)
for (COPE in c("cope1", "cope2", "cope3")){
        if (COPE == "cope1"){
                PREFIX<-"beta1-won"
        } else if (COPE == "cope2"){ 
                PREFIX<-"beta2-loss"
        } else if (COPE == "cope3"){ 
                PREFIX<-"contrast"
        }        
        for (MAP in c("tmap", "zmap")){
                DF2<-LoadDFs(FILES[grepl(COPE, FILES) & grepl("MelbourneP200S4", FILES) & grepl(MAP, FILES)])
                DF4<-LoadDFs(FILES[grepl(COPE, FILES) & grepl("MelbourneP400S4", FILES) & grepl(MAP, FILES)])
                PVT<-LoadDFs(FILES[grepl(COPE, FILES) & grepl("PVT", FILES) & grepl(MAP, FILES)])
                DF2<-merge(DF2,PVT,by="sub",all=TRUE); DF4<-merge(DF4,PVT,by="sub",all=TRUE)
                write.csv(DF2,paste0(ROOT,"/datasets/",PREFIX,"_",MAP,"_MelbourneP200S4_",nrow(DF2),"x",ncol(DF2),"_",TODAY,".csv"),row.names=FALSE)
                write.csv(DF4,paste0(ROOT,"/datasets/",PREFIX,"_",MAP,"_MelbourneP400S4_",nrow(DF4),"x",ncol(DF4),"_",TODAY,".csv"),row.names=FALSE)
        }
}

#TIME
FILES<-list.files(paste0(ROOT,'/pipelines/xcpengine'), pattern="roi2ts.tsv", full.names=T, recursive=T)
for (TASK in c("rest", "bandit")){
        for (ATLAS in c("200","400")){
                INDEX=0; SELECT=paste0("task-",TASK,".*MelbourneP",ATLAS,"S4")
                for (F in grep(SELECT, FILES, value = TRUE)){
                        INDEX=INDEX+1
                        SUB=gsub("sub-","",strsplit(F,'/')[[1]][8])
                        TIMESERIES=read.table(F,header=FALSE)
                        if (dim(TIMESERIES)[2] == 455){
                                names(TIMESERIES)<-NAMES400$V1
                        } else {
                                names(TIMESERIES)<-NAMES200$V1
                        }
                        TIMESERIES$sub<-SUB
                        TIMESERIES$nvolume<-row.names(TIMESERIES)
                        if (INDEX == 1){
                                TS<-TIMESERIES
                        } else {
                                TS<-rbind(TS,TIMESERIES)
                        }
                }
                TS<-TS[,c("sub","nvolume",setdiff(names(TS),c("sub", "nvolume")))]
                print(paste0("Saving: ",paste0(ROOT,"/datasets/time-",TASK,"_Melbourne",ATLAS,"_",nrow(TS),"x",ncol(TS),"_",TODAY,".csv")))
                write.csv(TS, paste0(ROOT,"/datasets/time-",TASK,"_Melbourne",ATLAS,"_",nrow(TS),"x",ncol(TS),"_",TODAY,".csv"), row.names=FALSE)
        }
}

#FCON
FILES<-list.files(paste0(ROOT,'/pipelines/xcpengine'), pattern="roi2ts.tsv", full.names=T, recursive=T)
for (F in FILES[grep("MelbourneP200S4",FILES)]){
        print(paste0("Aggrogating Data: ", F))
        TASK=gsub("_runs","",gsub("pipe-36despike_task-","",strsplit(F,'/')[[1]][7]))
        SUB=gsub("sub-","",strsplit(F,'/')[[1]][8])
        TIMESERIES=read.table(F,header=FALSE)
        if (dim(TIMESERIES)[2] == 455){
                names(TIMESERIES)<-NAMES400$V1
        } else {
                names(TIMESERIES)<-NAMES200$V1
        }
        cor_long <- melt(cor(TIMESERIES))
        cor_long <- cor_long[cor_long$Var1 != cor_long$Var2,]
        cor_long <- cor_long[!duplicated(t(apply(cor_long[,1:2], 1, sort))),]
        cor_long$Var1<-gsub("_","",gsub("-","",cor_long$Var1))
        cor_long$Var2<-gsub("_","",gsub("-","",cor_long$Var2))
        cor_long$label<- paste0("fcon_",cor_long$Var1,"_",cor_long$Var2)
        df<-as.data.frame(t(cor_long$value)); colnames(df)<-cor_long$label
        df$sub<-SUB; df$task<-TASK       
        if (exists("DF")){
                DF<-rbind(DF,df) 
        } else {
                DF<-df
        }
}; FCON_NAMES<-names(DF)[grep("fcon",names(DF))]
REST<-DF[which(DF$task=="rest"),]
REST<-cbind(REST[,"sub"], REST[,FCON_NAMES])
write.csv(REST, paste0(ROOT,"/datasets/fcon-rest_Melbourne400_",nrow(REST),"x",ncol(REST),"_",TODAY,".csv"), row.names=FALSE)
BANDIT<-DF[which(DF$task=="bandit"),]
BANDIT<-cbind(BANDIT[,"sub"], BANDIT[,FCON_NAMES])
write.csv(BANDIT, paste0(ROOT,"/datasets/fcon-bandit_Melbourne400_",nrow(BANDIT),"x",ncol(BANDIT),"_",TODAY,".csv"), row.names=FALSE)

#Quality Assurance
QA<-NULL; INDEX=0
VARS<-c("sub","EulerNumber","motionDVCorr","dvarsMean","relRMSMean",'DegreesFreedom')
QA<-setNames(data.frame(matrix(ncol=length(VARS), nrow=0)),VARS)
for (SUB in list.files(paste0(ROOT,'/pipelines/freesurfer'), pattern='sub')){
        SUBID<-gsub("sub-","",SUB)
        print(paste0("QA: ", SUBID)) ; INDEX=INDEX+1
        QA[INDEX,"sub"]<-SUBID
        QA[INDEX,"EulerNumber"]<-read.table(list.files(paste0(ROOT,'/pipelines/freesurfer/',SUB),pattern='nofix.euler',recursive=T,full.names=T))[1,1]
}
for (QAMetric in c("motionDVCorr", "dvars-mean", "relMeanRMS", "tdof")){
        for (FILE in list.files(paste0(ROOT,"/pipelines/xcpengine"),pattern=paste0(QAMetric,'.txt'),recursive=T,full.names=T)){
                QAVar<-gsub("-","",paste0(QAMetric,"_",gsub("pipe-36despike_task-","",strsplit(FILE,'/')[[1]][7])))
                SUB<-gsub("sub-",'',strsplit(FILE,'/')[[1]][8])
                QA[which(QA$sub==SUB),QAVar]<-as.numeric(read.table(FILE,fill = TRUE)[1,1])
        }
}
write.csv(QA, paste0(ROOT,"/datasets/qualvars_",nrow(QA),"x",ncol(QA),"_",TODAY,".csv"), row.names=FALSE)

#Beta/Contrast 
for (MODEL in c("1TD", "2Sampler", "3Hybrid", "4TD2LR", "5Sampler2LR", "6Hybrid2LR")){
        FILES<-list.files(paste0(ROOT,'/pipelines/xcpfeat/pipe-feat3_',MODEL), pattern="quantifyAtlas.csv", full.names=T, recursive=T)
        for (MAP in c("tmap", "zmap")){
                DF2<-LoadDFs(FILES[grepl("MelbourneP200S4", FILES) & grepl(MAP, FILES)])
                DF4<-LoadDFs(FILES[grepl("MelbourneP400S4", FILES) & grepl(MAP, FILES)])
                PVT<-LoadDFs(FILES[grepl("PVT", FILES) & grepl(MAP, FILES)])
                PVT$sub<-gsub(".feat","",PVT$sub)
                PREFIX<-paste0("beta3-",MODEL)
                DF2<-merge(DF2,PVT,by="sub",all=TRUE); DF4<-merge(DF4,PVT,by="sub",all=TRUE)
                write.csv(DF2,paste0(ROOT,"/datasets/",PREFIX,"_",MAP,"_MelbourneP200S4_",nrow(DF2),"x",ncol(DF2),"_",TODAY,".csv"),row.names=FALSE)
                write.csv(DF4,paste0(ROOT,"/datasets/",PREFIX,"_",MAP,"_MelbourneP400S4_",nrow(DF4),"x",ncol(DF4),"_",TODAY,".csv"),row.names=FALSE)
        }
}

########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######