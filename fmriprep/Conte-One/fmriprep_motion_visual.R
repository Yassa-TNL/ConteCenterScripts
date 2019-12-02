#!/usr/bin/env Rscript
###################################################################################################
##########################                 GrangerDTI                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

print("Reading Arguments")

inputPath <- "/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One/fmriprep/"
outputPath <- "/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/"
ALLTASKS <- c("REST","HIPP","AMG")

##################################
##### Load Required Packages #####
##################################

print("Loading Required Packages")

library("reshape2")
library("devtools")
library("lattice")
library("ggplot2")

################################################################
##### If Not Specified Find All Task Names To Be Processed #####
################################################################

if (!exists("ALLTASKS") || length(ALLTASKS) == 0){
	print(paste0("Searching For Data To Be Processed"))
	ALLFILES<-unlist(strsplit(list.files(path = inputPath, include.dirs=FALSE, pattern = ".tsv", recursive=TRUE), '_'))
	ALLTASKS<-grep("task-",ALLFILES)
	ALLTASKS<-unique(ALLFILES[TaskNamesOnly<-grep("task-",ALLFILES)])
	ALLTASKS<-gsub("task-", "",ALLTASKS)
}

################################################################################
##### Transform Input Files Into Matricies and Combine Into A Single Array #####
################################################################################

for (task in ALLTASKS){

	print(paste0("##########################################"))
	print(paste0("Now Processing Data From the ",task," Task"))
	print(paste0("##########################################"))

	print(paste0("Locating FMRIPREP Confounds TSV Files For Processing"))
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

	print(paste0("Organizing Subject-level Files Into Master Dataset For Analysis"))
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
		volAT40<-length(which(subdata$framewise_displacement < 0.40))
		volAT60<-length(which(subdata$framewise_displacement < 0.60))
		volAT80<-length(which(subdata$framewise_displacement < 0.80))

		newrow<-c(sub,ses,fdMEAN,fdSD,dvarsMEAN,dvarsSD,gsMEAN,volTOTAL,volAT20,volAT40,volAT60,volAT80,subdata$framewise_displacement)
		newrow<-as.data.frame(t(as.data.frame(newrow)))
		rbind.all.columns <- function(x, y){
 			x.diff <- setdiff(colnames(x), colnames(y))
			y.diff <- setdiff(colnames(y), colnames(x))
 			x[, c(as.character(y.diff))] <- NA
 			y[, c(as.character(x.diff))] <- NA
 			return(rbind(x, y))
		}
		OUTPUT<-rbind.all.columns(OUTPUT, newrow)
	}

	print(paste0("Cleaning Master Dataset For Figures of QA Data"))
	names(OUTPUT) <- c("sub","ses","fdMEAN","fdSD","dvarsMEAN","dvarsSD","gsMEAN","volTOTAL","volAT20","volAT40","volAT60","volAT80")
	OUTPUT <- suppressWarnings(data.frame(lapply(OUTPUT, function(x) as.numeric(as.character(x)))))
	OUTPUT<-OUTPUT[-c(1),]

#################################################################
##### Create Ouput Directories and Define Output File Names #####
#################################################################

	print(paste0("Defining Output File Names and Paths"))
	OutRoot<-paste0(outputPath,task,"/")
	suppressWarnings(dir.create(OutRoot, recursive=TRUE))
	setwd(outputPath)

	SubjectFD<-paste0(OutRoot,"n",nrow(OUTPUT),"_Subject-FD-Boxplots_volmax-",MaxVolumesPossible,"_task-",task,".pdf")
	GroupFD<-paste0(OutRoot,"n",nrow(OUTPUT),"_Group-FD-Distribution_volmax-",MaxVolumesPossible,"_task-",task,".pdf")
	SubjectVols<-paste0(OutRoot,"n",nrow(OUTPUT),"_Despiking-Volumes_volmax-",MaxVolumesPossible,"_task-",task,".pdf")

	QADataset<-paste0(OutRoot,"n",nrow(OUTPUT),"_Quality-Assurance_volmax-",MaxVolumesPossible,"_task-",task,".csv")
	VolumesDataset<-paste0(OutRoot,"n",nrow(OUTPUT),"_Volumes-Within-Timeseries_volmax-",MaxVolumesPossible,"_task-",task,".csv")

#######################################################################################
##### Create Scatterplot of Subject-Level Distributions of Framewise Displacement #####
#######################################################################################

	print(paste0("Creating Figure of Subject-Level Distributions of FD"))
	VOLUMES<-t(OUTPUT[,c(13:ncol(OUTPUT))])
	CONCAT<-melt(VOLUMES, id.vars=1)
	MEAN<-round(summary(CONCAT$value)[4], digits = 3)
	SD<-round(sd(CONCAT$value, na.rm=TRUE), digits = 3)
	subjects<-unlist(OUTPUT[,c(1)]) 
	sessions<-unlist(OUTPUT[,c(2)])
	for (subnum in 1:nrow(OUTPUT)){
		identifier<-paste0(subjects[subnum],"x",sessions[subnum])
		colnames(VOLUMES)[subnum]<-identifier
	}

	pdf(file=SubjectFD)
	boxplot(VOLUMES[,c(1:nrow(OUTPUT))],
		main = paste("Subject-Level Distributions of Head Motion for",task,"Task"),
		ylab = "Framewise Displacement",
		xlab = "Scan Sessions",
		col = "gray",
		border = "black",
		lwd = 1.5)
		mtext(paste0("Mean = ",MEAN,", Stardard Deviation =",SD), side=3)
		abline(h = c(0.2,0.4,0.6,0.8), col = c("yellow3","springgreen3","steelblue2","plum1"), lwd = 2)
	dev.off()

