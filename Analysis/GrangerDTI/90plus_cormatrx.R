#!/usr/bin/env Rscript
###################################################################################################
##########################                 GrangerDTI                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

print("Reading Arguments")

inputPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Audits/90-Plus/RawData/n29_right"
covaPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Audits/90-Plus/RawData/RAVLTsubsetworking.csv"

covsFormula <- "~RAVLT.Learning.Sum.x+Age.at.Enrollment+Gender.x"
ChangeType<-list("as.numeric","as.numeric","as.factor")


OutDirRoot <- " /dfs2/yassalab/rjirsara/GrangerDTI/Figures/90Plus/"



################################################################################
##### Transform Input Files Into Matricies and Combine Into A Single Array #####
################################################################################

InputFiles = list.files(path= inputPath,pattern="*.txt", full.names = TRUE)
MaxSubject<-length(InputFiles)

if (file.exists(InputFiles[1]) == FALSE){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	print(paste("Input Files Not Found - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	quit(save="no")
}

for (Subject in 1:MaxSubject){
	dataset=read.table(InputFiles[Subject], header = FALSE)
	maxdim<-dim(dataset)[1]
	for (DIM in 1:maxdim){
		row<-as.matrix(dataset[DIM,])
		row<-row[1:maxdim]
		col<-t(as.data.frame(dataset[,DIM]))
		col<-col[1:maxdim]
		BALANCED<-identical(row,col)
		if (BALANCED == FALSE){
			print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
			print(paste("Not Balanced Matrix File:",Subject," Dimension Number:",DIM," - Exiting Script"))
			print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
			quit(save="no")
		}
		DATASET<-data.frame(lapply(dataset, as.character.factor), stringsAsFactors=FALSE)
		chrVSint<-suppressWarnings(is.na(as.numeric(DATASET[DIM,])))
		chrSELECT<-grep(FALSE,chrVSint)
		if (length(chrSELECT)==0){
			ColumnNameRow=DIM
		}
	}
	if (!exists("ColumnNameRow")){
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡"))
		print(paste("Cannot Locate Row with Column Names for File:",Subject," - Exiting Script"))
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡"))
		quit(save="no")
	}
	DATASETRefined<-DATASET[c(ColumnNameRow:maxdim),c(ColumnNameRow:maxdim)]
	ColumnNAMES<-list(DATASETRefined[1,])
	MATRIX<-as.matrix(DATASETRefined[c(2:dim(DATASETRefined)[1]),c(2:dim(DATASETRefined)[1])])
	if (!exists("ARRAY")){
		MatrixDim<-dim(MATRIX)[1]
		ARRAY<-array(as.numeric(NA),dim =c(MatrixDim,MatrixDim,MaxSubject))
	}
	ARRAY[,,Subject] = MATRIX
}

#######################################################################################
##### Convert Array Into Single Spreadsheet With Proper Column Names For Analysis #####
#######################################################################################

row=as.list("")
SPREADSHEET=vector(mode = "list", length = MaxSubject)

for (Subject in 1:MaxSubject){
	for (Single in 1:MatrixDim){
		row[[Single]]<-as.numeric(ARRAY[Single,,Subject])
		SPREADSHEET[[Subject]]<-append(SPREADSHEET[[Subject]],row[[Single]])
	}
}

SPREADSHEET<-as.data.frame(t(as.data.frame(SPREADSHEET)))
rownames(SPREADSHEET)<-NULL
ColumnNAMES<-ColumnNAMES[[1]][-1]

if (length(ColumnNAMES)^2 != dim(SPREADSHEET)[2]){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡"))
	print(paste("Descrepancy Between Column Names and Dimensions of Final Spreadsheet - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡"))
	quit(save="no")
}

x=0
for (FirstRegion in 1:length(ColumnNAMES)){
	for (SecondRegion in 1:length(ColumnNAMES)){
		x=x+1
		One<-ColumnNAMES[FirstRegion]
		Two<-ColumnNAMES[SecondRegion]
		NAME<-print(paste(One,"x",Two))
		NAME<-gsub(" ","",NAME)
		names(SPREADSHEET)[x] <- NAME
	}
}

###################################################################################
##### Read In Covariate File To Merge with the Connectivity Data For Analysis #####
###################################################################################

if (file.exists(covaPath[1]) == FALSE){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
	print(paste("Covariates Files Not Found - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
	quit(save="no")
}

covaData <- read.csv(covaPath)
covaData$NeuroID<-0

for (Subject in 1:MaxSubject){
	SUBID<-strsplit(InputFiles, "/")[[Subject]][10]
	SUBID<-substr(SUBID, 1,3)
	SUBID_ROW<-which(covaData$Subject.ID == SUBID)
	covaData[SUBID_ROW,"NeuroID"] <- Subject
}
 
covaData<-covaData[which(covaData$NeuroID != 0),]
covaData<-covaData[order(covaData$NeuroID),]
covaData$NeuroID<-NULL
MaxSubsCov<-dim(covaData)[1]

if (MaxSubject != MaxSubsCov){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
	print(paste("Unequal Subjects in Connectivity (",MaxSubject,") and Covarites (",MaxSubsCov,") Files - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
	quit(save="no")
}

MaxVarsCov<-dim(covaData)[2]
DATASET<-cbind(covaData,SPREADSHEET)

######################################################
##### Prepare Variables of Interest For Analysis #####
######################################################

Predictors<-gsub("~", "",covsFormula)
Predictors<-gsub("\\*", "+",Predictors)
Predictors<-strsplit(Predictors, "+", fixed = TRUE)
MaxPredictors<-dim(as.data.frame(Predictors))[1]

for (VarNum in 1:MaxPredictors){
	VarName<-as.character(as.data.frame(Predictors)[[1]][VarNum])
	if (VarName %in% colnames(DATASET)){
		if (length(ChangeType) == MaxPredictors){
			Type<-ChangeType[[VarNum]][1]
			DATASET[,VarName]<-suppressWarnings(unlist(lapply(as.character(DATASET[,VarName]), Type)))
		}	
		DATASET<-DATASET[complete.cases(DATASET[,VarName]),]
		classtype<-class(DATASET[,VarName])		
		print(paste("##############################################"))
		print(paste("⚡⚡⚡",VarName,"is defined as a", classtype,"⚡⚡⚡"))
		print(paste("##############################################"))
	} else {
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
		print(paste("⚡⚡⚡",VarName,"NOT FOUND - EXITING SCRIPT ⚡⚡⚡"))
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
	}
}
######################################
##### Load Packages For Analysis #####
######################################

suppressMessages(library(corrplot))
suppressMessages(library(R.matlab))
suppressMessages(library(lattice))
suppressMessages(library(ggplot2))
suppressMessages(library(ppcor))

##################################################
##### Execute Correlations and Linear Models #####
##################################################

RvalRow<-dim(SPREADSHEET)[1]+1
PvalRow<-dim(SPREADSHEET)[1]+2
MainPredict<-Predictors[[1]][1]

if (MaxPredictors == 1){

	for (connection in 1:dim(SPREADSHEET)[2]){
		ConnNum<-dim(covaData)[2]+connection	
		ConnR<-suppressWarnings(cor.test(DATASET[,MainPredict],DATASET[,ConnNum], method="pearson")$estimate)
		ConnP<-suppressWarnings(cor.test(DATASET[,MainPredict],DATASET[,ConnNum], method="pearson")$p.value)
		if (is.null(ConnR)){
			ConnR<-NA
		}
		SPREADSHEET[RvalRow,connection]<-as.numeric(ConnR)
		SPREADSHEET[PvalRow,connection]<-as.numeric(ConnP)
	}
	Rvals<-SPREADSHEET[RvalRow,]
	Pvals<-SPREADSHEET[PvalRow,]
	SPREADSHEET<-SPREADSHEET[-c(RvalRow,PvalRow),]

} else {

	for (connection in 1:dim(SPREADSHEET)[2]){
		ConnNum<-dim(covaData)[2]+connection
		LIST=vector(mode = "list", length = MaxPredictors+1)
		LIST[[1]]<-DATASET[,MainPredict]
		LIST[[2]]<-DATASET[,ConnNum]
		for (PredictNum in 2:MaxPredictors){
			PredictName<-Predictors[[1]][PredictNum]
			LIST[[PredictNum+1]]<-DATASET[,PredictName]
		}
		if (length(LIST)==3){
			ConnR<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]]), method="pearson")$estimate
			ConnP<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]]), method="pearson")$p.value
		}
		if (length(LIST)==4){
			ConnR<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]]), method="pearson")$estimate
			ConnP<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]]), method="pearson")$p.value
		}
		if (length(LIST)==5){
			ConnR<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]]), method="pearson")$estimate
			ConnP<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]]), method="pearson")$p.value
		}
		if (length(LIST)==6){
			ConnR<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]]), method="pearson")$estimate
			ConnP<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]]), method="pearson")$p.value
		}
		if (length(LIST)==7){
			ConnR<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]],LIST[[7]]), method="pearson")$estimate
			ConnP<-pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]],LIST[[7]]), method="pearson")$p.value
		}
		if (length(LIST)>7){
			print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡"))
			print(paste("Need To Edit Script Before Analyzing This Much Variables:",length(LIST),"- Exiting Script"))
			print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡"))
			quit(save="no")
		}
		if (is.null(ConnR)){
			ConnR<-NA
		}
		SPREADSHEET[RvalRow,connection]<-as.numeric(ConnR)
		SPREADSHEET[PvalRow,connection]<-as.numeric(ConnP)
	}
	Rvals<-SPREADSHEET[RvalRow,]
	Pvals<-SPREADSHEET[PvalRow,]
	SPREADSHEET<-SPREADSHEET[-c(RvalRow,PvalRow),]
}





		Covariates<-noquote(paste(unlist(PredictLIST),collapse = ','))


		ConnR<-suppressWarnings(pcor.test(DATASET[,MainPredict],DATASET[,ConnNum], method="pearson")$estimate)
		ConnP<-suppressWarnings(cor.test(DATASET[,MainPredict],DATASET[,ConnNum], method="pearson")$p.value)
		if (is.null(ConnR)){
			ConnR<-NA
		}
		SPREADSHEET[RvalRow,connection]<-as.numeric(ConnR)
		SPREADSHEET[PvalRow,connection]<-as.numeric(ConnP)
	}
	Rvals<-SPREADSHEET[RvalRow,]
	Pvals<-SPREADSHEET[PvalRow,]
	SPREADSHEET<-SPREADSHEET[-c(RvalRow,PvalRow),]

}
as.formula(paste(paste0("dataSubj[,",x,"]"), covsFormula, sep="")) 
Covariates<-noquote(Covariates, right=TRUE)



