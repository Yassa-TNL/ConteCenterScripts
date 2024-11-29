#!/usr/bin/env bash
#####################

SUB=$1 
ATL=$2
ROOT=/dfs9/yassalab/CONTE2/pipelines/xcpfeat/pipe-feat2_task-bandit
LABELS=/dfs9/yassalab/rjirsara/ConteCenterScripts/ToolBox/atlases/atl-${ATL}.1D
ATLAS=/dfs9/yassalab/rjirsara/ConteCenterScripts/ToolBox/atlases/atl-${ATL}.nii.gz
SIMG=/dfs9/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/dependencies/xcpEngine.simg
TRANSFORM=/dfs9/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/dependencies/designs_xcp/oneratiotransform.txt
PVT=/dfs9/yassalab/rjirsara/ConteCenterScripts/ToolBox/atlases/atl-PVTdilate2mm.nii.gz

#####
### Extract Data From the Statistical Maps
#####

for MAP in `ls $ROOT/sub-${SUB}.gfeat/cope*.feat/stats/[tz]stat1.nii.gz` ; do
	echo "${SUB} - $ATL - `basename ${MAP}`" 
	STAT=`basename $MAP | cut -d '.' -f1 | sed s@stat1@map@g`
	OUTDIR=`dirname $MAP`
	singularity exec -B /dfs9/yassalab/ ${SIMG} \
		/xcpEngine/utils/quantifyAtlas \
			-v $MAP \
			-a $ATLAS \
			-n $STAT \
			-p $SUB \
			-s mean \
			-r $LABELS \
			-o $OUTDIR/atl-${ATL}_${STAT}_quantifyAtlas.csv
	rm $OUTDIR/atl-${ATL}_*.1D
	fslstats $MAP -k $PVT -M > $OUTDIR/atl-PVT_${STAT}_quantifyAtlas.csv
done

########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######