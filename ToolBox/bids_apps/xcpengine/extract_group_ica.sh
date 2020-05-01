#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 4
#$ -R y
#$ -ckpt restart
################

<<SKIP

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/xcpengine
DIR_LOCAL_APPS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/apps
DIR_LOCAL_DATA=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets

OPT_INCLUSION_FILE=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/Audit_Master_ConteMRI.csv 
OPT_INCLUSION_VAR=Inclusion_Cross

####################################################################################################
##### Find All Processed Scans And Extract Signal Using Every Available Atlas For Each Subject #####
####################################################################################################

for DIR_PIPE in $DIR_LOCAL_APPS/xcpengine/fc-* ; do
	LABEL_PIPE=`basename $PIPE | sed s@'fc-'@''@g`
	ALL_SCANS=`find "$(pwd -P)" $DIR_PIPE -iname *_residualised.nii.gz`
	for LABEL_TASK in `echo $ALL_SCANS | tr '/' '\n' | grep ^task | sort -u` ; do
		DIR_OUTPUT="$DIR_LOCAL_DATA/$(echo $LABEL_TASK | sed s@'task-'@'func-'@g)/ica"
		mkdir -p ${DIR_OUTPUT}
		INPUT_SCANS=`echo $ALL_SCANS | tr ' ' '\n' | grep $TASK`
SKIP

		




	
melodic -i /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux/test.txt \
	-o /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux/WORKING \
	--tr=2.5 \
	--nobet \
	-a concat \
	-m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz \
	--report \
	--Oall \
	-d 5




<<SKIP


	PIPE_LABEL=`basename $PIPE`
	REGRESSEDSCANS=`find ${PIPE} -type f -print | grep "_residualised.nii.gz"`
	echo "" > $LOG
	echo "#####################################################################################" >> $LOG
	echo " `ls $REGRESSEDSCANS | wc -l` Total Processed Scans Were Found For Pipeline: ${PIPE} " >> $LOG
	echo "#####################################################################################" >> $LOG


done


`find $DIR_LOCAL_APPS/xcpengine -maxdepth 3 -iname directory_structure_*.csv` ; do

	TASK=`basename $OUTPUT  | cut -d '_' -f3 | cut -d '.' -f1`
	PIPE=`echo $OUTPUT | sed s@"${DIR_LOCAL_APPS}/xcpengine/"@@g | cut -d '/' -f1`

	if ! grep -q MultiRun $OUTPUT ; then
		echo TEST
	fi


done

SKIP

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
