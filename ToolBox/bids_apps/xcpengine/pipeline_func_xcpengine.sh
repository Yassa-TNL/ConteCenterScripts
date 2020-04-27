#!/bin/bash
#$ -q yassalab,pub*,free*
#$ -pe openmp 8-24
#$ -R y
#$ -ckpt restart
################

module load singularity/3.0.0 fsl/6.0.1 

DIR_LOCAL_SCRIPTS=$1
DIR_LOCAL_APPS=$2
TEMPLATE_SPACE=$3
PIPELINES=$4
SUBJECT=$5
TASK=$6

#############################################
### Define Cohort, Command, and Log Files ###
#############################################

rm `echo ${TASK}${SUBJECT} | cut -c1-10`.*
for PIPE in `echo $PIPELINES | tr '@' ' ' ` ; do
	TODAY=`date "+%Y%m%d"`
	echo "Defining File Paths"
	DIR_OUTPUT_PATH=`echo $DIR_LOCAL_APPS/xcpengine/${PIPE} | sed s@'.dsn'@''@g`
	LOG_FILE=`echo $DIR_OUTPUT_PATH/logs/${TODAY}/${SUBJECT}_Log_${TASK}.txt`
	COHORT_FILE=`echo $DIR_OUTPUT_PATH/logs/${TODAY}/${SUBJECT}_Cohort_${TASK}.csv`
	COMMAND_FILE=`echo $DIR_OUTPUT_PATH/logs/${TODAY}/${SUBJECT}_Command_${TASK}.sh`
	DIR_WORKING_PATH=`echo $DIR_OUTPUT_PATH/workflows/single_subject_${SUBJECT}/task-${TASK}`
	mkdir -p $DIR_WORKING_PATH `dirname ${LOG_FILE}`

##########################
### Create Cohort File ###
##########################

	echo "Locating PrePreprocessed Scans"
	if [[ $PIPE == *"aroma"* ]] ; then
		ICA=`find $DIR_LOCAL_APPS/fmriprep/sub-${SUBJECT} | grep task-${TASK} | grep space-MNI152NLin6Asym_desc-smoothAROMAnonaggr_bold.nii.gz`
		SCANS=`echo $ICA | sed s@"${DIR_LOCAL_APPS}/fmriprep/"@""@g`
	else
		PREPROC=`find $DIR_LOCAL_APPS/fmriprep/sub-${SUBJECT} | grep task-${TASK} | grep space-${TEMPLATE_SPACE}_desc-preproc_bold.nii.gz`
		SCANS=`echo $PREPROC | sed s@"${DIR_LOCAL_APPS}/fmriprep/"@""@g`
	fi

	echo "Defining Cohort File Header"
	if [[ $(echo $SCANS | tr ' ' '_') != *"ses-"* && $(echo $SCANS | tr ' ' '_') != *"run-"* ]] ; then
		echo "id0,id1,img" > ${COHORT_FILE}
		HEADER_FORMAT='Standard'
	elif [[ $(echo $SCANS | tr ' ' '_') == *"ses-"* && $(echo $SCANS | tr ' ' '_') != *"run-"* ]] ; then
		echo "id0,id1,id2,img" > ${COHORT_FILE}
		HEADER_FORMAT='Longitudinal'
	elif [[ $(echo $SCANS | tr ' ' '_') != *"ses-"* && $(echo $SCANS | tr ' ' '_') == *"run-"* ]] ; then
		echo "id0,id1,id2,img" > ${COHORT_FILE}
		HEADER_FORMAT='MultiRun'
	elif [[ $(echo $SCANS | tr ' ' '_') == *"ses-"* && $(echo $SCANS | tr ' ' '_') == *"run-"* ]] ; then
		echo "id0,id1,id2,id3,img" > ${COHORT_FILE}
		HEADER_FORMAT='Longitudinal_MultiRun'	
	fi

	echo "Finalizing Cohort File"
	for SCAN in ${SCANS} ; do
		if [[ $HEADER_FORMAT == "Standard" ]] ; then
 			SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
			echo "sub-${SUB},task-${TASK},${SCAN}" >> ${COHORT_FILE}
		elif [[ $HEADER_FORMAT == "Longitudinal" ]] ; then
 			SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 			SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
			echo "sub-${SUB},ses-${SES},task-${TASK},${SCAN}" >> ${COHORT_FILE}
		elif [[ $HEADER_FORMAT == "MultiRun" ]] ; then
			if [[ $SCAN == *"run-"* ]] ; then
 				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 				RUN=`basename $SCAN | cut -d '_' -f3 | cut -d '-' -f2`
				echo "sub-${SUB},task-${TASK},run-${RUN},${SCAN}" >> ${COHORT_FILE}
			else
				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
				echo "sub-${SUB},task-${TASK},run-01,${SCAN}" >> ${COHORT_FILE}
			fi
		elif [[ $HEADER_FORMAT == "Longitudinal_MultiRun" ]] ; then
			if [[ $SCAN == *"run-"*  ]] ; then
				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 				SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
 				RUN=`basename $SCAN | cut -d '_' -f4 | cut -d '-' -f2`
				echo "sub-${SUB},ses-${SES},task-${TASK},run-${RUN},${SCAN}" >> ${COHORT_FILE}
			else
				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 				SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
				echo "sub-${SUB},ses-${SES},task-${TASK},run-01,${SCAN}" >> ${COHORT_FILE}
			fi
		fi
	done

	echo ${SUBJECT},${TODAY},${HEADER_FORMAT} >> $DIR_OUTPUT_PATH/logs/directory_structure_${TASK}.csv

