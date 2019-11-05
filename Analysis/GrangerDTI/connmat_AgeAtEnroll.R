#!/usr/bin/env Rscript
###################################################################################################
##########################                 GrangerDTI                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

print("Reading Arguments")

inputPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Audits/90-Plus/RawData/n18_left"
covaPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Audits/90-Plus/RawData/RAVLTsubsetworking.csv"

covsFormula <- "~Age.at.Enrollment+RAVLT.Recognition.Correct.x"
ChangeType<-list("as.numeric")
CorrType="pearson"

OutDirRoot <- " /dfs2/yassalab/rjirsara/GrangerDTI"
SubOutDir="Preliminary"

################################################################################
##### Transform Input Files Into Matricies and Combine Into A Single Array #####
################################################################################

print("Checking Input Arguments Are Correctly Formatted")

InputFiles = list.files(path= inputPath,pattern="*.txt", full.names = TRUE)
MaxSubject<-length(InputFiles)

if (file.exists(InputFiles[1]) == FALSE){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	print(paste("Input Files Not Found - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	quit(save="no")
}

if (CorrType == "pearson" || CorrType == "kendall" || CorrType == "Spearman"){
	print(paste("################################################"))
	print(paste("⚡⚡⚡",CorrType,"Correlations Will Be Executed ⚡⚡⚡"))
	print(paste("################################################"))
} else {
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
	print(paste("Type of Correlation Test Not Specified Correctly - Defaulting to Pearson Correlation"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
	CorrType="pearson"
}

############################################################
##### Coverting Input Files Into An Array For Analysis #####
############################################################

print("Transforming Input Files Into An Array")

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

print("Coverting Array Into Spreadsheet Consisting All NeuroImaging Data")

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
		NAME<-paste0(One,"x",Two,sep="")
		NAME<-gsub(" ","",NAME)
		names(SPREADSHEET)[x] <- NAME
	}
}

###################################################################################
##### Read In Covariate File To Merge with the Connectivity Data For Analysis #####
###################################################################################

print("Transforming Corvariates File and Merging with Neuroimaging Spreadsheet")

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

print("Preparing Variables of Interest For Analysis")

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
		print(paste("############################################"))
		print(paste("⚡⚡⚡",VarName,"Is Defined As", classtype,"⚡⚡⚡"))
		print(paste("############################################"))
	} else {
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
		print(paste("   ",VarName,"NOT FOUND - EXITING SCRIPT    "))
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
	}
}

######################################
##### Load Packages For Analysis #####
######################################

print("Loading Required Packages For Analysis and Visulizations")

suppressMessages(library(corrplot))
suppressMessages(library(lattice))
suppressMessages(library(ggplot2))
suppressMessages(library(ppcor))

##################################################
##### Execute Correlations and Linear Models #####
##################################################

print("Executing Analyses To Obtain R and P Values")

RvalRow<-dim(SPREADSHEET)[1]+1
PvalRow<-dim(SPREADSHEET)[1]+2
MainPredict<-Predictors[[1]][1]

if (MaxPredictors == 1){

	for (connection in 1:dim(SPREADSHEET)[2]){
		ConnNum<-dim(covaData)[2]+connection	
		ConnR<-suppressWarnings(cor.test(DATASET[,MainPredict],DATASET[,ConnNum], method=CorrType)$estimate)
		ConnP<-suppressWarnings(cor.test(DATASET[,MainPredict],DATASET[,ConnNum], method=CorrType)$p.value)
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
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]]), method=CorrType)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]]), method=CorrType)$p.value)
		}
		if (length(LIST)==4){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]]), method=CorrType)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]]), method=CorrType)$p.value)
		}
		if (length(LIST)==5){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]]), method=CorrType)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]]), method=CorrType)$p.value)
		}
		if (length(LIST)==6){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]]), method=CorrType)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]]), method=CorrType)$p.value)
		}
		if (length(LIST)==7){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]],LIST[[7]]), method=CorrType)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]],LIST[[7]]), method=CorrType)$p.value)
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

###################################################
##### Create Matrix of Data For Final Figures #####
###################################################

print("Constructing Matrices of Both R and P Values")

