#!/bin/bash
#$ -N GroupICA
#$ -q yassalab,free*
#$ -pe openmp 24-64
#$ -R y
#$ -ckpt restart
################

DIR_TOOLBOX=$1
DIR_PROJECT=$2
TEMPLATE_SPACE=$3
TASK_LABELS=$4
OPT_MANUAL_NCOMPS=$5
OPT_INCLUSION_FILE=$6
OPT_INCLUSION_VAR=$7
OPT_DUAL_REGRESS=$8

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 fsl/6.0.1
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
				sed -i "s@^${ROW}@${SCAN}@g" cohort.csv > /dev/null 2>&1
			done
		elif [[ $(echo $SCANS_PREPROC | tr ' ' '_') == *"ses-"* ]] ; then
			cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,ses,${OPT_INCLUSION_VAR} | grep 1$ > cohort.csv
			for ROW in `cat ${OPT_INCLUSION_FILE} |  csvcut -c sub,ses,${OPT_INCLUSION_VAR} | grep 1$` ; do
				SUB=`echo $ROW | cut -d ',' -f1`
				SES=`echo $ROW | cut -d ',' -f2`
				SCAN=`echo $SCANS_PREPROC | tr ' ' '\n' | grep "/sub-${SUB}_ses-${SES}_"`
				sed -i "s@^${ROW}@${SCAN}@g" cohort.csv > /dev/null 2>&1
			done
		else
			exit 0
		fi
		cat cohort.csv | grep .nii.gz > cohort_FINAL.csv 
		echo "IF PREPROC SCANS ARE MISSING THEY WILL BE PRINTED HERE: `cat cohort.csv | grep -v .nii.gz`"
		if [[ ! -z $OPT_INCLUSION_VAR && ${OPT_INCLUSION_VAR} == *'_Inclusion' ]] ; then
			FILE_COHORT=$DIR_PIPE/group/n$(cat cohort_FINAL.csv | wc -l)_$(echo $OPT_INCLUSION_VAR | cut -d '_' -f1).gica/cohort_${TODAY}.csv
		else
			FILE_COHORT=$DIR_PIPE/group/n$(cat cohort_FINAL.csv | wc -l)_$(basename $DIR_PROJECT | cut -d '/' -f1)_subsample.gica/cohort_${TODAY}.csv
		fi
		mkdir -p $(dirname $FILE_COHORT)
		mv cohort_FINAL.csv $FILE_COHORT ; rm cohort.csv
	else
		FILE_COHORT=$DIR_PIPE/group/n$(echo $SCANS_PREPROC | wc -w)_$(basename $DIR_PROJECT | cut -d '/' -f1)_fullsample.gica/cohort_${TODAY}.csv
		echo $SCANS_PREPROC | tr ' ' '\n' > $FILE_COHORT
	fi

####################################################################################
##### Define Project-Specific Arguements and Resample Input Images to Template #####
####################################################################################

	if [[ -z "${OPT_MANUAL_NCOMPS##[0-9]*}" || ${OPT_MANUAL_NCOMPS} == "pca" ]]  ; then
		NCOMP_ITERATIONS=`echo ${OPT_MANUAL_NCOMPS}`
	else
		NCOMP_ITERATIONS=$(echo `seq 20 1 30` "pca")
	fi

	if [[ ! -f $TEMPLATE_SPACE ]] ; then
		TEMPLATE_SPACE=$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz
	fi

	NIFTI=$(head -n1 $FILE_COHORT)
	FILE_DIM1=$(fslinfo $NIFTI | grep ^dim1 | awk {'print $2'})
	FILE_DIM2=$(fslinfo $NIFTI | grep ^dim2 | awk {'print $2'})
	FILE_DIM3=$(fslinfo $NIFTI | grep ^dim3 | awk {'print $2'})
	TMPL_DIM1=$(fslinfo $TEMPLATE_SPACE | grep ^dim1 | awk {'print $2'})
	TMPL_DIM2=$(fslinfo $TEMPLATE_SPACE | grep ^dim2 | awk {'print $2'})
	TMPL_DIM3=$(fslinfo $TEMPLATE_SPACE | grep ^dim3 | awk {'print $2'})
	if [[ $FILE_DIM1 != $TMPL_DIM1 || $FILE_DIM2 != $TMPL_DIM2 || $FILE_DIM3 != $TMPL_DIM3 ]] ; then
		module load mrtrix/3.0_RC3
		mrresize -size ${FILE_DIM1},${FILE_DIM2},${FILE_DIM3} ${TEMPLATE_SPACE} ${TEMPLATE_SPACE} -force
	fi
	cp ${TEMPLATE_SPACE} `dirname $FILE_COHORT`

