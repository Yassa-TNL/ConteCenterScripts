#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 4
#$ -R y
#$ -ckpt restart
################

print("Reading Arguments")

args <- commandArgs(trailingOnly=TRUE)
DIR_LOCAL_SCRIPTS = args[1]
DIR_LOCAL_APPS = args[2]
DIR_LOCAL_DATA = args[3]

suppressMessages(require(nlme))
suppressMessages(require(reshape))
suppressMessages(require(gtools))
suppressMessages(require(ggplot2))
TODAY=gsub("-","",Sys.Date())

####################################################################################################
##### Find All Processed Scans And Extract Signal Using Every Available Atlas For Each Subject #####
####################################################################################################

DIR_DATASETS=dirname(list.files(path=DIR_LOCAL_DATA, full.names=T, recursive=T, pattern = "_QA-Summary_"))
for (DIR_TASK in DIR_DATASETS[grep("prestats",DIR_DATASETS)]){
	LABEL_TASK=basename(gsub("prestats","",DIR_TASK))
	FILE_INFO <- file.info(list.files(DIR_TASK, pattern = "_QA-Summary_", full.names = T))
	FILE_QA<-rownames(FILE_INFO)[which.max(FILE_INFO$mtime)]
	CONTENT<-read.csv(FILE_QA)
	CONTENT<-CONTENT[,c("sub","ses")]
	print(paste0("Curating Confound2 Data From All Pipelines"))
	for (DIR_PIPE in list.files(path = paste0(DIR_LOCAL_APPS,"/xcpengine"), full.names=T, pattern="fc")){
		LABEL_PIPE=basename(gsub("fc-","",DIR_PIPE))
		FINAL=data.frame(matrix(NA, nrow = 0, ncol = 6218))
		for (ROW in 1:nrow(CONTENT)){
			IDS<-CONTENT[ROW,which(!is.na(match(colnames(CONTENT), c("sub","ses"))))]
			if (length(IDS) == 1){
				SUB<-IDS[1]
				DIR_ROOT<-paste0(DIR_PIPE,"/sub-",SUB,"/task-",LABEL_TASK)
			} else {
				SUB<-IDS[1]
				SES<-IDS[2]
				DIR_ROOT<-paste0(DIR_PIPE,"/sub-",SUB,"/ses-",SES,"/task-",LABEL_TASK)
			}
			FILES<-list.files(DIR_ROOT, recursive=T, full.names=T, pattern="_network.txt")
			FCON<-FILES[grep("run-02_desikanKilliany",FILES)]
			if (file.size(FCON) != 0){
				FCON<-as.data.frame(t(read.table(FCON)))
				FCON<-cbind(CONTENT[ROW,],FCON)
				FINAL<-rbind(FINAL,FCON)
			}
		}
		HEADERS<-list.files(DIR_LOCAL_SCRIPTS, recursive=T, full.names=T, pattern="NodeNames.txt")
		LABELS<-read.table(HEADERS[grep("desikanKilliany",HEADERS)])
		LABELS$V1<-gsub("Right-","r.",LABELS$V1) ; LABELS$V1<-gsub("Left-","l.",LABELS$V1)
		LABELS$V1<-gsub("ctx-rh-","r.",LABELS$V1) ; LABELS$V1<-gsub("ctx-lh-","l.",LABELS$V1)
		INDEX<-read.table(list.files(DIR_ROOT, recursive=T, full.names=T, pattern="desikanKilliany.net")[2])
		INDEX<-INDEX[-c(3)]
		SOURCE<-read.table(list.files(DIR_LOCAL_SCRIPTS, recursive=T, full.names=T, pattern=".node"))
		SOURCE$V6<-as.character(SOURCE$V6)
		for (ROW in 1:nrow(INDEX)){
			LABEL<-LABELS[c(INDEX[ROW,1],INDEX[ROW,2]),"V1"]
			if (LABEL[1] %in% SOURCE$V6 & LABEL[2] %in% SOURCE$V6){
				LABEL<-paste0(LABEL[1],'_',LABEL[2],"_RUN2")
				names(FINAL)[ROW+2]<-LABEL
			 } else {
				names(FINAL)[ROW+2]<-"EXCLUDE"
			}
		}
		FINAL<-FINAL[,which(names(FINAL) != "EXCLUDE")]
	}

write.table(FINAL,file=paste0(DIR_LOCAL_DATA,"/WORKING/RUN2.csv"),sep=',',row.names=FALSE)

Grp_Session<-ggplot(data=Figure,aes(x=AgeAtScan,y=Subject,group=Subject)) + geom_line(aes(color="#654321"), size=1.5) + geom_point(aes(color=Session),size=3.5) + scale_color_manual(values=c("#654321","#006eff", "#00aaff", "#00ddff")) + theme_classic()

RUN1<-read.csv("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/WORKING/RUN1.csv")
AMG<-read.csv("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/WORKING/AMG.csv")
RUN2<-read.csv("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/WORKING/RUN2.csv")
FINAL<-merge(RUN1,AMG, by=c("sub","ses"))
FINAL<-merge(FINAL,RUN2, by=c("sub","ses"))


FINAL<-na.omit(FINAL)
ONE<-FINAL[,c(1:2,grep("l.parahippocampal_l.frontalpole",names(FINAL)))]
ONE$IDS<-paste0(FINAL$sub,'x',FINAL$ses)
RUN1<-ONE[,c(3,6)]
AMG<-ONE[,c(4,6)]
RUN2<-ONE[,c(5,6)]
RUN1$SCAN<-"REST-1"
AMG$SCAN<-"AMG"
RUN2$SCAN<-"REST-2"
names(RUN1)[1]<-"Connectivity"
names(AMG)[1]<-"Connectivity"
names(RUN2)[1]<-"Connectivity"
FIGURE<-rbind(RUN1,AMG)
FIGURE<-rbind(FIGURE,RUN2)
FIGURE$SCAN<-factor(FIGURE$SCAN, levels=c("REST-1","AMG","REST-2"))
ggplot(data = FIGURE, mapping = aes(x = SCAN, y = Connectivity, group = IDS)) + geom_line(alpha=0.25) + theme_classic()
ggsave("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/WORKING/n282_R_HippXFrontPole_20200421.pdf")
ggplot(data = FIGURE, mapping = aes(x = SCAN, y = Connectivity, group = IDS)) + geom_line(alpha=0.25) + facet_wrap(~sub) + theme_classic()

ggplot(data = EXP, mapping = aes(x = Connectivity.right, y = Connectivity.left)) + geom_line(alpha=0.25) + geom_point() + theme_classic()

source<-unique(unlist(gsub("_AMG","",names(AMG))))
source<-unique(unlist(gsub("_AMG","",names(AMG)),"_"))
source<-source[-c(1:2)]

for (ROW in 1:length(source)){

	COLS<-grep(source[ROW],names(final))
	final[,COLS[2]]<- final[,COLS[2]] - final[,COLS[1]]
	final[,COLS[3]]<- final[,COLS[3]] - final[,COLS[1]]
	
}

for (ROW in 1:length(source)){
	REST<-which(names(final)== paste0(source[ROW],"_RUN2"))
	AMG<-which(names(final)== paste0(source[ROW],"_AMG"))
	lme(final[REST] ~ final[AMG], random = ~ 1 | final[sub], control=ctrl, method="REML",na.action=na.omit)
	
}



model.formula <- mclapply(3:ncol(AMG), function(x) {
  y<-paste0(x+ncol(AMG)-2)
print(x)
print(y)
  as.formula(paste(names(final[x]), "~", paste(names(final[y]))))
}, mc.cores=5)

#ANALYZE <- lme(formula = x, random = ~ 1 | sub,control=ctrl,data=final, method="REML",na.action=na.omit)
ctrl <- lmeControl(opt='optim') 


ncol(AMG)-2


for (ONE in 3:ncol(AMG)){
	TWO<-as.integer(ONE+ncol(AMG)-2)
	ANALYZE<-gamm4(formula = as.formula(paste(names(final[TWO]), "~", paste(names(final[ONE])))), random= as.formula(~(1|sub)), data=final, REML=T)$gam
	OUTPUT<-summary(ANALYZE)
	tVAL<-OUTPUT$p.table[6]
	pVAL<-OUTPUT$p.table[8]
	HEADER<-gsub("_RUN2","",names(final[TWO]))
	HEAD1<-unlist(strsplit(HEADER,"_"))[1]
	HEAD2<-unlist(strsplit(HEADER,"_"))[2]
	tMAT[HEAD1,HEAD2]<-tVAL
	tMAT[HEAD2,HEAD1]<-tVAL
	pMAT[HEAD1,HEAD2]<-pVAL
	pMAT[HEAD2,HEAD1]<-pVAL
}


ANALYZE<-gamm4(l.parahippocampal_l.frontalpole_RUN2 ~ l.parahippocampal_l.frontalpole_AMG, random= ~(1|sub), data=final)$gam
plotdata <- visreg(ANALYZE,"l.parahippocampal_l.frontalpole_AMG",type = "conditional",scale = "linear", plot = FALSE)
smooths <- data.frame(Variable = plotdata$meta$x,
                      x=plotdata$fit[[plotdata$meta$x]],
                      smooth=plotdata$fit$visregFit,
                      lower=plotdata$fit$visregLwr,
                      upper=plotdata$fit$visregUpr)
predicts <- data.frame(Variable = "dim1",
                       x=plotdata$res$l.parahippocampal_l.frontalpole_AMG,
                       y=plotdata$res$visregRes)

lineColor<- "#ed0e0e"
p_text<- "p < 0.0001"

Limbic<-ggplot() +
  geom_point(data = predicts, aes(x, y), alpha= 1  ) +
  #scale_colour_gradientn(colours = colkey,  name = "") +
  geom_line(data = smooths, aes(x = x, y = smooth), colour = lineColor,size=2) +
  geom_line(data = smooths, aes(x = x, y=lower), linetype="dashed", colour = lineColor, alpha = 0.8, size = 1.2) +
  geom_line(data = smooths, aes(x = x, y=upper), linetype="dashed",colour = lineColor, alpha = 0.8, size = 1.2) +
  annotate("text",x = -Inf, y = Inf, hjust = -0.1,vjust = 1,label = p_text, parse=TRUE,size = 8, colour = "black",fontface ="italic" ) +
  theme(legend.position = "none") + geom_abline(intercept = 0, slope = 0,alpha=0.4) + geom_vline(xintercept = 0,alpha=0.4) +
  labs(x = "", y = "") + xlim(-1,1) + ylim(-1,1) + theme_classic()
  theme(axis.title=element_text(size=26,face="bold"), axis.text=element_text(size=14), axis.title.x=element_text(color = "black"), axis.title.y=element_text(color = "black"))
  


m <- mclapply(model.formula, function(x) {
  ANALYZE <- gamm4(formula = x, random=as.formula(randomFormula), data=final, REML=T)$gam
  summary <- summary(ANALYZE)
  return(list(summary))
}, mc.cores=ncores)



			CHECKDIR<-length(which(grepl("combine", FILES) == TRUE))
			if (length(FILES) == 0){
				SKIP<-"Skipping Data Curation Due To Missing Files"
			} else if (length(FILES) == 1 & length(REGRESSED) == 1){
				VAL_CEN<-read.table(CENSORED)
				VAL_REG<-read.table(REGRESSED)	
				CONTENT[ROW,paste0("CENSOREDx",LABEL_PIPE)] <- VAL_CEN
			} else if (length(CENSORED)+length(REGRESSED) > 2 & CHECKDIR == 1){
				VAL_CEN<-read.table(CENSORED[grep("combine",CENSORED)])
				VAL_REG<-read.table(REGRESSED[grep("combine",REGRESSED)])
				CONTENT[ROW,paste0("CENSOREDx",LABEL_PIPE)] <- VAL_CEN
			} else {
				CONTENT[ROW,paste0("CENSOREDx",LABEL_PIPE)] <- NA
			}
		}
	}


