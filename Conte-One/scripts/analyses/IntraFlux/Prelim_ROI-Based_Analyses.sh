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

ATLAS=${DIR_TOOLBOX}/bids_apps/dependencies/atlases/atl-Yeo_ALL-bin_1-7.nii.gz
INDEX=0
for LABEL in `echo 'Visual Somatomotor DorsalAttention VentralAttention Limbic Frontoparietal Default'` ; do
	INDEX=$((INDEX + 1))
	OUTPUT=`echo $ATLAS | sed s@'ALL'@"${LABEL}"@g | sed s@'_1-7'@"_${INDEX}"@g`
	fslmaths ${ATLAS} -thr ${INDEX} -uthr ${INDEX} $OUTPUT
	fslmaths ${OUTPUT} -bin ${OUTPUT}
	chmod 750 $OUTPUT 
done

##########################################################
### Create Data Driven Atlases From Voxelwise Contrast ###
##########################################################

CLUSTER=${DIR_PROJECT}/apps/xcp-feat/pipe-aromaXcluster_task-AMG_emotion/group/n138_IntraFlux.gfeat/cope3.feat/rendered_thresh_zstat1.nii.gz
MASK=${DIR_PROJECT}/apps/xcp-feat/pipe-aromaXcluster_task-AMG_emotion/group/n138_IntraFlux.gfeat/cope3.feat/cluster_mask_zstat1.nii.gz
TEMPLATE=${DIR_TOOLBOX}/bids_apps/dependencies/atlases/atl-brainnetome_AMG-pro_211-214.nii.gz
OUTPUT=`echo $DIR_TOOLBOX/bids_apps/dependencies/atlases/atl-datadriven_AMG-pro_cope3.nii.gz`
TEMPLATE_BINARY=`echo $TEMPLATE | sed s@.nii.gz@_BINARY.nii.gz@g`

fslmaths ${TEMPLATE} -bin $TEMPLATE_BINARY
fslmaths $MASK -mul $TEMPLATE_BINARY $OUTPUT
fslmaths ${OUTPUT} -bin ${OUTPUT} -force
fslmaths $OUTPUT -mul $CLUSTER $OUTPUT
rm $TEMPLATE_BINARY


for INDEX in `seq 1 6` ; do
	OUTPUT_CLUSTER=`echo $OUTPUT | sed s@'AMG-pro'@"clust${INDEX}-bin"@g`
	fslmaths ${MASK} -thr ${INDEX} -uthr ${INDEX} $OUTPUT_CLUSTER
	chmod 740 $OUTPUT_CLUSTER
done

########################################
### Extract Contrasts on a ROI Basis ###
########################################

DIRS_FEAT=`find $DIR_PROJECT/apps/xcp-feat/pipe-aromaXcluster_task-AMG_emotion/group/n138_IntraFlux.lvl-1 | grep .feat$  | tr '\n' ' '`
for ATLAS in `ls $DIR_TOOLBOX/bids_apps/dependencies/atlases/atl-* | grep -v Yeo_ALL | grep 'datadriven_clust'` ; do
	NUM_DIRS=`echo $DIRS_FEAT | wc -w`
	LABEL_ATLAS=`basename $ATLAS | sed s@.nii.gz@''@g`
	featquery ${NUM_DIRS} ${DIRS_FEAT} 6 stats/tstat1 stats/tstat2 stats/tstat3 stats/zstat1 stats/zstat2 stats/zstat3 ${LABEL_ATLAS} -p -s -w -b ${ATLAS}
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
