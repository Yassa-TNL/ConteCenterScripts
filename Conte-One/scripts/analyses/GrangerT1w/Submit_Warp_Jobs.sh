FULLPATH=`echo /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/GrangerDTI/Thalamus/bids/sub*/ses-*/anat`

for d in $FULLPATH; do
	cd $d 

	if [[ ! -f `echo VOL_PREFIX+orig.HEAD | cut -d ' ' -f1` ]] ; then
		
		qsub /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/GrangerDTI/Thalamus/WarpBrainnectometoT1.sh $d

	else

		echo "Data Already Processed"
	
	fi
done