####################################################################################################
##### Find All Processed Scans And Extract Signal Using Every Available Atlas For Each Subject #####
####################################################################################################

DIR_DATASETS=dirname(list.files(path=DIR_LOCAL_DATA, full.names=T, recursive=T, pattern = "_QA-Summary_"))
for (DIR_TASK in DIR_DATASETS[grep("prestats",DIR_DATASETS)]){
	TASK=basename(gsub("prestats","",DIR_TASK))
	FILE_INFO <- file.info(list.files(DIR_TASK, pattern = "_QA-Summary_", full.names = T))
	FILE_QA<-rownames(FILE_INFO)[which.max(FILE_INFO$mtime)]
	CONTENT<-read.csv(FILE_QA)
	grep(names(CONTENT), )
	if (any(names(CONTENT) == "ses")){
		CONTENT<-CONTENT[,c("sub","ses")]
		SUB<-CONTENT[ROW,"sub"]
		SES<-CONTENT[ROW,"ses"]


		for (ROW in 1:nrow(CONTENT)){
			for (PIPE in list.files(path=paste0(DIR_LOCAL_APPS,"/xcpengine/"))){
				FILES<-list.files(path=paste0(DIR_LOCAL_APPS,"/xcpengine/",PIPE,"/sub-",SUB,"/ses-",SES,"/task-",TASK), full.names=T, recursive=T, pattern = "_network.txt")
				for (ATLAS in basename(dirname(FILES))){
					for (FCON in FILES[grep(ATLAS,FILES)]){
						TEMP<-as.data.frame(t(read.table(FCON)))
						TEMP$sub<-SUB
						TEMP$ses<-SES
						CONTENT<-merge(CONTENT,TEMP,by=c("sub","ses"))
					}
				}
			}
		}
	}
}



	echo $FCON

	rm EXTRACTSIG.*
	LOG=`echo $PIPE/logs/timeseries_extraction.txt`
	REGRESSEDSCANS=`find ${PIPE} -type f -print | grep "_residualised.nii.gz"`
	echo "" > $LOG
	echo "#####################################################################################" >> $LOG
	echo " `ls $REGRESSEDSCANS | wc -l` Total Processed Scans Were Found For Pipeline: ${PIPE} " >> $LOG
	echo "#####################################################################################" >> $LOG

	for SCAN in $REGRESSEDSCANS ; do
	
		DIR_ROIQUANT=`dirname $SCAN | sed s@'regress'@'roiquant'@g`
		ATLASES=`find $DIR_ROIQUANT | grep ".nii.gz" | grep -v "referenceVolume" | grep -v "global" | grep -v "segmentation"`
		if (( `echo $ATLASES | wc -l` == 0 )) ; then
			echo "" >> $LOG
			echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #" >> $LOG
			echo " No Atlases Were Found For `basename ${SCAN}` " >> $LOG
			echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #" >> $LOG
			break
		else
			echo "" >> $LOG
			echo "#############################################################################################" >> $LOG
			echo " `basename $SCAN` Has `echo $ATLASES | wc -l` Atlas(es) Avaliable To Extract Timeseries Data " >> $LOG
			echo "#############################################################################################" >> $LOG 
		fi
		for ATLAS in $ATLASES ; do
			FILE_SUBJECT_OUTPUT=`echo $ATLAS | sed s@'.nii.gz'@'_timeseries.csv'@g`
			if [[ ! -f $FILE_SUBJECT_OUTPUT ]] ; then
				echo ""
				echo " Extracting Subject-Level Time Series For `basename $SCAN` With Atlas: `basename $ATLAS` "
				singularity exec --cleanenv ${DIR_LOCAL_SCRIPTS}/container_xcpengine.simg \
					/xcpEngine/utils/roi2ts.R \
					-i ${SCAN} \
					-r ${ATLAS} | sed s@' '@','@g > ${FILE_SUBJECT_OUTPUT}
			fi
		done
	done
	
