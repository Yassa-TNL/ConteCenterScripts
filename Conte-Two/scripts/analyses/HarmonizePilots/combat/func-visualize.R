###################################################################################################
##########################               HarmonizeCOMBAT                 ##########################
##########################               Robert Jirsaraie                ##########################
##########################               rjirsara@uci.edu                ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
# Use #

# This script creates visualizations to view the change before and after harmonization was applied 
# via ComBat. Figure 1 shows how strongly correlated the travel subjects scans are while Figure 2
# coveys the overall differences between scans.

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

InDirRoot <- "/dfs2/yassalab/rjirsara/HarmonizeCOMBAT/Data/T1w"
InFileName <- "ASEG_Volume-"
OutRoot <- "/dfs2/yassalab/rjirsara/HarmonizeCOMBAT"

#############################
### Load Data For Visuals ###
#############################

InFiles<-grep(InFileName, list.files(InDirRoot, full.names=TRUE, recursive=TRUE))
COMBAT<-read.csv(list.files(InDirRoot, full.names=TRUE, recursive=TRUE)[InFiles[1]])
RAW<-read.csv(list.files(InDirRoot, full.names=TRUE, recursive=TRUE)[InFiles[2]])

###############################################################
### Restructure SubLevel Data and Load Software For Visuals ###
###############################################################

rsq <- function (x, y) cor(x, y) ^ 2

RestructSubLevel <- function(subject,harmonization){
	FINAL<-list()
	FINAL$scatter<-harmonization[,grep(subject,colnames(harmonization))]
	sub.uci<-as.data.frame(cbind(FINAL$scatter[,c(grep("UCI", colnames(FINAL$scatter)))],"UCI"))
	sub.ucsd<-as.data.frame(cbind(FINAL$scatter[,c(grep("UCSD", colnames(FINAL$scatter)))],"UCSD"))
	FINAL$box<-rbind(sub.uci,sub.ucsd)
	FINAL$box$V1<-as.numeric(as.character(FINAL$box$V1))
	FINAL$box$V2<-as.factor(as.character(FINAL$box$V2))
	return(FINAL)
}

suppressMessages(require(ggplot2))
suppressMessages(require(cowplot))
suppressMessages(require(RColorBrewer))

##############################################
### Save Figure For Pilot Subject Number 1 ###
##############################################

Subject1<-paste0(OutRoot,"/Figures/Pilot1T_ScatterPlot-COMBAT-Evaluation_T1w.pdf")
suppressWarnings(dir.create(dirname(Subject1), recursive=TRUE))

raw.scatterplot<-RestructSubLevel("REST",RAW)$scatter
combat.scatterplot<-RestructSubLevel("REST",COMBAT)$scatter

CORraw<-round(rsq(raw.scatterplot$UCIxREST,raw.scatterplot$UCSDxREST),digits=3)
CORcombat<-round(rsq(combat.scatterplot$UCIxREST,combat.scatterplot$UCSDxREST),digits=3)
OUTFILE="/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/datasets/REST/COMBAT/RESTING.pdf"

ggplot() + 
	geom_point(data=raw.scatterplot, aes(UCIxREST,UCSDxREST), colour="#c70000", size=1.8) + 
	geom_point(data=combat.scatterplot, aes(UCIxREST,UCSDxREST), colour="#169e00", size=1.8) +
	geom_abline(data=raw.scatterplot, mapping=aes(slope=1, intercept=0), colour="#000000", size=2, alpha=0.65) +
	labs(x="UCI Scanner (Siemens)", y= "UCSD Scanner (GE)") +
	ggtitle(paste0("ComBat Harmonization of Resting-State Scan (4,950 Unique Edges)")) +
	annotate("text", x = -.55, y = .93, label = paste0("R-squared of Raw Values = ",CORraw),colour = "#c70000") +
	annotate("text", x = -.4, y = 1, label = paste0("R-squared of ComBat-Corrected Values = ",CORcombat), colour = "#169e00") +
	theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(), axis.line = element_line(colour = "black"))
ggsave(file=OUTFILE,device = "pdf",width = 7, height = 7, units = c("in"))

##############################################
### Save Figure For Pilot Subject Number 1 ###
##############################################

raw.scatterplot<-RestructSubLevel("DOORS",RAW)$scatter
combat.scatterplot<-RestructSubLevel("DOORS",COMBAT)$scatter

CORraw<-round(rsq(raw.scatterplot$UCIxDOORS,raw.scatterplot$UCSDxDOORS),digits=3)
CORcombat<-round(rsq(combat.scatterplot$UCIxDOORS,combat.scatterplot$UCSDxDOORS),digits=3)
OUTFILE="/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/datasets/REST/COMBAT/DOORS.pdf"

ggplot() + 
	geom_point(data=raw.scatterplot, aes(UCIxDOORS,UCSDxDOORS), colour="#c70000", size=1.8) + 
	geom_point(data=combat.scatterplot, aes(UCIxDOORS,UCSDxDOORS), colour="#169e00", size=1.8) +
	geom_abline(data=raw.scatterplot, mapping=aes(slope=1, intercept=0), colour="#000000", size=2, alpha=0.65) +
	labs(x="UCI Scanner (Siemens)", y= "UCSD Scanner (GE)") +
	ggtitle(paste0("ComBat Harmonization of Doors Task-Based Scan (4,950 Unique Edges)")) +
	annotate("text", x = -.45, y = .93, label = paste0("R-squared of Raw Values = ",CORraw),colour = "#c70000") +
	annotate("text", x = -.33, y = 1, label = paste0("R-squared of ComBat-Corrected Values = ",CORcombat), colour = "#169e00") +
	theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(), axis.line = element_line(colour = "black"))
ggsave(file=OUTFILE,device = "pdf",width = 7, height = 7, units = c("in"))

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
