#!/usr/bin/env Rscript
######################

ConnMat <- function(DIR_RESPONCE_PATH,DIR_COVARIATE_PATH,DIR_OUTPUT_PATH,FORMULA,OPT_CORR_TYPE,OPT_CHANGE_TYPE,OPT_SUBDIR_PATH,OPT_VARS_OF_INTEREST){

################################################################################
##### Transform Input Files Into Matricies and Combine Into A Single Array #####
################################################################################

print("Checking Input Arguments Are Correctly Formatted")

InputFiles = list.files(path= DIR_RESPONCE_PATH,pattern="*.txt", full.names = TRUE)
MaxSubject<-length(InputFiles)

if (file.exists(InputFiles[1]) == FALSE){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	print(paste("Input Files Not Found - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
	quit(save="no")
}

if (OPT_CORR_TYPE == "pearson" || OPT_CORR_TYPE == "kendall" || OPT_CORR_TYPE == "Spearman"){
	print(paste("#######################################"))
	print(paste(OPT_CORR_TYPE,"Correlations Will Be Executed "))
	print(paste("#######################################"))
} else {
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
	print(paste("Type of Correlation Test Not Specified Correctly - Defaulting to Pearson Correlation"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
	OPT_CORR_TYPE="pearson"
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
	MATRIX<-as.matrix(DATASETRefined[c(ColumnNameRow:dim(DATASETRefined)[1]),c(ColumnNameRow:dim(DATASETRefined)[1])])
	ColumnNAMES<-list(DATASETRefined[1,-c(1)])
	if (!is.null(OPT_VARS_OF_INTEREST) && length(OPT_VARS_OF_INTEREST) > 0){
		VarNumInterest<-which(ColumnNAMES[[1]] %in% OPT_VARS_OF_INTEREST)
		MATRIX<-as.matrix(DATASETRefined[VarNumInterest,VarNumInterest])
		ColumnNAMES<-list(ColumnNAMES[[1]][VarNumInterest])	
	}
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
ColumnNAMES<-ColumnNAMES[[1]]

if (length(ColumnNAMES)^2 != dim(SPREADSHEET)[2]){
	print(paste0("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡"))
	print(paste0("Column Names (",length(ColumnNAMES)^2,") and Number of Columns (",dim(SPREADSHEET)[2],") Are Not Equal - Exiting Script"))
	print(paste0("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !  ! ⚡ ! ⚡ ! ⚡ "))
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

if (file.exists(DIR_COVARIATE_PATH[1]) == FALSE){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
	print(paste("Covariates Files Not Found - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
	quit(save="no")
}

covaData <- read.csv(DIR_COVARIATE_PATH)
covaData$NeuroID<-0
covaData$X<-NULL
names(covaData)[1]<- "Subject.ID"

for (Subject in 1:MaxSubject){
	SUBID<-unlist(strsplit(basename(InputFiles[Subject]), "left"))[1]
	SUBID<-unlist(strsplit(SUBID, "right"))[1]
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

Predictors<-gsub("~", "",FORMULA)
Predictors<-gsub("\\*", "+",Predictors)
Predictors<-strsplit(Predictors, "+", fixed = TRUE)
MaxPredictors<-dim(as.data.frame(Predictors))[1]

for (VarNum in 1:MaxPredictors){
	VarName<-as.character(as.data.frame(Predictors)[[1]][VarNum])
	if (VarName %in% colnames(DATASET)){
		if (length(OPT_CHANGE_TYPE) == MaxPredictors){
			Type<-OPT_CHANGE_TYPE[[VarNum]][1]
			DATASET[,VarName]<-suppressWarnings(unlist(lapply(as.character(DATASET[,VarName]), Type)))
		}	
		DATASET<-DATASET[complete.cases(DATASET[,VarName]),]
		classtype<-class(DATASET[,VarName])		
		print(paste("#################################"))
		print(paste(VarName,"Is Defined As", classtype ))
		print(paste("#################################"))
	} else {
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
		print(paste("   ",VarName,"NOT FOUND - EXITING SCRIPT   "))
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
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
		ConnR<-suppressWarnings(cor.test(DATASET[,MainPredict],DATASET[,ConnNum], method=OPT_CORR_TYPE)$estimate)
		ConnP<-suppressWarnings(cor.test(DATASET[,MainPredict],DATASET[,ConnNum], method=OPT_CORR_TYPE)$p.value)
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
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]]), method=OPT_CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]]), method=OPT_CORR_TYPE)$p.value)
		}
		if (length(LIST)==4){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]]), method=OPT_CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]]), method=OPT_CORR_TYPE)$p.value)
		}
		if (length(LIST)==5){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]]), method=OPT_CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]]), method=OPT_CORR_TYPE)$p.value)
		}
		if (length(LIST)==6){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]]), method=OPT_CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]]), method=OPT_CORR_TYPE)$p.value)
		}
		if (length(LIST)==7){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]],LIST[[7]]), method=OPT_CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]],LIST[[7]]), method=OPT_CORR_TYPE)$p.value)
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