##################################
### Execute XCPEngine Pipeline ###
##################################

	echo "Executing XCPEngine Pipeline"
	echo "singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_xcpengine.simg \
		-d ${DIR_LOCAL_SCRIPTS}/designs/${PIPE} \
		-c ${COHORT_FILE} \
		-o ${DIR_OUTPUT_PATH} \
		-i ${DIR_WORKING_PATH} \
		-r ${DIR_LOCAL_APPS}/fmriprep \
		-t 2" | tr '\t' '#' | sed s@'#'@''@g > ${COMMAND_FILE}

	chmod -R 775 ${COMMAND_FILE}

	${COMMAND_FILE} > ${LOG_FILE} 2>&1

	chmod -R 775 ${DIR_OUTPUT_PATH}/sub-${SUBJECT}
	rmdir ${DIR_OUTPUT_PATH}/workflows/single_subject_${SUBJECT}/task-${TASK}

###################################################################################
### Extract Signal From Tissue Segmentations Following Demeaning and Detrending ###
###################################################################################

	for DIR_ROOT in `find ${DIR_OUTPUT_PATH}/sub-${SUBJECT} -type f | grep task-${TASK} | sed s@"/task-${TASK}/"@','@g | cut -d ',' -f1 | uniq` ; do
		for SEGMENT in `find $DIR_ROOT | grep prestats | grep segmentation.nii.gz` ; do 	
			REGRESS_NIFTI=`echo $SEGMENT | sed s@'prestats'@'regress'@g | sed s@'segmentation'@'residualised'@g`					
			EXTRACT_FILE=`echo $SEGMENT | sed s@'prestats'@'confound2'@g | sed s@'.nii.gz'@'.csv'@g`
			singularity exec --cleanenv ${DIR_LOCAL_SCRIPTS}/container_xcpengine.simg \
				/xcpEngine/utils/roi2ts.R \
				-i ${REGRESS_NIFTI} \
				-r ${SEGMENT} | sed s@' '@','@g > ${EXTRACT_FILE}
		done
	done

##########################################################
### Merge Selected Output From Multi-Run Scan Sessions ###
##########################################################

	if [[ $HEADER_FORMAT == *"MultiRun"* ]] ; then
		for DIR_ROOT in `find ${DIR_OUTPUT_PATH}/sub-${SUBJECT} -type f | grep task-${TASK} | sed s@"/task-${TASK}/"@','@g | cut -d ',' -f1 | uniq` ; do
			echo 'Merging Selected Files From Fcon Module'
			for ATLAS in `ls ${DIR_ROOT}/task-${TASK}/run-01/fcon | grep -v .nii.gz` ; do
				mkdir -p ${DIR_ROOT}/task-${TASK}/combine/fcon/${ATLAS}/
				MERGE=`echo ${DIR_ROOT}/task-${TASK}/run-*/fcon/${ATLAS}/sub-${SUBJECT}*task-${TASK}_run-*_${ATLAS}_ts.1D`	
				MERGED_FILE=`echo $MERGE | cut -d ' ' -f1 | sed s@run-01@'combine'@g` ; cat $MERGE > $MERGED_FILE
				singularity exec --cleanenv ${DIR_LOCAL_SCRIPTS}/container_xcpengine.simg \
					/xcpEngine/utils/ts2adjmat.R \
					--ts $MERGED_FILE > `echo $MERGED_FILE | sed s@'ts.1D'@'network.txt'@g`
			done
			echo 'Merging Selected Files From Regress Module'
			mkdir -p ${DIR_ROOT}/task-${TASK}/combine/regress
			MERGE=`echo ${DIR_ROOT}/task-${TASK}/run-*/regress/sub-${SUBJECT}*task-${TASK}_run-*_nVolumesCensored.txt`	
			MERGED_FILE=`echo $MERGE | cut -d ' ' -f1 | sed s@run-01@'combine'@g` ; cat $MERGE > $MERGED_FILE
			if [ -s $MERGED_FILE ] ; then
				paste -sd+ $MERGED_FILE | bc > ${MERGED_FILE}_NEW ; mv ${MERGED_FILE}_NEW ${MERGED_FILE}
			else
				echo NA > ${MERGED_FILE}_NEW ; mv ${MERGED_FILE}_NEW ${MERGED_FILE}
			fi
			for REGRESS in `find ${DIR_ROOT}/task-${TASK}/run-01/regress | grep .nii.gz` ; do
				MERGED_NIFTI=`echo $REGRESS | sed s@'run-01'@'combine'@g` ; rm $MERGED_NIFTI
				fslmerge -t ${MERGED_NIFTI} `echo $REGRESS | sed s@'run-01'@'*'@g`
			done
			echo 'Merging Selected Files From Confound2 Module'
			mkdir -p ${DIR_ROOT}/task-${TASK}/combine/confound2
			MERGE=`echo ${DIR_ROOT}/task-${TASK}/run-*/confound2/sub-${SUBJECT}*task-${TASK}_run-*_modelParameterCount.txt`	
			MERGED_FILE=`echo $MERGE | cut -d ' ' -f1 | sed s@run-01@'combine'@g` ; cat ${MERGE} | sort -nr | head -n1 > $MERGED_FILE
			MERGE=`echo ${DIR_ROOT}/task-${TASK}/run-*/confound2/sub-${SUBJECT}*task-${TASK}_run-*_segmentation.csv`	
			MERGED_FILE=`echo $MERGE | cut -d ' ' -f1 | sed s@run-01@'combine'@g` ; cat $MERGE > $MERGED_FILE
			chmod -R ug+wrx ${DIR_ROOT}/task-${TASK}
		done
	fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
