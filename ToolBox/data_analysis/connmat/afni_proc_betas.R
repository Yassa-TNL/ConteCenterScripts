#!/usr/bin/env Rscript
######################

ConnMat <- function(FCON_COLS, IN_CSV, DIR_OUT, FORMULA, CORR_TYPE="pearson", CHANGE_CLASS = NULL, DIR_SUBOUT = NULL , VARS_INTEREST = NULL){

if( missing("FCON_COLS") | missing("IN_CSV") | missing("DIR_OUT") | missing("FORMULA")){
	cat('\n')
	cat(" Usage:",'\n')
	cat('\n')
	cat("This script takes in a dataset containing demographic and functional connectivity data from AFNI_Proc.py")
	cat("If input files are correctly entered it will restructure the data for group-level comparisons ")
	cat("then output correlation and p-value matrices based on the defined model.",'\n')
	cat('\n')
	cat(" Required Arguments:",'\n')
	cat('\n')
	cat("FCON_COLS: Range of Column Numbers Defining the Fcon Beta Vars with Deliminiter 'x' (Exp: Region1xRegion2)",'\n')
	cat("IN_CSV: Path to CSV dataset storing demographic, clinical, or other variables for analysis",'\n')
	cat("DIR_OUT: Path for where to output the processed data. Reccomendation: Keep constant for each project.",'\n')
	cat("FORMULA: Univariate or multivariate Model to be Analyzed. Ensure variables match headers within IN_CSV dataset",'\n')
	cat('\n')
	cat(" Optional Arguments:",'\n')
	cat('\n')
	cat("CORR_TYPE: Type Of correlation. Options: pearson vs kendall vs Spearman ",'\n')
	cat("CHANGE_CLASS: Change class for each variable defined in model respectively",'\n')
	cat("DIR_SUBOUT: Add sub-directory in output path for more organization",'\n')
	cat("VARS_INTEREST: A string of column names to keep from analysis",'\n')
	cat('\n')
	cat(" Call Example on HPC:",'\n')
	cat('\n')
	cat('ConnMat(FCON_COLS=, IN_CSV="/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/MarquezEPI/Results/COVA-ADRC_ConnMat_Betas/ADRC_ConnMat_Betas.csv", DIR_OUT="/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/MarquezEPI/Results/COVA-ADRC_ConnMat_Betas", FORMULA="~ravlt_A7+Age", CORR_TYPE="pearson", CHANGE_CLASS=list("as.numeric","as.numeric"), VARS_INTEREST=c("EC","PRC","MPFC","ACC"))','\n')
	cat('\n')
	cat('\n')
	stop("Required Input Arguments Not Given") 
}

##########################################################################
##### Read In The Dataset and Define Functional Connectivity Columns #####
##########################################################################

print("Transforming Corvariates File and Merging with Neuroimaging Spreadsheet")

if (file.exists(IN_CSV[1]) == FALSE){
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
	print(paste("Covariates Files Not Found - Exiting Script"))
	print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ !"))
	stop("Script Stopped Because of Fatal Error Above")
}

DATASET <- read.csv(IN_CSV)
names(DATASET)[1]<- "Subject.ID"
FCON_NAMES<-names(DATASET)[FCON_COLS]
SPREADSHEET<-DATASET[,FCON_NAMES]

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
		if (length(CHANGE_CLASS) == MaxPredictors){
			Type<-CHANGE_CLASS[[VarNum]][1]
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
		ConnName<-names(SPREADSHEET)[connection]	
		ConnR<-suppressWarnings(cor.test(DATASET[,MainPredict],DATASET[,ConnName], method=CORR_TYPE)$estimate)
		ConnP<-suppressWarnings(cor.test(DATASET[,MainPredict],DATASET[,ConnName], method=CORR_TYPE)$p.value)
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
		ConnName<-names(SPREADSHEET)[connection]
		LIST=vector(mode = "list", length = MaxPredictors+1)
		LIST[[1]]<-DATASET[,MainPredict]
		LIST[[2]]<-DATASET[,ConnName]
		for (PredictNum in 2:MaxPredictors){
			PredictName<-Predictors[[1]][PredictNum]
			LIST[[PredictNum+1]]<-DATASET[,PredictName]
		}
		if (length(LIST)==3){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]]), method=CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]]), method=CORR_TYPE)$p.value)
		}
		if (length(LIST)==4){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]]), method=CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]]), method=CORR_TYPE)$p.value)
		}
		if (length(LIST)==5){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]]), method=CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]]), method=CORR_TYPE)$p.value)
		}
		if (length(LIST)==6){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]]), method=CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]]), method=CORR_TYPE)$p.value)
		}
		if (length(LIST)==7){
			ConnR<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]],LIST[[7]]), method=CORR_TYPE)$estimate)
			ConnP<-suppressWarnings(pcor.test(LIST[[1]],LIST[[2]],c(LIST[[3]],LIST[[4]],LIST[[5]],LIST[[6]],LIST[[7]]), method=CORR_TYPE)$p.value)
		}
		if (length(LIST)>7){
			print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡"))
			print(paste("Need To Edit Script Before Analyzing This Much Variables:",length(LIST),"- Exiting Script"))
			print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡"))
			stop("Script Stopped Because of Fatal Error Above")
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
	if (length(VALUES) != length(COLUMNNAMES)^2){
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
		print(paste("Matrix Values (",length(VALUES),") and Column Number (",length(COLUMNNAMES),") are NOT Proportional "))
		print(paste("This is not a fatal error, but the matricies will likely contain missing values                     "))
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! "))
	}
	for (num in 1:length(VALUES)){
		VAL<-round(VALUES[[num]][1], digits = 3)
		HEADER<-names(VALUES[num])
		HEADER1<-strsplit(HEADER,"x", fixed = FALSE)[[1]][1]
		HEADER2<-strsplit(HEADER,"x", fixed = FALSE)[[1]][2]
		colh1<-which(colnames(MATRIX)== HEADER1)
		rowh2<-which(rownames(MATRIX)== HEADER2)
		MATRIX[colh1,rowh2]<-VAL
	}
	for (num in 1:length(MAT_NAMES)){
		MATRIX[num,num]<-NA
	}
	return(MATRIX)
}

