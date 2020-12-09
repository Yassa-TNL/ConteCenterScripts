#! /bin/bash
############

DIR_PROJECT=/dfs7/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux
DIR_STUDY=/dfs7/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 fsl/6.0.1 afni
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

########################################################
### Run Dual Regression and Extract Network Strength ###
########################################################

FILE_COHORT=$DIR_PROJECT/n138_IntraFlux.dualreg/cohort_sm3_20200802.csv
mkdir -p $DIR_PROJECT/n138_IntraFlux.alff/masks $DIR_PROJECT/n138_IntraFlux.time
fslsplit $DIR_PROJECT/n138_IntraFlux.gica/dim-12_sm3/melodic_IC.nii.gz 
mv vol0*.nii.gz $DIR_PROJECT/n138_IntraFlux.alff/masks

for NCOMP in `seq 1 1 12` ; do
	MASK=`echo $DIR_PROJECT/n138_IntraFlux.alff/masks/vol0*.nii.gz | cut -d ' ' -f${NCOMP}`
	for INPUT in `cat $FILE_COHORT | cut -d '/' -f10,11 | sort | uniq` ; do
		SUB=`echo $INPUT | cut -d '/' -f1 | sed s@'sub-'@''@g`
		SES=`echo $INPUT | cut -d '/' -f2 | sed s@'ses-'@''@g`
		INPUT1=$DIR_STUDY/apps/xcp-fcon/pipe-aroma_task-REST_run-1/sub-${SUB}/ses-${SES}/alff/*_alff.nii.gz
		ALFF1=`fslmeants -i $INPUT1 -m $MASK -w`
		INPUT2=$DIR_STUDY/apps/xcp-fcon/pipe-aroma_task-AMG/sub-${SUB}/ses-${SES}/alff/*_alff.nii.gz
		ALFF2=`fslmeants -i $INPUT2 -m $MASK -w`
		INPUT3=$DIR_STUDY/apps/xcp-fcon/pipe-aroma_task-REST_run-2/sub-${SUB}/ses-${SES}/alff/*_alff.nii.gz
		ALFF3=`fslmeants -i $INPUT3 -m $MASK -w`
		echo $ALFF1 $ALFF2 $ALFF3 | tr ' ' '\n' > $DIR_PROJECT/n138_IntraFlux.alff/sub-${SUB}_net-${NCOMP}.csv
		NIFTI1=$(echo /dfs7`cat $FILE_COHORT | grep $INPUT | grep task-REST_run-1`)
		TIME1=`fslmeants -i $NIFTI1 -m $MASK -w`
		NIFTI2=$(echo /dfs7`cat $FILE_COHORT | grep $INPUT | grep task-REST_run-1`)
		TIME2=`fslmeants -i $NIFTI2 -m $MASK -w`
		NIFTI3=$(echo /dfs7`cat $FILE_COHORT | grep $INPUT | grep task-REST_run-1`)
		TIME3=`fslmeants -i $NIFTI3 -m $MASK -w`	
		echo ${TIME1},${TIME2},${TIME3} | tr ',' '\n' > $DIR_PROJECT/n138_IntraFlux.time/sub-${SUB}_net-${NCOMP}.csv
	done

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