#################################################################################################
##### Concatenate All Extracted Time-Series Dataset Into A Single Spreadsheet For Analyses  #####
#################################################################################################
	
	for ATLAS in $ATLASES ; do
		TODAY=`date "+%Y%m%d"`
		ATLAS_LABEL=$(basename `dirname $ATLAS`)
		FILE_PARC_LABELS=`echo $DIR_LOCAL_SCRIPTS/parcellations/${ATLAS_LABEL}/*NodeNames.txt`
		FILE_GROUP_OUTPUT=`echo  ${PIPE}/group/signalextract/${ATLAS_LABEL}_TimeSeries_GROUP_${TODAY}.csv`
		FIRST_TIMESERIES=`find ${PIPE} -type f -print | grep "${ATLAS_LABEL}_timeseries.csv" | head -n1`
		mkdir -p `dirname $FILE_GROUP_OUTPUT` ; rm ${FILE_GROUP_OUTPUT} 2>/dev/null
		if [[ ! -f ${FILE_PARC_LABELS} ]] ; then
			echo "" >> $LOG
			echo "###########################################################################################" >> $LOG
			echo "Node Labels For The ${ATLAS_LABEL} Atlas Were Not Found -- Post-Hoc Addiing Will Be Needed " >> $LOG
			echo "###########################################################################################" >> $LOG
		elif [[ `head -1 $FIRST_TIMESERIES | sed 's/[^,]//g' | wc -c` !=  `cat  ${FILE_PARC_LABELS} | wc -l` ]] ; then 
			echo "" >> $LOG
			echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  " >> $LOG
			echo "ERROR: Subject-Level Timeseries and Node Labels Do Not Have the Same Dimensions For ${ATLAS_LABEL} " >> $LOG
			echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  " >> $LOG
			break
		elif [[ -f ${FILE_PARC_LABELS} && `echo $FIRST_TIMESERIES` != *"ses"*  ]] ; then
			echo "" >> $LOG
			echo "########################################################################################" >> $LOG
			echo "Saving Cross-sectional Subject Identifiers and Node Labels For The ${ATLAS_LABEL} Atlas " >> $LOG
			echo "########################################################################################" >> $LOG
			echo "sub,$(cat ${FILE_PARC_LABELS} | tr '\n' ',')" > ${FILE_GROUP_OUTPUT}
		elif [[ -f ${FILE_PARC_LABELS} && `echo $FIRST_TIMESERIES` == *"ses"*  ]] ; then
			echo "" >> $LOG
			echo "#####################################################################################" >> $LOG
			echo "Saving Longitudinal Subject Identifiers and Node Labels For The ${ATLAS_LABEL} Atlas " >> $LOG
			echo "#####################################################################################" >> $LOG
			echo "sub,ses,$(cat ${FILE_PARC_LABELS} | tr '\n' ',')" > ${FILE_GROUP_OUTPUT}
		fi
		for TIMESERIES in `find ${PIPE} -type f -print | grep "${ATLAS_LABEL}_timeseries.csv"` ; do
			if [[ `echo $FIRST_TIMESERIES` != *"ses"*  ]] ; then
				SUB=`basename $TIMESERIES | cut -d '_' -f1 | cut -d '-' -f2`
				sed "s/^/"$SUB",/" $TIMESERIES >> ${FILE_GROUP_OUTPUT}
			elif [[  `echo $FIRST_TIMESERIES` == *"ses"*  ]] ; then
				SUB=`basename $TIMESERIES | cut -d '_' -f1 | cut -d '-' -f2`
				SES=`basename $TIMESERIES | cut -d '_' -f2 | cut -d '-' -f2`
				sed "s/^/"$SUB",${SES},/" $TIMESERIES >> ${FILE_GROUP_OUTPUT}
			fi
			echo "" >> $LOG
			echo " Concatenating Extracted Time-Series Data Into Group-Level Dataset For `basename ${TIMESERIES}` " >> $LOG
			chmod ug+wrx ${TIMESERIES}
		done
		chmod ug+wrx ${FILE_GROUP_OUTPUT}
	done
	echo "" >> $LOG
	echo "###################################################################" >> $LOG
	echo " Finished Signal Extraction For Files within Root Directory: $PIPE " >> $LOG
	echo "###################################################################" >> $LOG
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
###################################################################################################
