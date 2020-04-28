#! /usr/bin/env Rscript
#$ -q yassalab,free*
#$ -pe openmp 1-4
#$ -R y
#$ -ckpt restart
################

print("Reading Arguments")

args <- commandArgs(trailingOnly=TRUE)
DIR_LOCAL_APPS = args[1]
DIR_LOCAL_DATA = args[2]

###############################################
##### Find All Task Names To Be Processed #####
###############################################

print(paste0("Searching For Data To Be Processed"))

INPUTFILES<-list.files(path = paste0(DIR_LOCAL_APPS,"/fmriprep"), full.names=TRUE, pattern = "_desc-confounds_regressors.tsv", recursive=TRUE)
ALLTASKS<-gsub("task-","",unique(unlist(strsplit(INPUTFILES, '_'))[grep("task-",unlist(strsplit(INPUTFILES, '_')))]))
ALLSCANS=as.character(ALLTASKS)
setwd(DIR_LOCAL_DATA)

for (task in ALLTASKS){
	if(length(grep("_run-",INPUTFILES[grep(task,INPUTFILES)])) != 0){
		RUNS<-unlist(strsplit(INPUTFILES[grep(task,INPUTFILES)],"_"))
		RUNS<-gsub("run-","",unique(RUNS[grep("run-",RUNS)]))
		for (run in RUNS){
			ALLSCANS<-append(ALLSCANS,paste0(task,"_",run))
		}
		ALLSCANS[which(ALLSCANS %in% task)]<-paste0(task,"_concat")
	}
}

##################################
##### Load Required Packages #####
##################################

print("Loading Required Packages")

rbind.all.columns <- function(x, y){
 	x.diff <- setdiff(colnames(x), colnames(y))
	y.diff <- setdiff(colnames(y), colnames(x))
	x[, c(as.character(y.diff))] <- NA
	y[, c(as.character(x.diff))] <- NA
 	return(rbind(x, y))
}

suppressMessages(require(RColorBrewer))
suppressMessages(require(reshape2))
suppressMessages(require(devtools))
suppressMessages(require(lattice))
suppressMessages(require(ggplot2))
suppressMessages(require(cowplot))

################################################################################
##### Transform Input Files Into Matricies and Combine Into A Single Array #####
################################################################################