##################################################################
##### Create Group-Level Histogram of Framewise Displacement #####
##################################################################

	print(paste0("Creating Figure of Group-Level Distributions of FD"))
	Remain20<-round(length(which(CONCAT$value < 0.20))/length(CONCAT$value)*100)
	Remain40<-round(length(which(CONCAT$value < 0.40))/length(CONCAT$value)*100)
	Remain60<-round(length(which(CONCAT$value < 0.60))/length(CONCAT$value)*100)
	Remain80<-round(length(which(CONCAT$value < 0.80))/length(CONCAT$value)*100)

	pdf(file=GroupFD)
	hist(CONCAT$value, 
		breaks=7500,
		xlim=c(0,SD*10+MEAN),
		main = paste("Head Motion Distribution of Sample for",task,"Task"),
		ylab = "Counts",
		xlab = "Framewise Displacement",)
		mtext(paste0("Volumes Remaining at 0.20=",Remain20,"% 0.40=",Remain40,"% 0.60=",Remain60,"% 0.80=",Remain80,"%"), side=3)
		abline(v = c(0.2,0.4,0.6,0.8), col = c("yellow3","springgreen3","steelblue2","plum1"), lwd = 2.5)
	dev.off()

###########################################################################
##### Create Subject-Level Histograms At Muliple Despiking Thresholds #####
###########################################################################

	print(paste0("Creating Figure of Despiking at Multiple Thresholds"))
	HISTOGRAMS<-data.frame(matrix(NA, nrow = 0, ncol = 2))
	for (subnum in 1:nrow(OUTPUT)){
		identifier<-paste0(subjects[subnum],"x",sessions[subnum])
		volnumsTOTAL<-data.frame(matrix("None", nrow = OUTPUT[subnum,"volTOTAL"], ncol = 1))
		volnumsAT20<-data.frame(matrix("0.20", nrow = OUTPUT[subnum,"volAT20"], ncol = 1))
		volnumsAT40<-data.frame(matrix("0.40", nrow = OUTPUT[subnum,"volAT40"], ncol = 1))
		volnumsAT60<-data.frame(matrix("0.60", nrow = OUTPUT[subnum,"volAT60"], ncol = 1))
		volnumsAT80<-data.frame(matrix("0.80", nrow = OUTPUT[subnum,"volAT80"], ncol = 1))
		DESPIKE<-rbind(volnumsTOTAL, setNames(rev(volnumsAT80), names(volnumsTOTAL)))
		DESPIKE<-rbind(DESPIKE, setNames(rev(volnumsAT60), names(DESPIKE)))
		DESPIKE<-rbind(DESPIKE, setNames(rev(volnumsAT40), names(DESPIKE)))
		DESPIKE<-rbind(DESPIKE, setNames(rev(volnumsAT20), names(DESPIKE)))
		DESPIKE$subid<-identifier
		HISTOGRAMS<-rbind(HISTOGRAMS, setNames(rev(DESPIKE), names(DESPIKE)))
	}
	colnames(HISTOGRAMS)[1]<-"threshold"


	ggplot(HISTOGRAMS, aes(HISTOGRAMS[,1], fill = HISTOGRAMS[,2])) +
		ggtitle(paste("Volumes After Framewise Displacement Despiking For",task,"Task")) +
		xlab("Scan Sessions") +
		ylab("Total Number of Volumes") +
		labs(fill = "Motion Threshold (FD):") +
		geom_bar(position = "identity", alpha = .4) +
  		theme(axis.title.x=element_text(size = rel(1.25),face = "bold"),
		axis.text.x=element_blank(),
		axis.title.y = element_text(size = rel(1.25),face = "bold"),
		plot.title = element_text(size = rel(1.25),face = "bold"),
		panel.background = element_rect(fill = "white", colour = "black"),
		legend.position = "top")
	ggsave(file=SubjectVols,device = "pdf",width = 14, height = 7, units = c("in"))

#########################################################################
##### Save Datasets of QA Data To Include As Covaraites In Analyses #####
#########################################################################

	print(paste0("Saving Processed Datasets For Subsequent Analyses"))
	FINAL<-OUTPUT[,c(1:12)]
	write.csv(FINAL, QADataset)
	write.csv(VOLUMES,VolumesDataset)
	Sys.chmod(list.files(path= OutRoot, pattern="*", full.names = TRUE), mode = "0775")
}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
