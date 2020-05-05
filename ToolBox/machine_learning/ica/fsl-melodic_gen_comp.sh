#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 16-64
#$ -R y
#$ -ckpt restart
################

module load fsl/6.0.1

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/xcpengine
DIR_LOCAL_APPS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/apps
DIR_LOCAL_OUT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux

OPT_TASK_LABEL=task-REST_run-01

OPT_INCLUSION_FILE=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/Audit_Master_ConteMRI.csv 
OPT_INCLUSION_VAR=Inclusion_Cross
OPT_MANUAL_NCOMP=NULL

#################################################################################
##### Read in Processed/Denoised fMRI Scans from XCPEngine Output Directory #####
#################################################################################

for DIR_PIPE in $DIR_LOCAL_APPS/xcpengine/fc-* ; do
	LABEL_PIPE=`basename $DIR_PIPE | sed s@'fc-'@''@g`
	ALL_SCANS=`find "$(pwd -P)" $DIR_PIPE -iname *_residualised.nii.gz`
	if [[ ! -z ${OPT_TASK_LABEL} && ${OPT_TASK_LABEL} == "task-"* ]] ; then
		LABELS_TASKS=${OPT_TASK_LABEL}
	else
		LABELS_TASKS=`echo ${ALL_SCANS} | tr '/' '\n' | grep ^task | sort -u` 
	fi
	for LABEL_TASK in ${LABELS_TASKS} ; do
		INPUT_SCANS=`echo $ALL_SCANS | tr ' ' '\n' | grep "/${LABEL_TASK}/"`
		DIR_OUTPUT="$DIR_LOCAL_OUT/GroupICA/fc-${LABEL_PIPE}_$(echo $LABEL_TASK | sed s@'task-'@'func-'@g)"
		TODAY=`date "+%Y%m%d"` ; mkdir -p ${DIR_OUTPUT} ${DIR_OUTPUT}/logs/${TODAY}
		COHORT_FILE=${DIR_OUTPUT}/logs/${TODAY}/n$(echo $INPUT_SCANS | wc -w)_Cohort_${LABEL_PIPE}.txt
		echo $INPUT_SCANS | tr ' ' '\n' > ${COHORT_FILE}

##########################################################
##### Select Only Subset of Input Scans If Requested #####
##########################################################

		if [[ -f ${OPT_INCLUSION_FILE} && ! -z `cat $OPT_INCLUSION_FILE | grep $OPT_INCLUSION_VAR` ]] ; then
			if [[ $(echo $INPUT_SCANS | tr ' ' '_') != *"ses-"* ]] ; then
				cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,${OPT_INCLUSION_VAR} | grep 1$ > $COHORT_FILE
				for ROW in `cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,${OPT_INCLUSION_VAR} | grep 1$` ; do
					SUB=`echo $ROW | cut -d ',' -f1`
					SCAN=`echo $INPUT_SCANS | tr ' ' '\n' | grep "/sub-${SUB}_"`
					NEW_ROW=`echo $ROW | sed s@${ROW}@${ROW},${SCAN}@g`
					cat ${COHORT_FILE} | sed s@${ROW}@${NEW_ROW}@g > ${COHORT_FILE}_NEW 
					mv ${COHORT_FILE}_NEW ${COHORT_FILE}
				done
			elif [[ $(echo $INPUT_SCANS | tr ' ' '_') == *"ses-"* ]] ; then
				cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,ses,${OPT_INCLUSION_VAR} | grep 1$ > $COHORT_FILE
				for ROW in `cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,ses,${OPT_INCLUSION_VAR} | grep 1$` ; do
					SUB=`echo $ROW | cut -d ',' -f1`
					SES=`echo $ROW | cut -d ',' -f2`
					SCAN=`echo $INPUT_SCANS | tr ' ' '\n' | grep "/sub-${SUB}_ses-${SES}_"`
					NEW_ROW=`echo $ROW | sed s@${ROW}@${ROW},${SCAN}@g`
					cat ${COHORT_FILE} | sed s@${ROW}@${NEW_ROW}@g > ${COHORT_FILE}_NEW 
					mv ${COHORT_FILE}_NEW ${COHORT_FILE}
				done
			else
				exit 0
			fi
			cat $COHORT_FILE | grep -v .nii.gz | cut -d ',' -f1,2 > ${COHORT_FILE}_MISSING
			cat $COHORT_FILE | grep .nii.gz | awk -F "\"*,\"*" '{print $4}' > ${COHORT_FILE}_SELECT
			MISS=`echo ${COHORT_FILE}_MISSING | sed s@n$(echo $INPUT_SCANS | wc -w)@n$(cat ${COHORT_FILE}_MISSING | wc  -l)@g`
			SELECT=`echo ${COHORT_FILE}_SELECT | sed s@n$(echo $INPUT_SCANS | wc -w)@n$(cat ${COHORT_FILE}_SELECT | wc  -l)@g`
			mv ${COHORT_FILE}_MISSING $(echo $MISS | sed s@'_MISSING'@''@g | sed s@'Cohort'@'Cohort_Missing'@g)
			mv ${COHORT_FILE}_SELECT $(echo $SELECT | sed s@'_SELECT'@''@g) ; rm ${COHORT_FILE} 
			COHORT_FILE=$(echo $SELECT | sed s@'_SELECT'@''@g)
		fi

##########################################################
##### Select Only Subset of Input Scans If Requested #####
##########################################################

		if [[ -z "${OPT_MANUAL_NCOMP##[0-9]*}" || ${OPT_MANUAL_NCOMP} == "pca" ]]  ; then
			NCOMP_ITERATIONS=${OPT_MANUAL_NCOMP}
		else
			NCOMP_ITERATIONS=$(echo `seq 6 2 30` "pca")
		fi
		for NCOMP in $NCOMP_ITERATIONS ; do
			COMMAND_FILE=$(echo `dirname $COHORT_FILE`/dim-${NCOMP}_Command_${TODAY}.sh)
			LOG_FILE=`echo $COMMAND_FILE | sed s@"Command"@"Log"@g | sed s@'.sh'@'.txt'@g`
			ARG_NCOMP=$(echo -d ${NCOMP})
			if [[ $NCOMP == "pca" ]] ; then
				unset ARG_NCOMP
			fi
			echo "melodic -i ${COHORT_FILE} \
				-o $DIR_OUTPUT/dim-${NCOMP} \
				-m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz \
				-a concat \
				--report \
				--Oall \
				-v ${ARG_NCOMP}" | tr '\t' '#' | sed s@'#'@''@g > ${COMMAND_FILE}

			chmod ug+wrx ${COMMAND_FILE}

			${COMMAND_FILE} > ${LOG_FILE} 2>&1

		done
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
