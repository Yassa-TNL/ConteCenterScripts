#!/usr/bin/env bash
###################

TODAY=`date "+%Y%m%d"` 
DIR_PROJECT=/dfs8/yassalab/ABCDS
SUBJECTS_DIR=$DIR_PROJECT/pipelines/freesurfer
XCPENGINE_DIR=$DIR_PROJECT/pipelines/xcpengine
SUBIDS=`ls $SUBJECTS_DIR | grep sub` ; COUNT=`echo $SUBIDS | wc -w`
DIR_TOOLBOX=/dfs8/yassalab/rjirsara/ConteCenterScripts/ToolBox

#####
### Extract Morphometry Measures From the Gordon Atlas
#####

for SUBID in $SUBIDS ; do
	echo $SUBID
	for HEMISPHERE in `echo lh rh` ; do
	mri_surf2surf \
		--srcsubject fsaverage \
		--trgsubject ${SUBID} \
		--hemi ${HEMISPHERE} \
		--sval-annot $DIR_TOOLBOX/atlases/atl-Gordon_${HEMISPHERE}.HCP-MMP1.annot \
		--tval $SUBJECTS_DIR/${SUBID}/label/atl-Gordon_${HEMISPHERE}.HCP-MMP1.annot
	mris_anatomical_stats \
		-mgz -cortex $SUBJECTS_DIR/${SUBID}/label/${HEMISPHERE}.cortex.label \
		-f $SUBJECTS_DIR/${SUBID}/stats/${HEMISPHERE}.gordon.HCP-MMP1.stats -b \
		-a $SUBJECTS_DIR/${SUBID}/label/atl-Gordon_${HEMISPHERE}.HCP-MMP1.annot ${SUBID} ${HEMISPHERE} white
	done
	chmod -R ug+wrx $SUBJECTS_DIR/${SUBID}/
done

#####
### Extract APARC and ASEG Regional Measures
#####

#ASEG
asegstats2table \
	--subjects $SUBIDS \
	--meas volume \
	--delimiter 'comma' \
	--tablefile $DIR_PROJECT/datasets/anat-aseg_${COUNT}x65_${TODAY}.csv

#Thalamus
asegstats2table \
	--subjects $SUBIDS \
	--statsfile=hypothalamic_subunits_volumes.v1.stats \
	--delimiter 'comma' \
	--skip \
	--tablefile $DIR_PROJECT/datasets/anat-hypothalamic_${COUNT}x12_${TODAY}.csv

#APARC
for MEASURE in `echo area volume thickness` ; do
	for HEMISPHERE in `echo lh rh` ; do
		aparcstats2table \
			--subjects $SUBIDS \
			--hemi $HEMISPHERE \
			--meas $MEASURE \
			--delimiter 'comma' \
			--tablefile $DIR_PROJECT/datasets/anat-aparc_${HEMISPHERE}_${MEASURE}_${TODAY}.csv
	done
done

#Gordon
for MEASURE in `echo area volume thickness` ; do
	for HEMISPHERE in `echo lh rh` ; do
		aparcstats2table \
			--subjects $SUBIDS \
			--hemi $HEMISPHERE \
			--meas $MEASURE \
			--delimiter 'comma' \
			--parc=gordon.HCP-MMP1 \
			--tablefile $DIR_PROJECT/datasets/anat-gordon_${HEMISPHERE}_${MEASURE}_${TODAY}.csv
	done
done

########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######