for (task in ALLSCANS){
	print(paste0("##########################################"))
	print(paste0("Now Processing Data From the ",task," Task"))
	print(paste0("##########################################"))
	print(paste0("Locating FMRIPREP Confounds TSV Files For Processing"))
	if (!grepl("_", task)){
		TASKFILES<-INPUTFILES[grep(paste0("task-",task),INPUTFILES)]
		TASKFILES<-TASKFILES[!grepl("problematic",TASKFILES)]
	} else if (grepl("_concat", task)){
		TASKFILES<-INPUTFILES[grep(paste0("task-",unlist(strsplit(task,"_"))[1]),INPUTFILES)]
		TASKFILES<-TASKFILES[!grepl("problematic",TASKFILES)]
	} else {
		TASKFILES<-INPUTFILES[grep(paste0("task-",unlist(strsplit(task,"_"))[1]),INPUTFILES)]
		TASKFILES<-TASKFILES[!grepl("problematic",TASKFILES)]
		TASKFILES<-TASKFILES[grepl(paste0("_run-",unlist(strsplit(task,"_"))[2]),TASKFILES)]
	}
	print(paste0("Determining the Max Number of Volumes"))
	if (file.exists(TASKFILES[1]) == TRUE){
		MaxVolumesPossible<-0
		for (FILE in TASKFILES){		
			CONTENT<-read.table(file = FILE, sep = '\t', header = TRUE)
			if (nrow(CONTENT) > MaxVolumesPossible){
				MaxVolumesPossible<-nrow(CONTENT)
			}
		}
	} else {
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
		print(paste("Input Files Not Found - Exiting Script"))
		print(paste("⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ ! ⚡ "))
		quit(save="no")
	}

	print(paste0("Organizing Subject-level Files Into Master Dataset For Analysis"))
	OUTPUT<-data.frame(matrix(NA, nrow = 1, ncol = 12+MaxVolumesPossible))
	colnames(OUTPUT) <- gsub("X", "V", colnames(OUTPUT))

	for (DIR_INPUT in unique(dirname(TASKFILES))){
		CONTENT<-data.frame("")
		colnames(CONTENT) <- gsub("X", "V", colnames(CONTENT))
		for (FILE in TASKFILES[grep(DIR_INPUT, TASKFILES)]){
			TEMP<-read.table(file = FILE, sep = '\t', header = TRUE)
			TEMP<-suppressWarnings(data.frame(lapply(TEMP, function(x) as.numeric(as.character(x)))))
			CONTENT<-rbind.all.columns(CONTENT,TEMP)
		}
		CONTENT<-CONTENT[-c(1),]
		FileName<-basename(FILE)
		SUB<-gsub("sub-","",unlist(strsplit(FileName, "_"))[grep("sub-",unlist(strsplit(FileName, "_")))])
		SES<-gsub("ses-","",unlist(strsplit(FileName, "_"))[grep("ses-",unlist(strsplit(FileName, "_")))])
		if (length(SES) == 0){			
			SES<-"NA"
		}
		fdMEAN<-summary(CONTENT$framewise_displacement)[4]
		fdSD<-sd(CONTENT$framewise_displacement,na.rm=TRUE)
		dvarsMEAN<-summary(CONTENT$dvars)[4]
		dvarsSD<-sd(CONTENT$dvars,na.rm=TRUE)
		gsMEAN<-summary(CONTENT$global_signal)[4]
		volTOTAL<-dim(CONTENT)[1]
		volAT25<-length(which(CONTENT$framewise_displacement < 0.25))
		volAT50<-length(which(CONTENT$framewise_displacement < 0.50))
		volAT75<-length(which(CONTENT$framewise_displacement < 0.75))
		volAT100<-length(which(CONTENT$framewise_displacement < 1.00))
		newrow<-c(SUB,SES,fdMEAN,fdSD,dvarsMEAN,dvarsSD,gsMEAN,volTOTAL,volAT25,volAT50,volAT75,volAT100,CONTENT$framewise_displacement)
		newrow<-as.data.frame(t(as.data.frame(newrow)))
		OUTPUT<-rbind.all.columns(OUTPUT, newrow)
	}
	print(paste0("Cleaning Master Dataset For Figures of QA Data"))
	names(OUTPUT) <- c("sub","ses","fdMEAN","fdSD","dvarsMEAN","dvarsSD","gsMEAN","volTOTAL","volAT25","volAT50","volAT75","volAT100")
	names(OUTPUT)
	OUTPUT[,-c(1,2)] <- suppressWarnings(data.frame(lapply(OUTPUT[,-c(1,2)], function(x) as.numeric(as.character(x)))))
	OUTPUT<-OUTPUT[-c(1),]
	OUTPUT<-OUTPUT[order(-OUTPUT[,"volTOTAL"],-OUTPUT[,"fdMEAN"] ),]
	MaxVolumesCombined<-dim(OUTPUT)[2]-12

#################################################################
##### Create Ouput Directories and Define Output File Names #####
#################################################################

	print(paste0("Defining Output File Names and Paths"))
	DIR_ROOT<-paste0(DIR_LOCAL_DATA,"/func_",task,"/prestats")
	suppressWarnings(dir.create(DIR_ROOT, recursive=TRUE))
	SubjectVols<-paste0(DIR_ROOT,"/n",nrow(OUTPUT),"_FD-Histogram_task-",task,".pdf")
	SubjectFD<-paste0(DIR_ROOT,"/n",nrow(OUTPUT),"_FD-Boxplot_task-",task,".pdf")
	GroupFD<-paste0(DIR_ROOT,"/n",nrow(OUTPUT),"_FD-Lineplot_task-",task,".pdf")
	QADataset<-paste0(DIR_ROOT,"/n",nrow(OUTPUT),"_QA-Summary_task-",task,".csv")
	VolumesDataset<-paste0(DIR_ROOT,"/n",nrow(OUTPUT),"_FD_volmax-",MaxVolumesCombined,"_ts_task-",task,".csv")

#######################################################################################
##### Create Scatterplot of Subject-Level Distributions of Framewise Displacement #####
#######################################################################################

	print(paste0("Creating Figure of Subject-Level Distributions of FD"))
	VOLUMES<-t(OUTPUT[,c(13:ncol(OUTPUT))])
	CONCAT<-melt(VOLUMES, id.vars=1)
	CONCAT<-CONCAT[complete.cases(CONCAT$value),]
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
		main = paste0("Subject-Level Distributions of Head Motion for ",task," Task"),
		ylab = "Head-Motion (Framewise-Displacement)",
		xlab = paste0("Scan Sessions (n = ",nrow(OUTPUT),")"),
		col = "#000000",
		border = "#000000",
		pch = 20,
		xaxt = "n",
		names = FALSE,
		varwidth = TRUE,
		frame=FALSE,
		whiskcol = "#ffffff",
		medcol = "#ffffff")
		mtext(paste0("Mean = ",MEAN,", Stardard Deviation =",SD), side=3)
		abline(h = c(0.25,0.50,0.75,1.00), col = c("#00d9ff","#00bbff","#0095ff","#006aff"), lwd = 1.5)
	dev.off()

