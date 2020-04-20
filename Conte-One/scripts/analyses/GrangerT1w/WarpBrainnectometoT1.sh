#!/bin/bash
#$ -N STEVE
#$ -q free*,yassalab
#$ -pe openmp 4
#$ -R y
#$ -ckpt restart

module load afni/v19.0.01 ; fsl/6.0.1 ; ants/2.1.0

cd $1

3dSkullStrip -input *.nii.gz -prefix VOL_PREFIX 
	
3dcalc -a *.nii.gz -b ./VOL_PREFIX+orig -expr 'a*step(b)' -prefix ./VOL_PREFIX_orig_vol
3dAFNItoNIFTI VOL_PREFIX_orig_vol+orig.
	
/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/GrangerDTI/Thalamus/ants/antsRegistrationSyN.sh -d 3 -f *.nii -m /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/GrangerDTI/Thalamus/template_MNI152.nii.gz -o outputtemplatetosub205practice.nii.gz


