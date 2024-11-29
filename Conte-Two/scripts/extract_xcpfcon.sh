#!/usr/bin/env bash
###################

SUB=$1 
ATL=$2 
ROOT=/dfs9/yassalab/CONTE2/pipelines/xcpengine
TOOLS=/dfs9/yassalab/rjirsara/ConteCenterScripts/ToolBox
SIMG=$TOOLS/bids_apps/dependencies/xcpEngine.simg
ATLAS=$TOOLS/atlases/atl-${ATL}.nii.gz
LABELS=$TOOLS/atlases/atl-${ATL}.1D
INDEX=$TOOLS/atlases/atl-${ATL}_NUM.1D
TEMPLATE=$TOOLS/atlases/tpl-MNI152NLin6Asym_res-02_desc-brain_T1w.nii.gz
TRANSFORM=$TOOLS/bids_apps/dependencies/designs_xcp/oneratiotransform.txt

#####
### Merge the Bandit Runs
#####

if [[ ! -f $ROOT/pipe-36despike_task-bandit_runs/${SUB}/regress/${SUB}_residualised.nii.gz ]] ; then
	mkdir -p $ROOT/pipe-36despike_task-bandit_runs/${SUB}/regress
	BASEDIR=`echo $ROOT/pipe-36despike_task-bandit_runs | sed s@_runs@''@g`
	PROCRUNS=`ls ${BASEDIR}_run-*/$SUB/regress/${SUB}_residualised.nii.gz`
	fslmerge -t $ROOT/pipe-36despike_task-bandit_runs/${SUB}/regress/${SUB}_residualised.nii.gz $PROCRUNS
fi

#####
### Register the Atlas To The Bandit Merged Runs
#####

for PIPEDIR in `echo $ROOT/pipe-36despike_task-rest $ROOT/pipe-36despike_task-bandit_runs` ; do
	if [[ ! -f $PIPEDIR/$SUB/regress/${SUB}_norm_resid.nii.gz ]] ; then
		antsApplyTransforms \
			-e 3 \
			-d 3 \
			-i $PIPEDIR/$SUB/regress/${SUB}_residualised.nii.gz \
			-r $TOOLS/atlases/tpl-MNI152NLin6Asym_res-02_desc-brain_T1w.nii.gz \
			-o $PIPEDIR/$SUB/regress/${SUB}_norm_resid.nii.gz \
			-n MultiLabel \
			-t $TOOLS/bids_apps/dependencies/designs_xcp/oneratiotransform.txt
	fi
done

#####
### Compute ALFF/ReHo Maps
#####

for PIPEDIR in `echo $ROOT/pipe-36despike_task-rest $ROOT/pipe-36despike_task-bandit_runs` ; do
	if [[ ! -f $PIPEDIR/$SUB/alff/${SUB}_norm_alff.nii.gz ]]; then
		PROC=$PIPEDIR/$SUB/regress/${SUB}_norm_resid.nii.gz
		DIR=$PIPEDIR/$SUB/alff; mkdir -p $DIR
		fslpspec $PROC $DIR/${SUB}_fslpspec.nii.gz
		fslmaths  $DIR/${SUB}_fslpspec.nii.gz -sqrt $DIR/${SUB}_fslpspec_sqrt.nii.gz
		fslroi $DIR/${SUB}_fslpspec_sqrt.nii.gz $DIR/${SUB}_fslpspec_sqrt_lowfreq.nii.gz 2 22
		fslmaths $DIR/${SUB}_fslpspec_sqrt_lowfreq.nii.gz -Tmean -mul 22 $DIR/${SUB}_norm_alff.nii.gz
		rm -rf $DIR/${SUB}_fslpspec*.nii.gz
	fi
	if [[ ! -f $PIPEDIR/$SUB/reho/${SUB}_norm_reho.nii.gz ]]; then
		PROC=$PIPEDIR/$SUB/regress/${SUB}_norm_resid.nii.gz
		DIR=$PIPEDIR/$SUB/reho; mkdir -p $DIR
		3dReHo -prefix $DIR/${SUB}_norm_reho.nii.gz -inset $PROC -nneigh 27
	fi
done

#####
### Extract Data From ALFF/ReHo Maps
#####

for PIPEDIR in `echo $ROOT/pipe-36despike_task-rest $ROOT/pipe-36despike_task-bandit_runs` ; do
	if [[ ! -f $PIPEDIR/$SUB/${MAP}/${MAP}_norm_quantifyAtlas.csv ]]; then
		for MAP in `echo alff reho` ; do
			echo "${SUB} - ${MAP} Module" 
			singularity exec -B /dfs9/yassalab/ ${SIMG} \
				/xcpEngine/utils/quantifyAtlas \
					-v $PIPEDIR/$SUB/${MAP}/${SUB}_norm_${MAP}.nii.gz \
					-a $ATLAS \
					-n $MAP \
					-p $SUB \
					-s mean \
					-r $LABELS \
					-o $PIPEDIR/$SUB/${MAP}/${MAP}_norm_quantifyAtlas.csv
			rm ${OUTDIR}/${MAP}*.1D
		done
	fi
done

########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######