##################################################################
##### Create Group-Level Histogram of Framewise Displacement #####
##################################################################

	print(paste0("Creating Figure of Group-Level Distributions of FD"))
	Remain25<-round(length(which(CONCAT$value < 0.25))/length(CONCAT$value)*100)
	Remain50<-round(length(which(CONCAT$value < 0.50))/length(CONCAT$value)*100)
	Remain75<-round(length(which(CONCAT$value < 0.75))/length(CONCAT$value)*100)
	Remain100<-round(length(which(CONCAT$value < 1.00))/length(CONCAT$value)*100)
	GROUPED<-data.frame(matrix(NA, nrow = length(1:125), ncol = 2))
	for (num in 1:125){
		THRESHOLD<-num/100
		PERCENT<-length(which(CONCAT$value < THRESHOLD))/length(which(complete.cases(CONCAT$value) == TRUE))
		GROUPED[num,1]<-THRESHOLD
		GROUPED[num,2]<-PERCENT
	}

	ggplot() + 
		geom_line(data= ,aes(GROUPED[,1],GROUPED[,2]), colour="#000000", size=3.00) +
		ggtitle(paste0("Percentage of Total Volumes Remaining After Temporal Censoring ",task," Task")) +
		xlab("Head-Motion Threshold (Framewise-Displacement)") +
		ylab("Volumes Remaining Across All Subjects (%)") +
		theme_classic() +
	  	theme(plot.title = element_text(size = rel(1.1),face = "bold"),
		axis.title.x=element_text(size = rel(1.25)),
		axis.title.y=element_text(size = rel(1.25))) +
		geom_vline(aes(xintercept=0.25), colour="#00d9ff", lwd = 1) + 
		geom_vline(aes(xintercept=0.50), colour="#00bbff", lwd = 1) + 
		geom_vline(aes(xintercept=0.75), colour="#0095ff", lwd = 1) + 
		geom_vline(aes(xintercept=1.00), colour="#006aff", lwd = 1) +
		annotate("text", x = 1.18, y = 0.25, label = paste0("Thresholds"),colour = "#000000",size = 4.5, fontface="bold") +
		annotate("text", x = 1.18, y = 0.20, label = paste0("0.25 = ",Remain25,"%"),colour = "#00d9ff",size = 4) +
		annotate("text", x = 1.18, y = 0.15, label = paste0("0.50 = ",Remain50,"%"),colour = "#00bbff",size = 4) +
		annotate("text", x = 1.18, y = 0.10, label = paste0("0.75 = ",Remain75,"%"),colour = "#0095ff",size = 4) +
		annotate("text", x = 1.18, y = 0.05, label = paste0("1.00 = ",Remain100,"%"),colour = "#006aff",size = 4) 
	ggsave(file=GroupFD,device = "pdf",width = 7, height = 7, units = c("in"))

