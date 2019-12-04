#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 8-16
#$ -l kernel=blcr
#$ -ckpt restart
#######################################
### Load Software and Define Inputs ###
#######################################

module purge 2>/dev/null
module load freesurfer/6.0 2>/dev/null

sub=`echo $1`
ses=`echo $2`

logfile=`echo /dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-Two/logs/sub-${sub}_ses-${ses}_output.txt`
OutputPath=/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-Two
export SUBJECTS_DIR=${OutputPath}
rm -rf ${OutputPath}/${sub}_tp${ses}
rm F${sub}x${ses}.*

########################
### Create MGZ Files ###
########################

MGZ=/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-Two/mgz/sub-${sub}_ses-${ses}_T1w-coverted.mgz

if [ ! -f ${MGZ} ] ; then

  mri_convert /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-${sub}/ses-${ses}/anat/sub-${sub}_ses-${ses}_T1w.nii.gz  ${MGZ} > ${logfile} 2>&1
  chmod 775 ${MGZ}

fi

#################################################################
### Define Paths to Subjects' Scans That Need to be Processed ###
#################################################################

recon-all -i ${MGZ} -s ${sub}_tp${ses} -no-isrunning -all -hippocampal-subfields-T1 -brainstem-structures -qcache > ${logfile} 2>&1
chmod -R 775 ${OutputPath}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡ #####
###################################################################################################
