#!/usr/bin/env Rscript
###################################################################################################
##########################                 GrangerDTI                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

print("Reading Arguments")

inputPath <- "/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/OLD/fmriprep/"
outputPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/"
tasks <- c("REST","AMG","HIPP")





auditfile=/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/Audit_Master_ConteMRI.csv
inputdir_DBK=/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-One-DBK
inputdir_One=/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-One
outdir=/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/T1w

covaPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Audits/90-Plus/RawData/RAVLTsubsetworking.csv"
covsFormula <- "~Age.at.Enrollment+RAVLT.Recognition.Correct.x"
ChangeType<-list("as.numeric")
CorrType="pearson"
OutDirRoot <- " /dfs2/yassalab/rjirsara/GrangerDTI"
SubOutDir="Preliminary"

##################################
##### Load Required Packages #####
##################################

print("Loading Required Packages")

library("devtools")
library("lattice")
library("ggplot2")

################################################################################
##### Transform Input Files Into Matricies and Combine Into A Single Array #####
################################################################################

for (task in tasks){

	print(paste0("Locating FMRIPREP Confounds TSV Files For Processing - ",task," Task"))
	InputExtension <- paste("_task-",task,"_desc-confounds_regressors.tsv", sep="")
	InputFiles = list.files(path = inputPath, pattern = InputExtension, full.names = TRUE, recursive=TRUE)
	if (file.exists(InputFiles[1]) == TRUE){
		MaxVolumesPossible<-0
		for (InFile in InputFiles){		
			subdata<-read.table(file = InFile, sep = '\t', header = TRUE)
			 if (nrow(subdata) > MaxVolumesPossible){
				MaxVolumesPossible<-nrow(subdata)
			}
		}
	} else {
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
		print(paste("Input Files Not Found - Exiting Script"))
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
		quit(save="no")
	}


	print(paste0("Organizing Subject-level Files Into Master Dataset For Analysis - ",task," Task"))
	OUTPUT<-data.frame(matrix(NA, nrow = 1, ncol = MaxVolumesPossible+12))
	colnames(OUTPUT) <- gsub("X", "V", colnames(OUTPUT))
	for (InFile in InputFiles){	
		FileName<-basename(InFile)
		FileName<-gsub(InputExtension,"",FileName)
		FileName<-strsplit(FileName[[1]][1] , "_")
		subdata<-read.table(file = InFile, sep = '\t', header = TRUE)
		subdata <- suppressWarnings(data.frame(lapply(subdata, function(x) as.numeric(as.character(x)))))

		sub<-strsplit(FileName[[1]][1], "-")[[1]][2]
		ses<-strsplit(FileName[[1]][2], "-")[[1]][2]
		fdMEAN<-summary(subdata$framewise_displacement)[4]
		fdSD<-sd(subdata$framewise_displacement,na.rm=TRUE)
		dvarsMEAN<-summary(subdata$framewise_displacement)[4]
		dvarsSD<-sd(subdata$framewise_displacement,na.rm=TRUE)
		gsMEAN<-summary(subdata$global_signal)[4]
		volTOTAL<-dim(subdata)[1]
		volAT20<-length(which(subdata$framewise_displacement < 0.20))
		volAT30<-length(which(subdata$framewise_displacement < 0.30))
		volAT40<-length(which(subdata$framewise_displacement < 0.40))
		volAT50<-length(which(subdata$framewise_displacement < 0.50))

		newrow<-c(sub,ses,fdMEAN,fdSD,dvarsMEAN,dvarsSD,gsMEAN,volTOTAL,volAT20,volAT30,volAT40,volAT50,subdata$framewise_displacement)
		newrow<-as.data.frame(t(as.data.frame(newrow)))
		rbind.all.columns <- function(x, y) {
 			x.diff <- setdiff(colnames(x), colnames(y))
			y.diff <- setdiff(colnames(y), colnames(x))
 			x[, c(as.character(y.diff))] <- NA
 			y[, c(as.character(x.diff))] <- NA
 			return(rbind(x, y))
		}
		OUTPUT<-rbind.all.columns(OUTPUT, newrow)
	}

	print(paste0("Cleaning Master Dataset For Figures of QA Data - ",task," Task"))
	names(OUTPUT) <- c("sub","ses","fdMEAN","fdSD","dvarsMEAN","dvarsSD","gsMEAN","volTOTAL","volAT20","volAT30","volAT40","volAT50")
	OUTPUT <- suppressWarnings(data.frame(lapply(OUTPUT, function(x) as.numeric(as.character(x)))))
	OUTPUT<-OUTPUT[-c(1),]

#################################################################
##### Create Ouput Directories and Define Output File Names #####
#################################################################

	OutRoot<-paste0(outputPath,task,"/")
	suppressWarnings(dir.create(OutRoot, recursive=TRUE))
	setwd(outputPath)

	QAFigure<-file.path(paste0(OutRoot,"n",nrow(OUTPUT),"_Temporal-Censoring_volmax-",MaxVolumesPossible,"_task-",task,".pdf"))
	QADataset<-paste0(OutRoot,"n",nrow(OUTPUT),"_Temporal-Censoring_volmax-",MaxVolumesPossible,"_task-",task,".csv")

	VolumesFigure<-paste0(OutRoot,"n",nrow(OUTPUT),"_Quality-Assurance_volmax-",MaxVolumesPossible,"_task-",task,".pdf")
	VolumesDataset<-paste0(OutRoot,"n",nrow(OUTPUT),"_Quality-Assurance_volmax-",MaxVolumesPossible,"_task-",task,".csv")

##################################################################################
##### Create Figure of Subject-Level Distributions of Framewise Displacement #####
##################################################################################

	VOLUMES<-t(OUTPUT[,c(13:ncol(OUTPUT))])
	subjects<-unlist(OUTPUT[,c(1)]) 
	sessions<-unlist(OUTPUT[,c(2)])
	for (subnum in 1:nrow(OUTPUT)){
		identifier<-paste0(subjects[subnum],"x",sessions[subnum])
		colnames(VOLUMES)[subnum]<-identifier
	}
	pdf(file=QAFigure)
	boxplot(VOLUMES[,c(1:nrow(OUTPUT))],
		main = paste("Subject-Level Distributions of Head Motion for",task,"Task"),
		ylab = "Framewise Displacement",
		xlab = "Scan Sessions",
		col = "gray",
		border = "black",
		lwd = 1.5)  
		abline(h = 0.50, col = "red", lwd = 2.5)
	dev.off()






> dev.copy(png,'myplot.png')
> dev.off()

pdf(paste(FigSubDir,"/n",dim(DATASET)[1],"_R-Matrix_",CorrType,"_",FileName,"_",Date,".pdf", sep=''),width=6,height=5,paper='special')
levelplot(Rmatrix, col.regions=heat.colors(100))
dev.off()



	
ddf = data.frame(NUMS = rnorm(500), GRP = sample(LETTERS[1:5],500,replace=T))

boxplot(NUMS ~ GRP, data = ddf, lwd = 2, ylab = 'NUMS')

spreadPointsMultiple(data=ddf, responseColumn="NUMS", categoriesColumn="GRP",
                     col="blue", plotOutliers=TRUE)








############################################################
##### Plot Histograms Of ARI while Differentiating Sex #####
############################################################
library(ggplot2)

dist_normal<-ggplot(rds, aes(TP2_ari_total, fill = TP2_sex)) + geom_histogram(binwidth = 1) + scale_color_grey() + scale_fill_grey(start=.7, end=.3) + theme_classic() + theme(legend.position="top")

dist_log<-ggplot(rds, aes(TP2_ari_log, fill = TP2_sex)) + geom_histogram(binwidth = .5) + scale_color_grey() + scale_fill_grey(start=.7, end=.3) + theme_classic() + theme(legend.position="top")

ggplot(rds, aes(TP2_ari_log, fill = veg)) + 
   geom_histogram(alpha = 0.5, aes(y = ..density..), position = 'identity')

###########################################
##### Plot Histograms Of ARI Together #####
###########################################

p1<-hist(rds$TP2_ari_total)
p2<-hist(rds$TP2_ari_log)
plot( p1, col=rgb(0.0,0.5,1.0,0.3), xlim=c(0,12))
plot(p2, col=rgb(0.0,0.3,0.7,0.3), xlim=c(0,12), add=T)


############





###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