###########################################################################
##### Create Subject-Level Histograms At Muliple Censoring Thresholds #####
###########################################################################

	print(paste0("Creating Figure of Censoring at Multiple Thresholds"))
	HISTOGRAMS<-data.frame(matrix(NA, nrow = 0, ncol = 2))
	for (subnum in 1:nrow(OUTPUT)){
		identifier<-paste0(subjects[subnum],"x",sessions[subnum])
		volnumsTOTAL<-data.frame(matrix("None", nrow = OUTPUT[subnum,"volTOTAL"], ncol = 1))
		volnumsAT25<-data.frame(matrix("0.25", nrow = OUTPUT[subnum,"volAT25"], ncol = 1))
		volnumsAT50<-data.frame(matrix("0.50", nrow = OUTPUT[subnum,"volAT50"], ncol = 1))
		volnumsAT75<-data.frame(matrix("0.75", nrow = OUTPUT[subnum,"volAT75"], ncol = 1))
		volnumsAT100<-data.frame(matrix("1.00", nrow = OUTPUT[subnum,"volAT100"], ncol = 1))
		CENSOR<-rbind(volnumsTOTAL, setNames(rev(volnumsAT100), names(volnumsTOTAL)))
		CENSOR<-rbind(CENSOR, setNames(rev(volnumsAT75), names(CENSOR)))
		CENSOR<-rbind(CENSOR, setNames(rev(volnumsAT50), names(CENSOR)))
		CENSOR<-rbind(CENSOR, setNames(rev(volnumsAT25), names(CENSOR)))
		CENSOR$threshold<-identifier
		HISTOGRAMS<-rbind(HISTOGRAMS, setNames(rev(CENSOR), names(CENSOR)))
	}
	colnames(HISTOGRAMS)[1]<-"subid"
	HISTOGRAMS$subid <- factor(HISTOGRAMS$subid, levels = unique(as.character(HISTOGRAMS$subid)))

	ggplot(HISTOGRAMS, aes(HISTOGRAMS[,1], fill = HISTOGRAMS[,2])) +
		ggtitle(paste0("Volumes After Framewise Displacement Censoring For ",task," Task")) +
		xlab(paste0("Scan Sessions (n = ",nrow(OUTPUT),")")) +
		ylab(paste0("Total Number of Volumes (max = ",MaxVolumesCombined,")")) +
		labs(fill = "Motion Threshold (FD):") +
		geom_bar(position = "identity", alpha = .675) +
  		theme(axis.title.x=element_text(size = rel(1.25),face = "bold"),
		axis.text.x=element_blank(),
		axis.title.y = element_text(size = rel(1.25),face = "bold"),
		plot.title = element_text(size = rel(1.25),face = "bold"),
		panel.background = element_rect(fill = "white", colour = "black"),
		legend.position = "top") +
		scale_fill_manual(values=c("#8B4513","#006aff","#0095ff","#00bbff","#00d9ff"))
	ggsave(file=SubjectVols,device = "pdf",width = 14, height = 7, units = c("in"))

#########################################################################
##### Save Datasets of QA Data To Include As Covaraites In Analyses #####
#########################################################################

	print(paste0("Saving Processed Datasets For Subsequent Analyses"))
	FINAL<-OUTPUT[,c(1:12)]
	VOLUMES<-t(VOLUMES)
	colnames(VOLUMES)<-gsub("NA.","vol",colnames(VOLUMES))
	if (all(is.na(FINAL$ses))){
		FINAL$ses<-NULL
		VOLUMES<-gsub("xNA","",row.names(VOLUMES))
		suppressMessages(suppressWarnings(write.csv(FINAL, QADataset)))
		suppressMessages(suppressWarnings(write.csv(VOLUMES, VolumesDataset)))
	} else {
		suppressMessages(suppressWarnings(write.csv(FINAL, QADataset)))
		suppressMessages(suppressWarnings(write.csv(VOLUMES, VolumesDataset)))
	}
	Sys.chmod(list.files(path=DIR_LOCAL_DATA , pattern="*", full.names = TRUE, recursive = TRUE), mode = "0775")
}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
