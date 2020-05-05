#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 64
#$ -R y
#$ -ckpt restart
################

module load fsl/6.0.1

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/xcpengine
DIR_LOCAL_APPS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/apps
DIR_LOCAL_OUT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux

OPT_INCLUSION_FILE=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/Audit_Master_ConteMRI.csv 
OPT_INCLUSION_VAR=Inclusion_Cross

OPT_MANUAL_NCOMP=NULL

#################################################################################
##### Read in Processed/Denoised fMRI Scans from XCPEngine Output Directory #####
#################################################################################

for DIR_PIPE in $DIR_LOCAL_APPS/xcpengine/fc-* ; do
	LABEL_PIPE=`basename $DIR_PIPE | sed s@'fc-'@''@g`
	ALL_SCANS=`find "$(pwd -P)" $DIR_PIPE -iname *_residualised.nii.gz`
	for LABEL_TASK in `echo $ALL_SCANS | tr '/' '\n' | grep ^task | sort -u` ; do
		TODAY=`date "+%Y%m%d"`
		INPUT_SCANS=`echo $ALL_SCANS | tr ' ' '\n' | grep "/${LABEL_TASK}/"`
		DIR_OUTPUT="$DIR_LOCAL_OUT/GroupICA/$(echo $LABEL_TASK | sed s@'task-'@'func-'@g)"
		mkdir -p ${DIR_OUTPUT} ${DIR_OUTPUT}/logs

		COHORT_FILE=${DIR_OUTPUT}/logs/n$(echo $INPUT_SCANS | wc -w)_Cohort_${TODAY}.csv
		echo $INPUT_SCANS | tr ' ' '\n' > ${COHORT_FILE}

##########################################################
##### Select Only Subset of Input Scans If Requested #####
##########################################################

		if [[ -f ${OPT_INCLUSION_FILE} && ! -z `cat $OPT_INCLUSION_FILE | grep $OPT_INCLUSION_VAR` ]] ; then

			if [[ $(echo $INPUT_SCANS | tr ' ' '_') != *"ses-"* ]] ; then

				cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,ses,${OPT_INCLUSION_VAR}

			elif [[ $(echo $SCANS | tr ' ' '_') == *"ses-"* ]] ; then
				cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,ses,${OPT_INCLUSION_VAR} | grep 1$ > $COHORT_FILE
				for ROW in `cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,ses,${OPT_INCLUSION_VAR} | grep 1$` ; do
					SUB=`echo $ROW | cut -d ',' -f1`
					SES=`echo $ROW | cut -d ',' -f2`
					SCAN=`echo $INPUT_SCANS | tr ' ' '\n' | grep "/sub-${SUB}_ses-${SES}_"`
					NEW_ROW=`echo $ROW | sed s@${ROW}@${ROW},${SCAN}@g`
					cat ${COHORT_FILE} | sed s@${ROW}@${NEW_ROW}@g > ${COHORT_FILE}_NEW 
					mv ${COHORT_FILE}_NEW ${COHORT_FILE}
				done
				cat $COHORT_FILE | grep -v .nii.gz | cut -d ',' -f1,2 > ${COHORT_FILE}_MISSING
				cat $COHORT_FILE | grep .nii.gz | awk -F "\"*,\"*" '{print $4}' > ${COHORT_FILE}_SELECT
				MISS=`echo ${COHORT_FILE}_MISSING | sed s@n$(echo $INPUT_SCANS | wc -w)@n$(cat ${COHORT_FILE}_MISSING | wc  -l)@g`
				SELECT=`echo ${COHORT_FILE}_SELECT | sed s@n$(echo $INPUT_SCANS | wc -w)@n$(cat ${COHORT_FILE}_SELECT | wc  -l)@g`
				mv ${COHORT_FILE}_MISSING $(echo $MISS | sed s@'_MISSING'@''@g | sed s@'Cohort'@'Missing'@g)
				mv ${COHORT_FILE}_SELECT $(echo $SELECT | sed s@'_SELECT'@''@g)
				mv ${COHORT_FILE}_NEW $COHORT_FILE
				rm ${COHORT_FILE}
			else
				exit 0
			fi
		fi

melodic -i /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux/Prelim_GroupICA_Workflow/cohort.txt \
	-o /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux/Prelim_GroupICA_Workflow/TWO \
	-m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz \
	-a concat \
	--report \
	--Oall \
	-v

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
