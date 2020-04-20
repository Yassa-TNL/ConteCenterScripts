#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 4
#$ -R y
#$ -ckpt restart
################

DIR_LOCAL_SCRIPTS=$1
DIR_LOCAL_APPS=$2

####################################################################################################
##### Find All Processed Scans And Extract Signal Using Every Available Atlas For Each Subject #####
####################################################################################################

for PIPE in $DIR_LOCAL_APPS/xcpengine/*/fc-* ; do

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