if (!exists("OPT_SUBDIR_PATH")){
	OPT_SUBDIR_PATH<-""
}

RESP<-basename(DIR_RESPONCE_PATH)
COVA<-basename(DIR_COVARIATE_PATH)
COVA<-gsub(".csv","",COVA)

DataSubDir<-paste0(DIR_OUTPUT_PATH,"/Data/COVA-",COVA,"_RESP-",RESP,"/",OPT_SUBDIR_PATH,split="")
DataSubDir<-gsub(' ','',DataSubDir)
dir.create(file.path(DataSubDir), showWarnings = FALSE, recursive = TRUE, mode = "0775")

FigSubDir<-paste0(DIR_OUTPUT_PATH,"/Figures/COVA-",COVA,"_RESP-",RESP,"/",OPT_SUBDIR_PATH,split="")
FigSubDir<-gsub(' ','',FigSubDir)
dir.create(file.path(FigSubDir), showWarnings = FALSE, recursive = TRUE, mode = "0775")

OutSubDir<-paste0(DIR_OUTPUT_PATH,"/Results/COVA-",COVA,"_RESP-",RESP,"/",OPT_SUBDIR_PATH,split="")
OutSubDir<-gsub(' ','',OutSubDir)
dir.create(file.path(OutSubDir), showWarnings = FALSE, recursive = TRUE, mode = "0775")

################################################
##### Save Final SpreadSheet and Matricies #####
################################################

print("Save Final Output Dataset, Matricies and Figures")

Date<-format(Sys.time(), "%Y%m%d")
FileName<-gsub("~","",FORMULA)
FileName<-gsub("\\*", "and",FileName)

write.csv(DATASET, paste(DataSubDir,"/n",dim(DATASET)[1],"_",FileName,"_",Date,".csv", sep=''))
write.csv(Pmatrix, paste(OutSubDir,"/n",dim(DATASET)[1],"_P-Matrix_",FileName,"_",Date,".csv", sep=''))
write.csv(Rmatrix, paste(OutSubDir,"/n",dim(DATASET)[1],"_R-Matrix-",OPT_CORR_TYPE,"_",FileName,"_",Date,".csv", sep=''))

###############################
##### Save Matrix Figures #####
###############################

print(paste("#########################"))
print(paste(" Script Ran Successfully "))
print(paste("#########################"))

pdf(paste(FigSubDir,"/n",dim(DATASET)[1],"_R-Matrix_",OPT_CORR_TYPE,"_",FileName,"_",Date,".pdf", sep=''),width=6,height=5,paper='special')
levelplot(Rmatrix, col.regions=heat.colors(100))
dev.off()

pdf(paste(FigSubDir,"/n",dim(DATASET)[1],"_P-Matrix_",OPT_CORR_TYPE,"_",FileName,"_",Date,".pdf", sep=''),width=6,height=5,paper='special')
levelplot(Pmatrix, col.regions=heat.colors(100))
dev.off()

Sys.chmod(list.files(path= DataSubDir, pattern="*", full.names = TRUE), mode = "0775")
Sys.chmod(list.files(path= FigSubDir, pattern="*", full.names = TRUE), mode = "0775")
Sys.chmod(list.files(path= OutSubDir, pattern="*", full.names = TRUE), mode = "0775")

}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
