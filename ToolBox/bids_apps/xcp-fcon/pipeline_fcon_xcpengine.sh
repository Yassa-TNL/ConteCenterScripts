#!/bin/bash
#$ -q yassalab,pub*,free*
#$ -pe openmp 1-16
#$ -R y
#$ -ckpt restart
################

module load singularity fsl 

DIR_TOOLBOX=$1
DIR_PROJECT=$2
TEMPLATE_SPACE=$(basename $3 | cut -d '_' -f1 | cut -d '-' -f2)
PIPE_LABELS="${4}"
SUBJECT=$5
TASK_LABEL=$6

#############################################
### Define Cohort, Command, and Log Files ###
#############################################

TODAY=`date "+%Y%m%d"`
rm `echo ${TASK_LABEL}${SUBJECT} | cut -c1-10`.*
for PIPE in `echo $PIPE_LABELS | tr '@' ' '` ; do

	echo "Locating PrePreprocessed Scans"
	PIPE_LABEL=`echo $PIPE | sed s@'fc-'@@g | sed s@'.dsn'@@g | sed s@_@X@g`
	PREPROC=`find $DIR_PROJECT/apps/fmriprep/sub-${SUBJECT} | grep task-${TASK_LABEL} | grep space-${TEMPLATE_SPACE}_desc-preproc_bold.nii.gz`
	SCANS=`echo $PREPROC | sed s@"${DIR_PROJECT}/apps/fmriprep/"@""@g`

	i=0
	echo "Define Input & Output Paths"
	for SCAN in ${SCANS} ; do
		if [[ $(echo $SCANS | tr ' ' '_') != *"ses-"* && $(echo $SCANS | tr ' ' '_') != *"run-"* ]] ; then
			SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
			COHORT_HEADER=`echo "id0,img"`
			COHORT_CONTENT=`echo "sub-${SUB},${SCAN}"`
			DIR_ROOT[i]=$DIR_PROJECT/apps/xcp-fcon/pipe-${PIPE_LABEL}_task-${TASK_LABEL} 
		elif [[ $(echo $SCANS | tr ' ' '_') == *"ses-"* && $(echo $SCANS | tr ' ' '_') != *"run-"* ]] ; then
 			SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 			SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
			COHORT_HEADER=`echo "id0,id1,img"`
			COHORT_CONTENT=`echo "sub-${SUB},ses-${SES},${SCAN}"`
			DIR_ROOT[i]=$DIR_PROJECT/apps/xcp-fcon/pipe-${PIPE_LABEL}_task-${TASK_LABEL}
		elif [[ $(echo $SCANS | tr ' ' '_') != *"ses-"* && $(echo $SCANS | tr ' ' '_') == *"run-"* ]] ; then
			if [[ $SCAN == *"run-"* ]] ; then
 				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 				RUN=`basename $SCAN | cut -d '_' -f3 | cut -d '-' -f2`
			else
				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
				RUN=1
			fi
			COHORT_HEADER=`echo "id0,img"`
			COHORT_CONTENT=`echo "sub-${SUB},${SCAN}"`
			DIR_ROOT[i]=$DIR_PROJECT/apps/xcp-fcon/pipe-${PIPE_LABEL}_task-${TASK_LABEL}_run-${RUN}
		elif [[ $(echo $SCANS | tr ' ' '_') == *"ses-"* && $(echo $SCANS | tr ' ' '_') == *"run-"* ]] ; then
			if [[ $SCAN == *"run-"* ]] ; then
				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 				SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
 				RUN=`basename $SCAN | cut -d '_' -f4 | cut -d '-' -f2`
			else
				SUB=`basename $SCAN | cut -d '_' -f1 | cut -d '-' -f2`
 				SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
				RUN=1
			fi
			COHORT_HEADER=`echo "id0,id1,img"`
			COHORT_CONTENT=`echo "sub-${SUB},ses-${SES},${SCAN}"`
			DIR_ROOT[i]=$DIR_PROJECT/apps/xcp-fcon/pipe-${PIPE_LABEL}_task-${TASK_LABEL}_run-${RUN}
		fi

		echo "Finalizing Cohort File"
		mkdir -p ${DIR_ROOT[i]}/logs/${TODAY}/
		if [[ ! -f ${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_cohort.csv ]] ; then
			echo $COHORT_HEADER > ${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_cohort.csv
		fi
		if ! grep ${COHORT_CONTENT} "${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_cohort.csv" ; then
			echo $COHORT_CONTENT >> ${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_cohort.csv	
		fi
		(( i++ ))
	done

	echo "Executing XCPEngine Pipeline"
	for DIR_ROOT in `echo ${DIR_ROOT[@]} | tr ' ' '\n' | sort | uniq` ; do
		echo "singularity run --bind /dfs2,/data:/mnt --cleanenv `ls -t $DIR_TOOLBOX/bids_apps/dependencies/xcpengine_v*.simg | head -n1` \
			-d $DIR_TOOLBOX/bids_apps/dependencies/designs_xcp/${PIPE} \
			-c ${DIR_ROOT}/logs/${TODAY}/sub-${SUBJECT}_cohort.csv \
			-o ${DIR_ROOT} \
			-i ${DIR_ROOT}/workflows/single_subject_${SUBJECT} \
			-r ${DIR_PROJECT}/apps/fmriprep \
			-t 2" | tr '\t' '#' | sed s@'#'@''@g > ${DIR_ROOT}/logs/${TODAY}/sub-${SUBJECT}_command.sh

		chmod -R 775 ${DIR_ROOT}/logs/${TODAY}/sub-${SUBJECT}_command.sh

		${DIR_ROOT}/logs/${TODAY}/sub-${SUBJECT}_command.sh > /dev/null 2>&1

		echo "Cleaning Output Directories and Smoothing Preproc Files"
		chmod -R 775 ${DIR_ROOT}/sub-${SUBJECT}
		find ${DIR_ROOT}/sub-${SUBJECT} -size 0 -delete
		rm -rf ${DIR_ROOT}/workflows/single_subject_${SUBJECT}
		for SCAN in `find ${DIR_ROOT} -iname *_residualised.nii.gz`; do
			if [[ ! -f `echo $SCAN | sed s@.nii@_sm2.nii@g` ]] ; then 
				MASK=`echo $SCAN | sed s@'regress/'@'prestats/'@g | sed s@'_residualised.nii.gz'@'_mask.nii.gz'@g`
				fslmaths $SCAN -s 2 `echo $SCAN | sed s@.nii@_sm2.nii@g`
				fslmaths `echo $SCAN | sed s@.nii@_sm2.nii@g` -mul $MASK `echo $SCAN | sed s@.nii@_sm2.nii@g`
				chmod ug+wrx `echo $SCAN | sed s@.nii@_sm2.nii@g` 
			fi
			if [[ ! -f `echo $SCAN | sed s@.nii@_sm3.nii@g` ]] ; then 
				MASK=`echo $SCAN | sed s@'regress/'@'prestats/'@g | sed s@'_residualised.nii.gz'@'_mask.nii.gz'@g`
				fslmaths $SCAN -s 3 `echo $SCAN | sed s@.nii@_sm3.nii@g`
				fslmaths `echo $SCAN | sed s@.nii@_sm3.nii@g` -mul $MASK `echo $SCAN | sed s@.nii@_sm3.nii@g`
				chmod ug+wrx `echo $SCAN | sed s@.nii@_sm3.nii@g` 
			fi
		done

		echo "Extract Signal From Tissue Segmentations"
		for SEGMENT_NIFTI in `find ${DIR_ROOT}/sub-${SUBJECT} -type f | grep prestats | grep segmentation.nii.gz` ; do
			REGRESS_NIFTI=`echo $SEGMENT_NIFTI | sed s@'prestats'@'regress'@g | sed s@'segmentation'@'residualised'@g`					
			EXTRACT_FILE=`echo $SEGMENT_NIFTI | sed s@'prestats'@'confound2'@g | sed s@'.nii.gz'@'.csv'@g`
			singularity exec --cleanenv `ls -t $DIR_TOOLBOX/bids_apps/dependencies/xcpengine_v*.simg | head -n1` \
				/xcpEngine/utils/roi2ts.R \
				-i ${REGRESS_NIFTI} \
				-r ${SEGMENT_NIFTI} | sed s@' '@','@g > ${EXTRACT_FILE}
		done
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