PredictFinal<-gsub(' ','',PredictFinal)
DATASET[,ConnNum]
DATASET[,'Age.at.Enrollment']

TEST<-paste(DATASET[,MainPredict],DATASET[,ConnNum],c(DATASET[,'Age.at.Enrollment'],DATASET[,'Gender.x']), method="pearson")


TEST<-paste(DATASET[,MainPredict],DATASET[,ConnNum],c(PredictLIST), method="pearson")



c(LIST[[3]]
c(LIST[[3]],LIST[[4]])



pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]]), method="pearson")







pcor.test(DATASET[,MainPredict],DATASET[,ConnNum],c(DATASET[,'Age.at.Enrollment'],DATASET[,'Gender.x']), method="pearson")

pcor.test(DATASET[,MainPredict],DATASET[,ConnNum],c(Covariate), method="pearson")




MainPredict<-Predictors[[1]][1]

for 2
ConvaryPredict<-Predictors[[1]][2:MaxPredictors]
ConvaryPredict
c()




pcor.test(DATASET[Predictors[[1]][1],],DATASET[,],DATASET[,], method = c("spearman"))


HSGPA,FGPA,SATV, method = c("spearman"))

pcor.test(DATA$RAVLT.Learning.Sum.x, DATA$CA1xDG, DATA$Age.at.Enrollment, method = c("spearman"), na.rm = TRUE, data=covaData)










