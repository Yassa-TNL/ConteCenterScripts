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

for NCOMP in `seq 10 1 30` ; do
	GROUP_ICA_NIFTI=$DIR_PROJECT/apps/xcp-fcon/pipe-aroma_task-REST_run-1/group/n138_IntraFlux.gica/dim-${NCOMP}/melodic_IC.nii.gz 
	FILE_COHORT=$DIR_PROJECT/analyses/IntraFlux/Dual_Regress_Analysis/cohort_20200724.csv 
	OUTPUT_DIR=$DIR_PROJECT/analyses/IntraFlux/Dual_Regress_Analysis/dim-${NCOMP}

	REST1_COHORT=`cat $DIR_PROJECT/apps/xcp-fcon/pipe-aroma_task-REST_run-1/group/n138_IntraFlux.gica/cohort_20200724.csv`
	REST2_COHORT=`echo $REST1_COHORT | sed s@'pipe-aroma_task-REST_run-1'@'pipe-aroma_task-REST_run-2'@g`
	AMG_COHORT=`echo $REST1_COHORT | sed s@'pipe-aroma_task-REST_run-1'@'pipe-aroma_task-AMG'@g`
	echo $REST1_COHORT $AMG_COHORT $REST2_COHORT | tr ' ' '\n' > ${FILE_COHORT}
	unset SGE_ROOT ; module purge ; module load fsl/6.0.1

	for SUBJECT in `cat $FILE_COHORT  | cut -d '/' -f10 | sort | uniq` ; do

		dual_regression $GROUP_ICA_NIFTI 1 -1 5000 $OUTPUT_DIR/$SUBJECT `cat $FILE_COHORT | grep $SUBJECT`

		DATAFRAME=`echo $OUTPUT_DIR/$SUBJECT/stats/aggregated_${SUBJECT}.csv`
		SUB_LABEL=`echo ${SUBJECT} | cut -d '-' -f2`
		mkdir -p $OUTPUT_DIR/$SUBJECT/stats
		echo sub, $SUB_LABEL, | tr ' ' '\n' > $DATAFRAME

		INDEX=0
		for NETWORK in $OUTPUT_DIR/$SUBJECT/dr_stage2_ic*.nii.gz ; do
			INDEX=$((INDEX+1))
			fslmeants -i $NETWORK -o $OUTPUT_DIR/$SUBJECT/stats/network${INDEX}.txt
			HEADER=`echo COMP${INDEX}_REST1,COMP${INDEX}_AMG,COMP${INDEX}_REST2,`
			DATA=`cat $OUTPUT_DIR/$SUBJECT/stats/network${INDEX}.txt | tr '\n' ',' | sed s@' '@''@g`
			sed -i "s@`head -n1 ${DATAFRAME}`@`echo $(head -n1 ${DATAFRAME})$HEADER`@g" ${DATAFRAME} > /dev/null 2>&1
			sed -i "s@`tail -n1 ${DATAFRAME}`@`echo $(tail -n1 ${DATAFRAME})$DATA`@g" ${DATAFRAME} > /dev/null 2>&1
		done
		
			
	done



for TYPE in `echo 'REST1.csv REST2.csv AMG.csv' | tr ' ' '\n'` ; do
	LABEL=`echo $TYPE | cut -d '.' -f1`
	OUT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/IntraFlux/Dual_Regress_Analysis
	dual_regression $GROUP_ICA_NIFTI 1 -1 5000 $OUT/${LABEL} `cat  $OUT/$TYPE`


done





	for MAP in $OUTPUT_DIR/ ; do



		fslmaths $MAP -s 1 $(echo $MAP | sed s@"probmap_"@"probmap_smth-1_"@g | sed s@'stats'@'smooths'@g)
		fslmaths $MAP -s 2 $(echo $MAP | sed s@"probmap_"@"probmap_smth-2_"@g | sed s@'stats'@'smooths'@g)
		fslmaths $MAP -s 3 $(echo $MAP | sed s@"probmap_"@"probmap_smth-3_"@g | sed s@'stats'@'smooths'@g)
		fslmaths $MAP -s 4 $(echo $MAP | sed s@"probmap_"@"probmap_smth-4_"@g | sed s@'stats'@'smooths'@g)
		fslmaths $MAP -s 5 $(echo $MAP | sed s@"probmap_"@"probmap_smth-5_"@g | sed s@'stats'@'smooths'@g)
	done
done
