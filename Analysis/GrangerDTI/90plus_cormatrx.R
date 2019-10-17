#!/usr/bin/env Rscript
###################################################################################################
##########################                 GrangerDTI                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

print("Reading Arguments")

covaPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/RawData/90plus_corMatrix/RAVLTsubsetworking.csv"
inputPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/RawData/90plus_corMatrix/n29_right"
OutDirRoot <- " /dfs2/yassalab/rjirsara/GrangerDTI/Figures/90Plus/"
covsFormula <- "~AgeAtScan"

library(R.matlab)
library(ggplot2)
library(corrplot)
library(lattice)

####################################################
##### Commands For Data Preparation From Steve #####
####################################################

inputFiles = list.files(path= inputPath,pattern="*.txt", full.names = TRUE)



emptyarray <- array(as.numeric(NA),dim =c(10,12,length(temp)))

#Read in Neuroimaging Files Into A 3D Array

j <- 0
for (i in temp) {
    j <- j + 1
    df2 <- read.table(i, sep = '\t',header = T,quote='', comment='')
    x <- as.matrix(df2)
    emptyarray[,,j] = x
}

firstdrop <-emptyarray[1:10,2:12,1:length(temp)]
colnames (firstdrop) <- as.character(unlist(firstdrop[1,,length(temp)]))
firstdrop=firstdrop[-1,,]
seconddrop4=firstdrop[,-1,]
class(seconddrop4) <- "numeric" 

#Read in Cognition Data Into A Dataset

  covaData <- read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/RawData/90plus_corMatrix/RAVLTsubsetworking.csv")
  covaData$NeuroID<-0
  
  DIM_TEMP<-length(temp)
  for (DIM in 1:DIM_TEMP){
    SUBID<-strsplit(temp, "/")[[DIM]][11]
    SUBID<-substr(SUBID, 1,3)
    SUBID_ROW<-which(covaData$Subject.ID == SUBID)
    covaData[SUBID_ROW,"NeuroID"] <- 1
  }
 
  covaData<-covaData[which(covaData$NeuroID == "1"),]
  covaData<-covaData[order(covaData$Subject.ID),]
  covaData$NeuroID<-NULL

##########################################################
##### Clean Array and Covert Into Single Spreadsheet #####
##########################################################

  ARRAY<-seconddrop4[,-c(10),]
  row=as.list("")
  final=as.list("")
  maxsubs<-dim(ARRAY)[3]

  for (subject in 1:maxsubs){
    final[[subject]]=unlist(covaData[subject,])
    maxrows<-dim(ARRAY)[1]
    for (single in 1:maxrows){
      row[[single]]<-as.numeric(ARRAY[single,,subject])
      final[[subject]]<-append(row[[single]],final[[subject]])
    }
  }

  FINAL<-t(as.data.frame(final))
  FINAL<-as.data.frame(FINAL[1:maxsubs,])
 # NAMES = c(colnames(ARRAY))
 # names(FINAL)[1:dim(ARRAY)[2]] <- NAMES 
 # NAMES = c(colnames(covaData))
 # names(FINAL)[dim(ARRAY)[2]:dim(covaData)[2]] <- NAMES 

############################################################
##### Refine Variables of Interest and Relabel Columns #####
############################################################

  matrixlength=dim(ARRAY)[2]
  FINALS=as.data.frame("")
  if (matrixlength == 9){

    for (x in 1:(matrixlength-1)){
       min<-(x+1)+(9*(x-1))
       max<-(9*x)+1
       subset<-FINAL[,c(min:max)]
       FINALS<-cbind(FINALS,subset)
    }
    FINALS<-FINALS[,-c(1)]
    names(FINALS)[1:8]<-c("CA1-CA2","CA1-DG","CA1-CA3","CA1-SUB","CA1-ERC","CA1-BA35","CA1-BA-36","CA1-PHC")
    names(FINALS)[9:15]<-c("CA2-DG","CA2-CA3","CA2-SUB","CA2-ERC","CA2-BA35","CA2-BA36","CA2-PHC")
    names(FINALS)[16:21]<-c("DG-CA3","DG-SUB","DG-ERC","DG-BA35","DG-BA36","DG-PHC")
    names(FINALS)[22:26]<-c("CA3-SUB","CA3-ERC","CA3-BA35","CA3-BA36","CA3-PHC")
    names(FINALS)[27:30]<-c("SUB-ERC","SUB-BA35","SUB-BA36","SUB-PHC")
    names(FINALS)[31:33]<-c("ERC-BA35","ERC-BA36","ERC-PHC")
    names(FINALS)[34:35]<-c("BA35-BA36","BA35-PHC")
    names(FINALS)[36]<-c("BA36-PHC")
    FINALS<-cbind(FINAL$V1,FINALS)
    names(FINALS)[1]<-"RAVLT"
    rownames(FINALS)<-NULL

  } else {

    print(paste("Matrix Length Not Expected:",maxtrixlength,"Revisions Are Needed"))
    exit <- function(){
        .Internal(.invokeRestart(list(NULL, NULL), NULL))
      }
    exit()
  }

