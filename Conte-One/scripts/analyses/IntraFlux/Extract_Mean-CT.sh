#! /bin/bash
############

DIR_TOOLBOX=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

module load freesurfer/6.0

#############################################################
### Extract Mean Cortical Thickness Per Group ICA Network ###
#############################################################

FILE_COHORT=$DIR_PROJECT/analyses/IntraFlux/n138_IntraFlux.dualreg/cohort_sm3_20200802.csv
OUTPUT_DIR=$DIR_PROJECT/analyses/IntraFlux/n138_IntraFlux.ct
mkdir -p $OUTPUT_DIR/masks
rm -rf `find $DIR_PROJECT/apps/freesurfer -empty -iname stats | sed s@'/stats'@@g`

for MASK in `ls $DIR_PROJECT/analyses/IntraFlux/n138_IntraFlux.gica/dim-12_sm3/smooths_final/probmap_*.nii.gz` ; do
	MASK_BIN=$(echo $OUTPUT_DIR/masks/`basename $MASK | sed s@'.nii'@'_BIN.nii'@g`)
	fslmaths $MASK -thr 0.4 -bin $MASK_BIN
done

for INPUT in `cat $FILE_COHORT | cut -d '/' -f10,11 | sort | uniq` ; do
	SUB=`echo $INPUT | cut -d '/' -f1 | sed s@'sub-'@''@g`
	SES=`echo $INPUT | cut -d '/' -f2 | sed s@'ses-'@''@g`
	SUBJECTS_DIR=$(echo `find $DIR_PROJECT/apps/freesurfer -maxdepth 2 -iname ${SUB}_tp${SES}` | sed s@"/${SUB}_tp${SES}"@""@g)
	${DIR_TOOLBOX}/bids_apps/freesurfer/extract_custom_mask.sh ${SUB} ${SES} $OUTPUT_DIR ${SUBJECTS_DIR}
	echo $SUB $SES
done
		
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

