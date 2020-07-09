#! /bin/bash
############

DIR_TOOLBOX=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3 fsl/6.0.1
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

################################
### Resample Yeo 7-ROI Atlas ###
################################

DIR_ATLAS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/dependencies/atlases/atl-7Yeo_ALL.nii.gz
fslmaths $ATLAS -thr 1 output.nii.gz

##########################################################
### Create Function To Extract Contrats on a ROI Basis ###
##########################################################

ROIextraction () {
	featquery $1 $2 6 stats/tstat1 stats/tstat2 stats/tstat3 stats/zstat1 stats/zstat2 stats/zstat3 $3 -p -s -w -b $4
}

DIRS_FEAT=`find $DIR_PROJECT/apps/xcp-feat/pipe-aromaXcluster_task-AMG_emotion/group/n138_IntraFlux.lvl-1 -type d -iname *.feat | tr '\n' ' '`
DIR_ATLAS=`ls $DIR_TOOLBOX/bids_apps/dependencies/atlases/atl-brainconnect_AMG_211-214.nii.gz`

for ATLAS in $DIR_ATLAS ; do
	NUM_DIRS=`echo $DIRS_FEAT | wc -w`
	LABEL_ATLAS=`basename $ATLAS | sed s@.nii.gz@''@g`

	ROIextraction ${NUM_DIRS} ${DIRS_FEAT} ${LABEL_ATLAS} ${ATLAS}
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

