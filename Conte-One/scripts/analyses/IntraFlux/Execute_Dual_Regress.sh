#! /bin/bash
############

DIR_TOOLBOX=/dfs7/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs7/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3 fsl/6.0.1
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

########################################################
### Run Dual Regression and Extract Network Strength ###
########################################################

NCOMP=12_sm3
GROUP_ICA_NIFTI=$DIR_PROJECT/apps/xcp-fcon/pipe-aroma_task-REST_run-1/group/n138_IntraFlux.gica/dim-${NCOMP}/melodic_IC.nii.gz 
FILE_COHORT=$DIR_PROJECT/analyses/IntraFlux/n138_IntraFlux.dualreg/cohort_sm3_20200802.csv
OUTPUT_DIR=$DIR_PROJECT/analyses/IntraFlux/n138_IntraFlux.dualreg/dim-${NCOMP}
mkdir -p $OUTPUT_DIR

REST1_COHORT=`cat $DIR_PROJECT/apps/xcp-fcon/pipe-aroma_task-REST_run-1/group/n138_IntraFlux.gica/cohort_sm3_20200801.csv`
REST2_COHORT=`echo $REST1_COHORT | sed s@'pipe-aroma_task-REST_run-1'@'pipe-aroma_task-REST_run-2'@g`
AMG_COHORT=`echo $REST1_COHORT | sed s@'pipe-aroma_task-REST_run-1'@'pipe-aroma_task-AMG'@g`
echo $REST1_COHORT $AMG_COHORT $REST2_COHORT | tr ' ' '\n' > ${FILE_COHORT}
unset SGE_ROOT ; module purge ; module load fsl/6.0.1

for SUBJECT in `cat $FILE_COHORT  | cut -d '/' -f10 | sort | uniq` ; do

	#dual_regression $GROUP_ICA_NIFTI 1 -1 5000 $OUTPUT_DIR/$SUBJECT `cat $FILE_COHORT | grep "regress/${SUBJECT}_"`

	DATAFRAME1=`echo $OUTPUT_DIR/$SUBJECT/stats/aggregated_mean_${SUBJECT}.csv`
	DATAFRAME2=`echo $OUTPUT_DIR/$SUBJECT/stats/aggregated_eigen_${SUBJECT}.csv`
	SUB_LABEL=`echo ${SUBJECT} | cut -d '-' -f2`
	mkdir -p $OUTPUT_DIR/$SUBJECT/stats
	echo sub, $SUB_LABEL, | tr ' ' '\n' > $DATAFRAME1
	echo sub, $SUB_LABEL, | tr ' ' '\n' > $DATAFRAME2

	INDEX=0
	for NETWORK in $OUTPUT_DIR/$SUBJECT/dr_stage2_ic*.nii.gz ; do
		INDEX=$((INDEX+1))
		ALLMASK=$(ls `dirname $NETWORK`/maskALL.nii.gz)
		fslmeants -i $NETWORK -m $ALLMASK -o $OUTPUT_DIR/$SUBJECT/stats/network${INDEX}.txt
		fslmeants -i $NETWORK -m $ALLMASK --eig -o $OUTPUT_DIR/$SUBJECT/stats/network_eig_${INDEX}.txt
		HEADER=`echo COMP${INDEX}_REST1,COMP${INDEX}_AMG,COMP${INDEX}_REST2,`
		DATA1=`cat $OUTPUT_DIR/$SUBJECT/stats/network${INDEX}.txt | tr '\n' ',' | sed s@' '@''@g`
		sed -i "s@`head -n1 ${DATAFRAME1}`@`echo $(head -n1 ${DATAFRAME1})$HEADER`@g" ${DATAFRAME1} > /dev/null 2>&1
		sed -i "s@`tail -n1 ${DATAFRAME1}`@`echo $(tail -n1 ${DATAFRAME1})$DATA1`@g" ${DATAFRAME1} > /dev/null 2>&1
		DATA2=`cat $OUTPUT_DIR/$SUBJECT/stats/network_eig_${INDEX}.txt| tr '\n' ',' | sed s@' '@''@g`
		sed -i "s@`head -n1 ${DATAFRAME2}`@`echo $(head -n1 ${DATAFRAME2})$HEADER`@g" ${DATAFRAME2} > /dev/null 2>&1
		sed -i "s@`tail -n1 ${DATAFRAME2}`@`echo $(tail -n1 ${DATAFRAME2})$DATA2`@g" ${DATAFRAME2} > /dev/null 2>&1
	done

	for NUM in `seq 0 1 2` ; do
		ZMAP=$OUTPUT_DIR/$SUBJECT/dr_stage2_subject0000${NUM}_Z.nii.gz
		if [[ $NUM == 0 ]] ; then
			OUTDIR=$OUTPUT_DIR/$SUBJECT/smooths_REST1
		elif [[ $NUM == 1 ]] ; then
			OUTDIR=$OUTPUT_DIR/$SUBJECT/smooths_AMG
		else
			OUTDIR=$OUTPUT_DIR/$SUBJECT/smooths_REST2
		fi
		mkdir -p ${OUTDIR}
		fslmaths $ZMAP -s 5 -thr 1.5 ${OUTDIR}/temp.nii.gz
		fslsplit ${OUTDIR}/temp.nii.gz ${OUTDIR}/ -t
			rm ${OUTDIR}/temp.nii.gz
		done	
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