ConstructMatrix <- function(VALUES,COLUMNNAMES){
	MATRIX<-matrix(, nrow = length(COLUMNNAMES), ncol = length(COLUMNNAMES))
	colnames(MATRIX)<-COLUMNNAMES
	rownames(MATRIX)<-COLUMNNAMES
	if (length(VALUES) == length(COLUMNNAMES)^2){
		for (num in 1:length(VALUES)){
			VAL<-round(VALUES[[num]][1], digits = 3)
			HEADER<-names(VALUES[num])
			HEADER1<-strsplit(HEADER,"x", fixed = FALSE)[[1]][1]
			HEADER2<-strsplit(HEADER,"x", fixed = FALSE)[[1]][2]
			colh1<-which(colnames(MATRIX)== HEADER1)
			rowh2<-which(rownames(MATRIX)== HEADER2)
			MATRIX[colh1,rowh2]<-VAL
		}
	return(MATRIX)
	} else {
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
		print(paste("Matrix Values (",length(VALUES),") and Column Names (",length(COLUMNNAMES),") Are NOT Proportional - Exiting Script"))
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
		quit(save="no")
	}
}


Rmatrix<-ConstructMatrix(Rvals,ColumnNAMES)
Pmatrix<-ConstructMatrix(Pvals,ColumnNAMES)

###############################
##### Define Output Paths #####
###############################

print("Defining Output Paths To Store Output Files")

if (!exists("SubOutDir")){
	SubOutDir<-""
}

RESP<-basename(inputPath)
COVA<-basename(covaPath)
COVA<-gsub(".csv","",RESP)

DataSubDir<-paste0(OutDirRoot,"/Data/COVA-",COVA,"_RESP-",RESP,"/",SubOutDir,split="")
DataSubDir<-gsub(' ','',DataSubDir)
dir.create(file.path(DataSubDir), showWarnings = FALSE, recursive = TRUE, mode = "0775")

FigSubDir<-paste0(OutDirRoot,"/Figures/COVA-",COVA,"_RESP-",RESP,"/",SubOutDir,split="")
FigSubDir<-gsub(' ','',FigSubDir)
dir.create(file.path(FigSubDir), showWarnings = FALSE, recursive = TRUE, mode = "0775")

OutSubDir<-paste0(OutDirRoot,"/Results/COVA-",COVA,"_RESP-",RESP,"/",SubOutDir,split="")
OutSubDir<-gsub(' ','',OutSubDir)
dir.create(file.path(OutSubDir), showWarnings = FALSE, recursive = TRUE, mode = "0775")

################################################
##### Save Final SpreadSheet and Matricies #####
################################################

print("Save Final Output Dataset, Matricies and Figures")

Date<-format(Sys.time(), "%Y%m%d")
FileName<-gsub("~","",covsFormula)
FileName<-gsub("\\*", "and",FileName)

write.csv(DATASET, paste(DataSubDir,"/n",dim(DATASET)[1],"_",FileName,"_",Date,".csv", sep=''))
write.table(Rmatrix, file = paste(OutSubDir,"/n",dim(DATASET)[1],"_R-Matrix_",CorrType,"_",FileName,"_",Date,".mat", sep=''))
write.table(Pmatrix, file = paste(OutSubDir,"/n",dim(DATASET)[1],"_P-Matrix_",CorrType,"_",FileName,"_",Date,".mat", sep=''))

###############################
##### Save Matrix Figures #####
###############################

print(paste("###############################"))
print(paste("⚡⚡⚡ Script Ran Successfully ⚡⚡⚡"))
print(paste("###############################"))

pdf(paste(FigSubDir,"/n",dim(DATASET)[1],"_R-Matrix_",CorrType,"_",FileName,"_",Date,".pdf", sep=''),width=6,height=5,paper='special')
levelplot(Rmatrix, col.regions=heat.colors(100))
dev.off()

pdf(paste(FigSubDir,"/n",dim(DATASET)[1],"_P-Matrix_",CorrType,"_",FileName,"_",Date,".pdf", sep=''),width=6,height=5,paper='special')
levelplot(Pmatrix, col.regions=heat.colors(100))
dev.off()

Sys.chmod(list.files(path= DataSubDir, pattern="*", full.names = TRUE), mode = "0775")
Sys.chmod(list.files(path= FigSubDir, pattern="*", full.names = TRUE), mode = "0775")
Sys.chmod(list.files(path= OutSubDir, pattern="*", full.names = TRUE), mode = "0775")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
