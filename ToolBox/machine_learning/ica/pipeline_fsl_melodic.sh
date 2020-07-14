#!/bin/bash
#$ -N GroupICA
#$ -q yassalab,free*
#$ -pe openmp 16-64
#$ -R y
#$ -ckpt restart
################

DIR_TOOLBOX=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One
TEMPLATE_SPACE=$DIR_TOOLBOX/bids_apps/dependencies/atlases/tpl-MNI152NLin6Asym_res-02_desc-brain_mask.nii.gz
TASK_LABELS="pipe-aroma_task-REST_run-1"
OPT_MANUAL_NCOMPS=$(echo `seq 5 30` "pca")
OPT_INCLUSION_FILE=${DIR_PROJECT}/datasets/aggregate_df.csv 
OPT_INCLUSION_VAR=IntraFlux_Inclusion

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3 fsl/6.0.1
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local
rm GroupICA.*

#################################################################################
##### Read in Processed/Denoised fMRI Scans from XCPEngine Output Directory #####
#################################################################################

TODAY=`date "+%Y%m%d"`
for TASK_LABEL in $TASK_LABELS ; do
	DIR_PIPE=$DIR_PROJECT/apps/xcp-fcon/${TASK_LABEL}
	SCANS_PREPROC=`find $DIR_PIPE -iname *_residualised.nii.gz`

##########################################################
##### Select Only Subset of Input Scans If Requested #####
##########################################################

	if [[ -f ${OPT_INCLUSION_FILE} && ! -z `cat $OPT_INCLUSION_FILE | grep $OPT_INCLUSION_VAR` ]] ; then
		if [[ $(echo $SCANS_PREPROC | tr ' ' '_') != *"ses-"* ]] ; then
			cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,${OPT_INCLUSION_VAR} | grep 1$ > cohort.csv
			for ROW in `cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,${OPT_INCLUSION_VAR} | grep 1$` ; do
				SUB=`echo $ROW | cut -d ',' -f1`
				SCAN=`echo $SCANS_PREPROC | tr ' ' '\n' | grep "/sub-${SUB}_"`
				sed -i "s@^${ROW}@${SCAN}@g" cohort.csv
			done
		elif [[ $(echo $SCANS_PREPROC | tr ' ' '_') == *"ses-"* ]] ; then
			cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,ses,${OPT_INCLUSION_VAR} | grep 1$ > cohort.csv
			for ROW in `cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,ses,${OPT_INCLUSION_VAR} | grep 1$` ; do
				SUB=`echo $ROW | cut -d ',' -f1`
				SES=`echo $ROW | cut -d ',' -f2`
				SCAN=`echo $SCANS_PREPROC | tr ' ' '\n' | grep "/sub-${SUB}_ses-${SES}_"`
				sed -i "s@^${ROW}@${SCAN}@g" cohort.csv
				done
		else
			exit 0
		fi
		cat cohort.csv | grep .nii.gz > cohort_FINAL.csv 
		echo "IF PREPROC SCANS ARE MISSING THEY WILL BE PRINTED HERE: `cat cohort.csv | grep -v .nii.gz`"
		if [[ ! -z $OPT_INCLUSION_VAR && ${OPT_INCLUSION_VAR} == *'_Inclusion' ]] ; then
			FILE_COHORT=$DIR_PIPE/group/n$(cat cohort_FINAL.csv | wc -l)_$(echo $OPT_INCLUSION_VAR | cut -d '_' -f1).grpica/logs/cohort_${TODAY}.csv
		else
			FILE_COHORT=$DIR_PIPE/group/n$(cat cohort_FINAL.csv | wc -l)_$(basename $DIR_PROJECT | cut -d '/' -f1).grpica/logs/cohort_${TODAY}.csv
		fi
		mkdir -p $(dirname $FILE_COHORT)
		mv cohort_FINAL.csv $FILE_COHORT ; rm cohort.csv
	fi

