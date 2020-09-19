#!/bin/bash
#$ -q yassalab,pub*,free*
#$ -pe openmp 16-24
#$ -R y
#$ -ckpt restart
################

module load singularity/3.0.0 2>/dev/null 

DIR_LOCAL_SCRIPTS=$1
DIR_LOCAL_BIDS=$2
DIR_LOCAL_APPS=$3
PIPELINES=$4
SUBJECT=$5

#############################################
### Define Cohort, Command, and Log Files ###
#############################################

rm `echo ANAT${SUBJECT} | cut -c1-10`.*
for PIPE in `echo $PIPELINES | tr '@' ' ' ` ; do

	TODAY=`date "+%Y%m%d"`
	echo "Defining File Paths"
	DIR_OUTPUT_PATH=`echo $DIR_LOCAL_APPS/xcpengine/${PIPE} | sed s@'.dsn'@''@g`
	COMMAND_FILE=`echo $DIR_OUTPUT_PATH/logs/${TODAY}/${SUBJECT}_Command_ANAT.sh`
	COHORT_FILE=`echo $DIR_OUTPUT_PATH/logs/${TODAY}/${SUBJECT}_Cohort_ANAT.csv`
	LOG_FILE=`echo $DIR_OUTPUT_PATH/logs/${TODAY}/${SUBJECT}_Log_ANAT.txt`
	DIR_WORKING_PATH=`echo $DIR_OUTPUT_PATH/workflows/single_subject_${SUBJECT}`
	mkdir -p $DIR_WORKING_PATH `dirname ${LOG_FILE}`

##########################
### Create Cohort File ###
##########################

	echo "Locating Anatomical Scans"
	SCANS=`find $DIR_LOCAL_BIDS/sub-${SUBJECT} | grep T1w.nii.gz`

	echo "Defining Cohort File Header"
	if [[ $(echo $SCANS | tr ' ' '_') != *"ses-"* && $(echo $SCANS | tr ' ' '_') != *"run-"* ]] ; then
		echo "id0,img" > ${COHORT_FILE}
		HEADER_FORMAT='Standard'
	elif [[ $(echo $SCANS | tr ' ' '_') == *"ses-"* && $(echo $SCANS | tr ' ' '_') != *"run-"* ]] ; then
		echo "id0,id1,img" > ${COHORT_FILE}
		HEADER_FORMAT='Longitudinal'
	elif [[ $(echo $SCANS | tr ' ' '_') != *"ses-"* && $(echo $SCANS | tr ' ' '_') == *"run-"* ]] ; then
		echo "id0,id1,img" > ${COHORT_FILE}
		HEADER_FORMAT='MultiRun'
	elif [[ $(echo $SCANS | tr ' ' '_') == *"ses-"* && $(echo $SCANS | tr ' ' '_') == *"run-"* ]] ; then
		echo "id0,id1,id2,img" > ${COHORT_FILE}
		HEADER_FORMAT='Longitudinal_MultiRun'	
	fi

	echo "Finalizing Cohort File"
	for SCAN in ${SCANS} ; do

		if [[ $HEADER_FORMAT == "Standard" ]] ; then
 			SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
			echo "sub-${SUB},${SCAN}" >> ${COHORT_FILE}
		elif [[ $HEADER_FORMAT == "Longitudinal" ]] ; then
 			SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 			SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
			echo "sub-${SUB},ses-${SES},${SCAN}" >> ${COHORT_FILE}
		elif [[ $HEADER_FORMAT == "MultiRun" ]] ; then
			if [[ $SCAN == *"run-"* ]] ; then
 				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 				RUN=`basename $SCAN | cut -d '_' -f3 | cut -d '-' -f2`
				echo "sub-${SUB},run-${RUN},${SCAN}" >> ${COHORT_FILE}
			else
				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
				echo "sub-${SUB},run-01,${SCAN}" >> ${COHORT_FILE}
			fi
		elif [[ $HEADER_FORMAT == "Longitudinal_MultiRun" ]] ; then
			if [[ $SCAN == *"run-"*  ]] ; then
				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 				SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
 				RUN=`basename $SCAN | cut -d '_' -f4 | cut -d '-' -f2`
				echo "sub-${SUB},ses-${SES},run-${RUN},${SCAN}" >> ${COHORT_FILE}
			else
				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 				SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
				echo "sub-${SUB},ses-${SES},run-01,${SCAN}" >> ${COHORT_FILE}
			fi
		fi
	done

##################################
### Execute XCPEngine Pipeline ###
##################################

	echo "Executing XCPEngine Pipeline"
	echo "singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_xcpengine.simg \
		-d ${DIR_LOCAL_SCRIPTS}/designs/${PIPE} \
		-c ${COHORT_FILE} \
		-o ${DIR_OUTPUT_PATH} \
		-i ${DIR_WORKING_PATH} \
		-t 2" | tr '\t' '#' | sed s@'#'@''@g > ${COMMAND_FILE}

	chmod -R 775 ${COMMAND_FILE}

	${COMMAND_FILE} > ${LOG_FILE} 2>&1

	chmod -R 775 ${DIR_OUTPUT_PATH}/sub-${SUBJECT}

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
