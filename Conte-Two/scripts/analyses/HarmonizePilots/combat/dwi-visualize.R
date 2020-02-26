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

raw.scatterplot<-RestructSubLevel("Pilot1T",RAW)$scatter
combat.scatterplot<-RestructSubLevel("Pilot1T",COMBAT)$scatter

CORraw<-round(rsq(raw.scatterplot$Pilot1TxUCI,raw.scatterplot$Pilot1TxUCSD),digits=3)
CORcombat<-round(rsq(combat.scatterplot$Pilot1TxUCI,combat.scatterplot$Pilot1TxUCSD),digits=3)

ggplot() + 
	geom_point(data=raw.scatterplot, aes(Pilot1TxUCI,Pilot1TxUCSD), colour="#c70000", size=1.8) + 
	geom_point(data=combat.scatterplot, aes(Pilot1TxUCI,Pilot1TxUCSD), colour="#169e00", size=1.8) +
	geom_abline(data=raw.scatterplot, mapping=aes(slope=1, intercept=0), colour="#000000", size=2, alpha=0.65) +
	labs(x="UCI Scanner (Siemens)", y= "UCSD Scanner (GE)") +
	ggtitle(paste0("ComBat Harmonization of 205 Brain Volume Regions For Pilot #1")) +
	annotate("text", x = 35, y = 200, label = paste0("R-squared of Raw Values = ",CORraw),colour = "#c70000") +
	annotate("text", x = 52, y = 192, label = paste0("R-squared of ComBat-Corrected Values = ",CORcombat), colour = "#169e00")
ggsave(file=Subject1,device = "pdf",width = 7, height = 7, units = c("in"))

##############################################
### Save Figure For Pilot Subject Number 2 ###
##############################################

Subject2<-paste0(OutRoot,"/Figures/Pilot2T_ScatterPlot-COMBAT-Evaluation_T1w.pdf")
suppressWarnings(dir.create(dirname(Subject2), recursive=TRUE))

raw.scatterplot<-RestructSubLevel("Pilot2T",RAW)$scatter
combat.scatterplot<-RestructSubLevel("Pilot2T",COMBAT)$scatter

CORraw<-round(rsq(raw.scatterplot$Pilot2TxUCI,raw.scatterplot$Pilot2Tx1xUCSD),digits=3)
CORcombat<-round(rsq(combat.scatterplot$Pilot2TxUCI,combat.scatterplot$Pilot2Tx1xUCSD),digits=3)

ggplot() + 
	geom_point(data=raw.scatterplot, aes(Pilot2TxUCI,Pilot2Tx1xUCSD), colour="#c70000", size=1.8) + 
	geom_point(data=combat.scatterplot, aes(Pilot2TxUCI,Pilot2Tx1xUCSD), colour="#169e00", size=1.8) +
	geom_abline(data=raw.scatterplot, mapping=aes(slope=1, intercept=0), colour="#000000", size=2, alpha=0.65) +
	labs(x="UCI Scanner (Siemens)", y= "UCSD Scanner (GE)") +
	ggtitle(paste0("ComBat Harmonization of 205 Brain Volume Regions For Pilot #2")) +
	annotate("text", x = 35, y = 200, label = paste0("R-squared of Raw Values = ",CORraw),colour = "#c70000") +
	annotate("text", x = 52, y = 192, label = paste0("R-squared of ComBat-Corrected Values = ",CORcombat), colour = "#169e00")
ggsave(file=Subject2,device = "pdf",width = 7, height = 7, units = c("in"))

Sys.chmod(list.files(path= OutRoot, pattern="*", full.names = TRUE, recursive=TRUE), mode = "0775")

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