##################################
##### Compute R and P Values #####
##################################

  Regions<-dim(FINALS)[2]
  NewRow<-dim(FINALS)[1]+1

### Correlation Matrix ###
  for (var in 2:Regions){
    connR<-cor(FINALS[,1],FINALS[,var], use="complete.obs", method="pearson") 
    FINALS[NewRow,var]<-as.numeric(connR)
    print(connR)
  }

  Rvals<-FINALS[NewRow,-c(1)]
  FINALS<-FINALS[-c(NewRow),]

### P-value Matrix ###
  for (var in 2:Regions){
    MAX<-max(FINALS[,var])
    if (max(FINALS[,var], na.rm=TRUE) > 0){
      connSummary<-summary(lm(FINALS[,1]~FINALS[,var]))[4]
      connP<-connSummary$coefficients[2,4]
      FINALS[NewRow,var]<-as.numeric(connP)
    }
  }

  Pvals<-FINALS[NewRow,-c(1)]
  FINALS<-FINALS[-c(NewRow),]

###################################################
##### Create Matrix of Data For Final Figures #####
###################################################

### Correlation Matrix ###
  rMATRIX<-matrix(, nrow = 9, ncol = 9)
  colnames(rMATRIX)<-c("CA1","CA2","DG","CA3","SUB","ERC","BA35","BA36","PHC")
  rownames(rMATRIX)<-c("CA1","CA2","DG","CA3","SUB","ERC","BA35","BA36","PHC")
  ognames<-ARRAY[0,,1]
  numRval<-length(Rvals)
  for (num in 1:numRval){
    VAL<-round(Rvals[[num]][1], digits = 2)
    HEADER<-names(Rvals[num])
    HEADER1<-strsplit(HEADER,"-", fixed = FALSE)[[1]][1]
    HEADER2<-strsplit(HEADER,"-", fixed = FALSE)[[1]][2]

    colh1<-which(colnames(rMATRIX)== HEADER1)
    rowh2<-which(rownames(rMATRIX)== HEADER2)
    rMATRIX[colh1,rowh2]<-VAL

    colh2<-which(colnames(rMATRIX)== HEADER2)
    rowh1<-which(rownames(rMATRIX)== HEADER1)
    rMATRIX[colh2,rowh1]<-VAL
  }

### P-value Matrix ###
  pMATRIX<-matrix(, nrow = 9, ncol = 9)
  colnames(pMATRIX)<-c("CA1","CA2","DG","CA3","SUB","ERC","BA35","BA36","PHC")
  rownames(pMATRIX)<-c("CA1","CA2","DG","CA3","SUB","ERC","BA35","BA36","PHC")
  ognames<-ARRAY[0,,1]
  numRval<-length(Pvals)
  for (num in 1:numRval){
    VAL<-round(Pvals[[num]][1], digits = 6)
    HEADER<-names(Pvals[num])
    HEADER1<-strsplit(HEADER,"-", fixed = FALSE)[[1]][1]
    HEADER2<-strsplit(HEADER,"-", fixed = FALSE)[[1]][2]

    colh1<-which(colnames(pMATRIX)== HEADER1)
    rowh2<-which(rownames(pMATRIX)== HEADER2)
    pMATRIX[colh1,rowh2]<-VAL

    colh2<-which(colnames(pMATRIX)== HEADER2)
    rowh1<-which(rownames(pMATRIX)== HEADER1)
    pMATRIX[colh2,rowh1]<-VAL
  }

### Finish Matricies ###
  for (num in 1:9){
    rMATRIX[num,num]<-1
    pMATRIX[num,num]<-1
  }

################################
##### Create Final Figures #####
################################
  
  OutputPath=paste("/dfs2/yassalab/rjirsara/GrangerDTI/Figures/90Plus",hemi, sep='/')

  pdf(paste(OutputPath,"/n18_Correlations_20191014.pdf",sep='/'),width=6,height=5,paper='special')
  levelplot(rMATRIX, col.regions=heat.colors(100))
  dev.off()

  pdf(paste(OutputPath,"n18_Significance_20191014.pdf",sep='/'),width=6,height=5,paper='special')
  levelplot(pMATRIX, col.regions=heat.colors(100))
  dev.off()

#############################################
##### Save Output Dataset and Matricies #####
#############################################

  write.csv(FINALS, paste(OutputPath,"n18_HippoSubRegions_20191014.csv", sep='/'))
  write.table(rMATRIX, file = paste(OutputPath,"n18_R-Value_Matrix_20191014.csv", sep='/'))
  write.table(pMATRIX, file = paste(OutputPath,"n18_P-Value_Matrix_20191014.csv", sep='/'))

}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
