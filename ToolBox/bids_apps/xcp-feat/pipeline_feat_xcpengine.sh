#!/bin/bash
#$ -q yassalab,pub*,free*
#$ -pe openmp 8-16
#$ -R y
#$ -ckpt restart
################

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3 fsl/6.0.1
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local 

DIR_TOOLBOX=$1
DIR_PROJECT=$2
DESIGN_CONFIG=$3
TEMPLATE_SPACE=$4
DENOISE_PIPELINE="${5}"
CONTRAST_HEADER="${6}"
TASK_LABEL=$7
SUBJECT=$8
OPT_THRESH_TYPE=`echo $9 | tr '[A-Z]' '[a-z]'`
OPT_THRESH_MASK=$10

#############################################
### Define Cohort, Command, and Log Files ###
#############################################

#unset SGE_ROOT
TODAY=`date "+%Y%m%d"`
rm `echo ${TASK_LABEL}${SUBJECT} | cut -c1-10`.*
rm ${DIR_PROJECT}/scripts/apps/sub-${SUBJECT}*_structmask.nii.gz
if [[ $OPT_THRESH_TYPE == 'uncorrected' ]] ; then
	THRESH_TYPE=1
elif [[ $OPT_THRESH_TYPE == 'voxel' ]] ; then
	THRESH_TYPE=2
elif [[ $OPT_THRESH_TYPE == 'cluster' ]] ; then
	THRESH_TYPE=3
else
	OPT_THRESH_TYPE='none'
	THRESH_TYPE=0