MAT_NAMES<-unique(unlist(strsplit(names(SPREADSHEET),'x')))
Rmatrix<-ConstructMatrix(Rvals,MAT_NAMES)
Pmatrix<-ConstructMatrix(Pvals,MAT_NAMES)

if (!is.null(VARS_INTEREST) && length(VARS_INTEREST) > 0){
	VarNumInterest<-suppressWarnings(which(rownames(Rmatrix) == VARS_INTEREST))
	Rmatrix<-Rmatrix[VarNumInterest,VarNumInterest]
	Pmatrix<-Pmatrix[VarNumInterest,VarNumInterest]
}

###############################
##### Define Output Paths #####
###############################

print("Defining Output Paths To Store Output Files")

if (!exists("DIR_SUBOUT") && is.null(DIR_SUBOUT)){
	DIR_SUBOUT<-""
}

COVA<-basename(IN_CSV)
COVA<-gsub(".csv","",COVA)
DataSubDir<-paste0(DIR_OUT,"/Results/COVA-",COVA,"/",DIR_SUBOUT,split="")
DataSubDir<-gsub(' ','',DataSubDir)
dir.create(file.path(DataSubDir), showWarnings = FALSE, recursive = TRUE, mode = "0775")

################################################
##### Save Final SpreadSheet and Matricies #####
################################################

print("Save Final Output Dataset, Matricies and Figures")

Date<-format(Sys.time(), "%Y%m%d")
FileName<-gsub("~","",FORMULA)
FileName<-gsub("\\*", "and",FileName)

write.csv(DATASET, paste(DataSubDir,"/n",dim(DATASET)[1],"_",FileName,"_",Date,".csv", sep=''))
write.csv(Pmatrix, paste(DataSubDir,"/n",dim(DATASET)[1],"_P-Matrix_",FileName,"_",Date,".csv", sep=''))
write.csv(Rmatrix, paste(DataSubDir,"/n",dim(DATASET)[1],"_R-Matrix-",CORR_TYPE,"_",FileName,"_",Date,".csv", sep=''))

###############################
##### Save Matrix Figures #####
###############################

print(paste("#########################"))
print(paste(" Script Ran Successfully "))
print(paste("#########################"))

pdf(paste(DataSubDir,"/n",dim(DATASET)[1],"_R-Matrix_",CORR_TYPE,"_",FileName,"_",Date,".pdf", sep=''),width=6,height=5,paper='special')
levelplot(Rmatrix,col.regions = colorRampPalette(c('darkblue','blue','lightblue','white','orange','orangered','darkred'))(100000), xlab="Nodes",ylab="Nodes",)
dev.off()

pdf(paste(DataSubDir,"/n",dim(DATASET)[1],"_P-Matrix_",CORR_TYPE,"_",FileName,"_",Date,".pdf", sep=''),width=6,height=5,paper='special')
levelplot(Pmatrix,col.regions = colorRampPalette(c('darkblue','blue','lightblue','white','orange','orangered','darkred'))(100000), xlab="Nodes",ylab="Nodes",)
dev.off()

Sys.chmod(list.files(path= DataSubDir, pattern="*", full.names = TRUE), mode = "0775")

}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