<-pcor.test(x, y, z, use = c("mat","rec"), method = c("pearson","spearman","kendall"), na.rm = T)
print("Analyzing Dataset")

model.formula <- mclapply((dim(covaData)[2] + 1):dim(dataSubj)[2], function(x) { 
  as.formula(paste(paste0("dataSubj[,",x,"]"), covsFormula, sep="")) 
}, mc.cores=ncores)

print("Executing Models")

m <- mclapply(model.formula, function(x) {
  ANALYZE <- gamm4(formula = x, random=as.formula(randomFormula), data=dataSubj, REML=T)$gam
  summary <- summary(ANALYZE)
  residuals <- ANALYZE$residuals
  missing <- as.numeric(ANALYZE$na.action)
  return(list(summary,residuals, missing))
}, mc.cores=ncores)





### Correlation Matrix ###

for (connection in 1:dim(SPREADSHEET)[2]){
	<-pcor.test(x, y, z, use = c("mat","rec"), method = c("pearson","spearman","kendall"), na.rm = T)
	connR<-cor(covaData[,""],FINALS[,var], use="complete.obs", method="pearson") 
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






















##### Refine Variables of Interest and Relabel Columns #####
############################################################
library(R.matlab)
library(ggplot2)
library(corrplot)
library(lattice)


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