####################################################################################
##### Define Project-Specific Arguements and Resample Input Images to Template #####
####################################################################################

	if [[ -z "${OPT_MANUAL_NCOMP##[0-9]*}" || ${OPT_MANUAL_NCOMP} == "pca" ]]  ; then
		NCOMP_ITERATIONS=${OPT_MANUAL_NCOMP}
	else
		NCOMP_ITERATIONS=$(echo `seq 12 1 32` "pca")
	fi
	if [[ ! -f TEMPLATE_SPACE ]] ; then
		TEMPLATE_SPACE=$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz
	fi
	module load mrtrix/3.0_RC3
	for NIFTI in $SCANS_PREPROC ; do
		FILE_DIM1=$(fslinfo $NIFTI | grep ^dim1 | awk {'print $2'})
		FILE_DIM2=$(fslinfo $NIFTI | grep ^dim2 | awk {'print $2'})
		FILE_DIM3=$(fslinfo $NIFTI | grep ^dim3 | awk {'print $2'})
		TMPL_DIM1=$(fslinfo $TEMPLATE_SPACE | grep ^dim1 | awk {'print $2'})
		TMPL_DIM2=$(fslinfo $TEMPLATE_SPACE | grep ^dim2 | awk {'print $2'})
		TMPL_DIM3=$(fslinfo $TEMPLATE_SPACE | grep ^dim3 | awk {'print $2'})
		if [[ $FILE_DIM1 != $TMPL_DIM1 || $FILE_DIM2 != $TMPL_DIM2 || $FILE_DIM3 != $TMPL_DIM3 ]] ; then
			mrresize -size ${TMPL_DIM1},${TMPL_DIM2},${TMPL_DIM3} ${NIFTI} ${NIFTI} -force
		fi
	done

##################################################
##### Execute FSL MELODIC Group ICA Commands #####
##################################################

	GRPICA_COMMAND=$(echo `dirname $FILE_COHORT`/command_grpica_${TODAY}.sh)
	GRPICA_LOG=`echo $GRPICA_COMMAND | sed s@"command"@"log"@g | sed s@'.sh'@'.txt'@g`
	DUALREG_COMMAND=$(echo `dirname $FILE_COHORT`/command_dualreg_${TODAY}.sh)
	DUALREG_LOG=`echo $DUALREG_COMMAND | sed s@"command"@"log"@g | sed s@'.sh'@'.txt'@g`
	for NCOMP in $NCOMP_ITERATIONS ; do
		ARG_NCOMP=$(echo -d ${NCOMP})
		if [[ $NCOMP == "pca" ]] ; then
			unset ARG_NCOMP
		fi

		echo "melodic -i ${FILE_COHORT} \
			-o `dirname $FILE_COHORT | sed s@'logs'@"dim-${NCOMP}"@g` \
			-m $TEMPLATE_SPACE \
			-a concat \
			--report \
			--Oall \
			--nobet \
			--mmthresh=0.5 \
			-v ${ARG_NCOMP}" | tr '\t' '#' | sed s@'#'@''@g > ${GRPICA_COMMAND}

		chmod ug+wrx ${GRPICA_COMMAND}

		${GRPICA_COMMAND} > ${GRPICA_LOG} 2>&1

		NIFTI_GRPICA_OUTPUT=$(echo `dirname $FILE_COHORT` | sed s@'logs'@"dim-${NCOMP}/melodic_IC.nii.gz"@g)
		DIR_DUALREG_OUTPUT=$(dirname $FILE_COHORT | sed s@'grpica/logs'@"dualreg/dim-${NCOMP}"@g)
		mkdir -p $DIR_DUALREG_OUTPUT

		echo "dual_regression $NIFTI_GRPICA_OUTPUT 1 -1 50000 $DIR_DUALREG_OUTPUT `cat $FILE_COHORT | tr '\n' ' ' | grep -v local`" > ${DUALREG_COMMAND}

		chmod ug+wrx ${DUALREG_COMMAND} ; unset SGE_ROOT

		${DUALREG_COMMAND} > ${DUALREG_LOG} 2>&1

		chmod -R ug+wrx $(echo $DIR_DUALREG_OUTPUT | sed s@'.dualreg'@'.*'@g)
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