fi
for PIPE in `echo $DENOISE_PIPELINE | sed s@fc-@''@g | sed s@.dsn@''@g` ; do
	for CONTRAST in $CONTRAST_HEADER ; do

		echo "Locating PrePreprocessed Scans"
		TEMPLATE_LABEL=$(basename $TEMPLATE_SPACE | cut -d '_' -f1 | cut -d '-' -f2)
		PREPROC=`find $DIR_PROJECT/apps/fmriprep/sub-${SUBJECT} | grep task-${TASK_LABEL} | grep space-${TEMPLATE_LABEL}_desc-preproc_bold.nii.gz`
		SCANS=`echo $PREPROC | sed s@"${DIR_PROJECT}/apps/fmriprep/"@""@g`

		echo "Defining Output Paths & Input Event Files"
		INDEX_SCAN=0 ; i=0
		for SCAN in ${SCANS} ; do
			INDEX_SCAN=$((INDEX_SCAN + 1))
			LABEL_PIPE=`echo $PIPE | sed s@'_'@'x'@g`
			LABEL_CONTRAST=`echo $CONTRAST_HEADER | sed s@'_'@'x'@g`
			if [[ $(echo $SCANS | tr ' ' '_') != *"ses-"* && $(echo $SCANS | tr ' ' '_') != *"run-"* ]] ; then
				DATA_STRUC='Standard'
				DIR_ROOT[i]=$DIR_PROJECT/apps/xcp-feat/pipe-${LABEL_PIPE}X${OPT_THRESH_TYPE}_task-${TASK_LABEL}_${CONTRAST}
				TSV_FILE=`find $DIR_PROJECT/bids sub-${SUBJECT}_task-${TASK_LABEL}_events.tsv`
			elif [[ $(echo $SCANS | tr ' ' '_') == *"ses-"* && $(echo $SCANS | tr ' ' '_') != *"run-"* ]] ; then
				DATA_STRUC='Longitudinal'
				SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
				DIR_ROOT[i]=$DIR_PROJECT/apps/xcp-feat/pipe-${LABEL_PIPE}X${OPT_THRESH_TYPE}_task-${TASK_LABEL}_${CONTRAST}
				TSV_FILE=`find $DIR_PROJECT/bids -iname sub-${SUBJECT}_ses-${SES}_task-${TASK_LABEL}_events.tsv`
			elif [[ $(echo $SCANS | tr ' ' '_') != *"ses-"* && $(echo $SCANS | tr ' ' '_') == *"run-"* ]] ; then
				DATA_STRUC='MultiRun'
				if [[ $SCAN == *"run-"* ]] ; then
					RUN=`basename $SCAN | cut -d '_' -f3 | cut -d '-' -f2`
					DIR_ROOT[i]=$DIR_PROJECT/apps/xcp-feat/pipe-${LABEL_PIPE}X${OPT_THRESH_TYPE}_task-${TASK_LABEL}_run-${RUN}_${CONTRAST}
					TSV_FILE=`find $DIR_PROJECT/bids -iname sub-${SUBJECT}_task-${TASK_LABEL}_run-${RUN}_events.tsv`
				else
					RUN=01 
					DIR_ROOT[i]=$DIR_PROJECT/apps/xcp-feat/pipe-${LABEL_PIPE}X${OPT_THRESH_TYPE}_task-${TASK_LABEL}_run-${RUN}_${CONTRAST}
					TSV_FILE=`find $DIR_PROJECT/bids -iname sub-${SUBJECT}_task-${TASK_LABEL}_events.tsv`
				fi
			elif [[ $(echo $SCANS | tr ' ' '_') == *"ses-"* && $(echo $SCANS | tr ' ' '_') == *"run-"* ]] ; then
				DATA_STRUC='Longitudinal_MultiRun'
				SES=`basename $SCAN | cut -d '_' -f2 | cut -d '-' -f2`
				if [[ $SCAN == *"run-"* ]] ; then
					RUN=`basename $SCAN | cut -d '_' -f4 | cut -d '-' -f2`
					DIR_ROOT[i]=$DIR_PROJECT/apps/xcp-feat/pipe-${LABEL_PIPE}X${OPT_THRESH_TYPE}_task-${TASK_LABEL}_run-${RUN}_${CONTRAST}
					TSV_FILE=`find $DIR_PROJECT/bids -iname sub-${SUBJECT}_ses-${SES}_task-${TASK_LABEL}_run-${RUN}_events.tsv`
				else
					RUN=01
					DIR_ROOT=[i]$DIR_PROJECT/apps/xcp-feat/pipe-${LABEL_PIPE}X${OPT_THRESH_TYPE}_task-${TASK_LABEL}_run-${RUN}_${CONTRAST}
					TSV_FILE=`find $DIR_PROJECT/bids -iname sub-${SUBJECT}_ses-${SES}_task-${TASK_LABEL}_events.tsv`
				fi
			fi

			echo "Edit And Relabel Event Files for Analysis"
			if [[ -f $TSV_FILE && `head -n1 $TSV_FILE | tr '\t' '_'` == *"${CONTRAST}"*  || -f $DESIGN_CONFIG ]] ; then
				cat $TSV_FILE | tr '\t' ',' | csvcut -c "onset","duration",${CONTRAST} | tail -n +2 | tr ',' '\t' > ${TSV_FILE}_TEMP
				FILE_COHORT=${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_cohort.csv
				mkdir -p ${DIR_ROOT[i]}/logs/${TODAY}/
				INDEX_CONTRAST=0
				for CONDITION in `cat ${TSV_FILE}_TEMP | awk '{print $3}' | sort | uniq` ; do
					INDEX_CONTRAST=$((INDEX_CONTRAST + 1))
					if [[ $DATA_STRUC != "Longitudinal"* ]] ; then
						COHORT_HEADER=`echo "id0,img,task_design"`
						COHORT_CONTENT=`echo "sub-${SUBJECT},${SCAN},${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_design.fsf"`
						FILE_EVENT=${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_lab-${CONDITION}_evs-${INDEX_CONTRAST}.txt
						FILE_DESIGN=${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_design.fsf
					else						
						COHORT_HEADER=`echo "id0,id1,img,task_design"`
						COHORT_CONTENT=`echo "sub-${SUBJECT},ses-${SES},${SCAN},${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_ses-${SES}_design.fsf"`
						FILE_EVENT=${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_ses-${SES}_lab-${CONDITION}_evs-${INDEX_CONTRAST}.txt
						FILE_DESIGN=${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}_ses-${SES}_design.fsf
					fi
					if [[ ! -f $FILE_COHORT ]] ; then
						echo $COHORT_HEADER > $FILE_COHORT
					fi
					if ! grep ${COHORT_CONTENT} "${FILE_COHORT}" ; then
						echo $COHORT_CONTENT >> ${FILE_COHORT}
					fi
					if [[ $INDEX_CONTRAST == 1 ]] ; then
						cp $DESIGN_CONFIG $FILE_DESIGN
					fi
					cat $FILE_DESIGN | sed s@"EV${INDEX_CONTRAST}_FILE"@"${FILE_EVENT}"@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
					cat ${TSV_FILE}_TEMP | grep ${CONDITION} | sed s@$CONDITION@$INDEX_CONTRAST@g > $FILE_EVENT
				done
				echo $COHORT_CONTENT >> $FILE_COHORT ; rm ${TSV_FILE}_TEMP
				cat $DIR_TOOLBOX/bids_apps/dependencies/designs_xcp/task.dsn | sed s@'rps'@"${PIPE}"@g > ${DIR_ROOT[i]}/logs/${TODAY}/design.dsn
				TR=$(cat `find $DIR_PROJECT/bids/sub-${SUBJECT} -iname *${TASK_LABEL}*json | head -n1` | grep RepetitionTime | awk '{print $2}' | sed s@','@''@g)
				cat $FILE_DESIGN | sed s@TEMPORAL_RESOLUTION@${TR}@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
				cat $FILE_DESIGN | sed s@DIR_OUTPUT@\""${DIR_ROOT[i]}"\"@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
				cat $FILE_DESIGN | sed s@THRESH_TYPE@"${THRESH_TYPE}"@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
				cat $FILE_DESIGN | sed s@TEMPLATE_SPACE@"${TEMPLATE_SPACE}"@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
				cat $FILE_DESIGN | sed s@NIFTI_PREPROC@\""${DIR_PROJECT}/apps/fmriprep/${SCAN}"\"@g | sed s@".nii.gz"@""@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
				cat $FILE_DESIGN | sed s@NUMBER_VOLUMES@`fslinfo $DIR_PROJECT/apps/fmriprep/$SCAN | grep ^dim4 | awk '{print $2}'`@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
				cat $FILE_DESIGN | sed s@TOTAL_VOXELS@`fslstats $DIR_PROJECT/apps/fmriprep/$SCAN -V | cut -d ' ' -f2 | cut -d '.' -f1`@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
				if [[ -f $OPT_THRESH_MASK ]] ; then
					cat $FILE_DESIGN | sed s@"THRESH_MASK"@"${OPT_THRESH_MASK}"@g | sed s@'.nii.gz'@''@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
				else
					cat $FILE_DESIGN | sed s@"THRESH_MASK"@""@g > ${FILE_DESIGN}_TEMP ; mv ${FILE_DESIGN}_TEMP ${FILE_DESIGN}
				fi
			else
				continue
			fi
			mkdir -p ${DIR_ROOT[i]}/workflows/single_subject_${SUBJECT}
			chmod ug+wrx ${DIR_ROOT[i]}/logs/${TODAY}/sub-${SUBJECT}*
			(( i++ ))
		done

		for DIR_ROOT in ${DIR_ROOT[@]} ; do
			echo "Executing XCPEngine Pipeline"
			echo "singularity run --cleanenv `ls -t $DIR_TOOLBOX/bids_apps/dependencies/xcpengine_v*.simg | head -n1` \
				-d ${DIR_ROOT}/logs/${TODAY}/design.dsn \
				-c ${FILE_COHORT} \
				-o ${DIR_ROOT} \
				-i ${DIR_ROOT}/workflows/single_subject_${SUBJECT} \
				-r ${DIR_PROJECT}/apps/fmriprep \
				-t 2" | tr '\t' '#' | sed s@'#'@''@g > ${DIR_ROOT}/logs/${TODAY}/sub-${SUBJECT}_command.sh

			chmod -R 775 ${DIR_ROOT}/logs/${TODAY}/sub-${SUBJECT}_command.sh

			$DIR_ROOT/logs/${TODAY}/sub-${SUBJECT}_command.sh > /dev/null 2>&1
		
			echo "Executing XCPEngine Pipeline"
			if [[ ! -f `find $DIR_ROOT/sub-${SUBJECT} -iname *zstat1.nii.gz | head -n1` ]] ; then
				chmod ug-x $DIR_ROOT/logs/${TODAY}/sub-${SUBJECT}_*		
				mkdir -p $DIR_ROOT/workflows/problematic_wf_${TODAY}
				mv $DIR_ROOT/sub-${SUBJECT} $DIR_ROOT/workflows/problematic_wf_${TODAY}
			else
				chmod -R 775 $DIR_ROOT/sub-${SUBJECT}
				find ${DIR_ROOT}/sub-${SUBJECT} -size 0 -delete
				rm -rf ${DIR_ROOT}/workflows/single_subject_${SUBJECT}
			fi
		done
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