###############################################################################
##### Execute FSL MELODIC Group ICA Commands & Dual Regression if Enabled #####
###############################################################################

	GRPICA_COMMAND=$(echo `dirname $FILE_COHORT`/command_grpica_${TODAY}.sh)
	DUALREG_COMMAND=$(echo `dirname $FILE_COHORT | sed s@'.gica'@'.dreg'@g`/command_dualreg_${TODAY}.sh)
	for NCOMP in $NCOMP_ITERATIONS ; do
		mkdir -p $(echo $(dirname $FILE_COHORT)/dim-${NCOMP})
		ARG_NCOMP=$(echo -d ${NCOMP})
		if [[ $NCOMP == "pca" ]] ; then
			unset ARG_NCOMP
		fi

		echo "melodic -i ${FILE_COHORT} \
			-o $(echo `dirname $FILE_COHORT`/dim-${NCOMP}) \
			-m $TEMPLATE_SPACE \
			-a concat \
			--report \
			--Oall \
			--nobet \
			--mmthresh=0.5 \
			-v ${ARG_NCOMP}" | tr '\t' '#' | sed s@'#'@''@g > ${GRPICA_COMMAND}

		chmod ug+wrx ${GRPICA_COMMAND}

		${GRPICA_COMMAND} > `echo $GRPICA_COMMAND | sed s@"command"@"dim-${NCOMP}/log"@g | sed s@'.sh'@'.txt'@g` 2>&1

		rm `echo $(dirname $FILE_COHORT)/dim-${NCOMP}/log.txt`
		mkdir -p $(echo $(dirname $FILE_COHORT)/dim-${NCOMP}/smooths)
		for MAP in `find $(echo $(dirname $FILE_COHORT)/dim-${NCOMP}) | grep 'stats/probmap'` ; do
			fslmaths $MAP -s 1 $(echo $MAP | sed s@"probmap_"@"probmap_smth-1_"@g | sed s@'stats'@'smooths'@g)
			fslmaths $MAP -s 2 $(echo $MAP | sed s@"probmap_"@"probmap_smth-2_"@g | sed s@'stats'@'smooths'@g)
			fslmaths $MAP -s 3 $(echo $MAP | sed s@"probmap_"@"probmap_smth-3_"@g | sed s@'stats'@'smooths'@g)
			fslmaths $MAP -s 4 $(echo $MAP | sed s@"probmap_"@"probmap_smth-4_"@g | sed s@'stats'@'smooths'@g)
			fslmaths $MAP -s 5 $(echo $MAP | sed s@"probmap_"@"probmap_smth-5_"@g | sed s@'stats'@'smooths'@g)
		done

		if [[ ${OPT_DUAL_REGRESS} == "TRUE" ]] ; then

			NIFTI_GRPICA_OUTPUT=$(echo `dirname $GRPICA_COMMAND`/dim-${NCOMP}/melodic_IC.nii.gz)
			DIR_DUALREG_OUTPUT=$(echo `dirname $FILE_COHORT | sed s@.gica@.dreg@g`/dim-${NCOMP})
			mkdir -p $DIR_DUALREG_OUTPUT

			echo "dual_regression $NIFTI_GRPICA_OUTPUT 1 -1 5000 $DIR_DUALREG_OUTPUT `cat $FILE_COHORT | tr '\n' ' ' | grep -v local`" > ${DUALREG_COMMAND}

			chmod ug+wrx ${DUALREG_COMMAND} ; unset SGE_ROOT ; module purge ; module load fsl/6.0.1

			${DUALREG_COMMAND} > `echo $DUALREG_COMMAND | sed s@"command"@"dim-${NCOMP}/log"@g | sed s@'.sh'@'.txt'@g` 2>&1

			module load anaconda/2.7-4.3.1 singularity/3.3.0

		fi
		chmod -R ug+wrx `echo $(dirname $FILE_COHORT)/dim-${NCOMP}`	
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
