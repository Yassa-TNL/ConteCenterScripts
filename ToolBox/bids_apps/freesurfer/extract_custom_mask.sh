#!/bin/bash
#$ -q yassalab,pub*,free*
#$ -pe openmp 1-4
#$ -R y
#$ -ckpt restart
################

module load freesurfer/6.0

SUB=$1
SES=$2
OUTPUT_DIR=$3
SUBJECTS_DIR=$4

#######################################################
##### Extract the Volume from Subcortical Regions #####
#######################################################

cd ${SUBJECTS_DIR}/${SUB}_tp${SES}/surf
for MASK in `ls $OUTPUT_DIR/masks/probmap_6_BIN.nii.gz` ; do
	NETWORK=`basename $MASK | cut -d '_' -f2 | cut -d '.' -f1`
	fslregister --s fsaverage --mov ${MASK} --reg net-${NETWORK}_to_fsaverage.dat
	for HEMI in `echo lh rh` ; do
		mri_vol2surf \
			--mov ${MASK} \
			--reg net-${NETWORK}_to_fsaverage.dat \
			--projdist-max 0 1 0.1 \
			--interp nearest \
			--hemi ${HEMI} \
			--out ${HEMI}.fsaverage.network-${NETWORK}.mgh
		mri_surf2surf \
			--s ${SUB}_tp${SES} \
			--trgsubject fsaverage \
			--hemi ${HEMI} \
			--sval ${HEMI}.thickness \
			--tval ${HEMI}.thickness.fsaverage.mgh
		mri_segstats \
			--seg ${HEMI}.fsaverage.network-${NETWORK}.mgh \
			--in ${HEMI}.thickness.fsaverage.mgh \
			--sum ${OUTPUT_DIR}/sub-${SUB}_ses-${SES}_hemi-${HEMI}_net-${NETWORK}_ct.txt
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
