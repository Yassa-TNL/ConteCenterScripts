#!/usr/bin/env Rscript
###################################################################################################
##########################                 GrangerDTI                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

library(R.matlab)
library(ggplot2)
library(corrplot)

####################################################
##### Commands For Data Preparation From Steve #####
####################################################

temp = list.files(path= "/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/RawData/90plus_corMatrix",pattern="*.txt", full.names = TRUE)

emptyarray <- array(as.numeric(NA),dim =c(10,12,length(temp)))

#read in .txt files recursively and store in 3D arrays
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

#All18subj <- apply(seconddrop4,c(1,2),mean)
RAVLTsubdimensional <- read.csv("/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/RawData/90plus_corMatrix/RAVLTsubsetworking.csv")
RAVLTsubdimensional <- RAVLTsubdimensional[,-1]
RAVLTsubdimensional <- as.data.frame(RAVLTsubdimensional)

##########################################################
##### Clean Array and Covert Into Single Spreadsheet #####
##########################################################

ARRAY<-seconddrop4[,-c(10),]
row=as.list("")
final=as.list("")
maxsubs<-dim(ARRAY)[3]

for (subject in 1:maxsubs){
  final[[subject]]=as.vector(RAVLTsubdimensional[subject,])
  maxrows<-dim(ARRAY)[1]
  for (single in 1:maxrows){
    row[[single]]<-as.numeric(ARRAY[single,,subject])
    final[[subject]]<-append(final[[subject]],row[[single]])
   }
}

FINAL<-t(as.data.frame(final))
FINAL<-as.data.frame(FINAL[1:maxsubs,])
names(FINAL)[1]<-"RAVLT"

############################################################
##### Refine Variables of Interest and Relabel Columns #####
############################################################

matrixlength=sqrt(dim(FINAL)[2]-1)
FINALS=as.data.frame("")
if (matrixlength == 9){

  for (x in 1:(matrixlength-1)){
     min<-(x+1)+(9*(x-1))+1
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
  FINALS<-cbind(FINAL$RAVLT,FINALS)

} else {

  print(paste("Matrix Length Not Expected:",maxtrixlength,"Revisions Are Needed"))
  exit <- function() {
    .Internal(.invokeRestart(list(NULL, NULL), NULL))
  }
  exit()
}

########################################
##### Execute Corelations Matrices #####
########################################

MATRIX<-FINALS[,-c(which(colSums(FINALS) == 0))]
M<-cor(MATRIX, use="pairwise.complete.obs")


corrplot.mixed(M, lower.col = "black", number.cex = 0.75)

corrplot(M, type = "lower", order = "hclust", tl.col = "black", tl.srt = 45)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
