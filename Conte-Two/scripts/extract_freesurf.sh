#!/usr/bin/env bash
###################

ROOT=/dfs9/yassalab/
DATA_DIR=$ROOT/CONTE2/datasets
ATLAS_DIR=$ROOT/rjirsara/ConteCenterScripts/ToolBox/atlases
export SUBJECTS_DIR=$ROOT/CONTE2/pipelines/freesurfer
SUBJIDS=`echo $SUBJECTS_DIR/sub*| xargs -n 1 basename`

#####
### Register Atlases to Subject Space & Extract Data
#####

SUBNAME=$1
for ANNOT in `ls $ATLAS_DIR/*.annot | grep 'Schaefer'` ; do
	ATLAS=`basename $ANNOT`
	HEMI=`basename $ANNOT | cut -d '_' -f2 | cut -d '.' -f1`
	PARCEL=`basename $ANNOT | cut -d '_' -f1 | cut -d '-' -f2`
	if [[ ! -f `echo $SUBJECTS_DIR/$SUBNAME/stats/${HEMI}.${PARCEL}.stats` ]] ; then
	mri_surf2surf \
		--srcsubject fsaverage \
		--trgsubject $SUBNAME \
		--hemi $HEMI \
		--sval-annot $ANNOT \
		--tval $SUBJECTS_DIR/$SUBNAME/label/${ATLAS}
	mris_anatomical_stats \
		-mgz -cortex $SUBJECTS_DIR/$SUBNAME/label/${HEMI}.cortex.label \
		-f $SUBJECTS_DIR/$SUBNAME/stats/${HEMI}.${PARCEL}.stats \
		-b -a $SUBJECTS_DIR/$SUBNAME/label/${ATLAS} $SUBNAME ${HEMI} white
	fi
done

for SUBID in `echo $SUBJIDS` ; do
	if [[ ! -f `echo $SUBJECTS_DIR/$SUBID/stats/hypothalamic_subunits_volumes.v1.stats` ]] ; then
	echo $SUBID
	mri_segment_hypothalamic_subunits \
		--s  $SUBID \
		--sd $SUBJECTS_DIR
	fi
done

#####
### Aggrograte Data Across all Subjects
#####

#Cortical Parcels
for ANNOT in `ls $ATLAS_DIR/*.annot | grep 'Schaefer'` ; do
	ATLAS=`basename $ANNOT`
	HEMI=`basename $ANNOT | cut -d '_' -f2 | cut -d '.' -f1`
	PARCEL=`basename $ANNOT | cut -d '_' -f1 | cut -d '-' -f2`
	for MEASURE in `echo volume thickness area` ; do
		aparcstats2table \
			--subjects $SUBJIDS \
			--hemi $HEMI \
			--meas $MEASURE \
			--delimiter 'comma' \
			--parc=${PARCEL} \
			--skip \
			--tablefile $DATA_DIR/${HEMI}.${PARCEL}_${MEASURE}.csv
		chmod u+wrx  $DATA_DIR/${HEMI}.${PARCEL}_${MEASURE}.csv
	done
done

#Hypothalamus
asegstats2table \
	--subjects $SUBJIDS \
	--statsfile=hypothalamic_subunits_volumes.v1.stats \
	--delimiter 'comma' \
	--skip \
	--tablefile $DATA_DIR/anat-hypothalamic.csv

#ASEG
asegstats2table \
	--subjects $SUBJIDS \
	--meas volume \
	--delimiter 'comma' \
	--skip \
	--tablefile $DATA_DIR/anat-aseg.csv

########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######