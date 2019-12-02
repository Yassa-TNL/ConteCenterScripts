#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script identifies subjects and processes data from Conte-One who need to be run through the 
fmriprep preprocessing pipeline via singulatiry image.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module purge 2>/dev/null 
module load singularity/3.0.0 2>/dev/null 

#########################################
##### Define Input and Output Paths #####
#########################################

Singularity_Container=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fmriprep/fmriprep-latest.simg
script_root_dir=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fmriprep/Conte-One
bids_root_dir=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One
output_root_dir=/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One

#######################################################
##### Build FMRIPREP Singularity Image if Missing #####
#######################################################

if [ -f $Singularity_Container ] ; then

	version=`singularity run --cleanenv $Singularity_Container --version | cut -d ' ' -f2`
	echo ''
	echo "Preprocessing will be Completed using the FmriPrep Singularity Image: ${version}"
	echo ''

else

	echo ''
	echo "Singularity Image Not Found -- Building New Containter with Latest Version of fmriprep"
	echo ''
	singularity build ${Singularity_Container} docker://poldracklab/fmriprep:latest

fi

###############################################################
##### Define New Subjects to be Processed and Submit Jobs #####
###############################################################

AllSubjects=`ls -d1 ${bids_root_dir}/sub-* | xargs -n 1 basename | cut -d '-' -f2`

for sub in ${AllSubjects} ; do

	JobName=`echo FPREP${sub}`
	JobStatus=`qstat -u $USER | grep "${JobName}\b" | awk {'print $5'}`
	qa=`echo ${output_root_dir}/fmriprep/sub-${sub}/ses-*/func/sub-${sub}_ses-*_task-*_desc-confounds_regressors.tsv | cut -d ' ' -f1`
	preproc=`echo ${output_root_dir}/fmriprep/sub-${sub}/ses-*/func/sub-${sub}_ses-*_task-*_*_desc-brain_mask.nii.gz | cut -d ' ' -f1`
	html=`echo ${output_root_dir}/fmriprep/sub-${sub}*.html`

	if [ ! -d `echo ${bids_root_dir}/sub-${sub}/ses-*/func | cut -d ' ' -f1` ] ; then

		echo ''
		echo "#####################################################"
		echo "#sub-${sub} does not have functional scans to process"
		echo "#####################################################"
		echo ''

	elif [ -f ${qa} ] && [ -f ${preproc} ] && [ -f ${html} ] ; then

		echo ''
		echo "#####################################################"
		echo "#sub-${sub} already ran through the fmriprep pipeline"
		echo "#####################################################"
		echo ''

	elif [ ! -z "$JobStatus" ] ; then

		echo ''
		echo "#######################################################"
		echo "#sub-${sub} is currently being processed (${JobStatus})"
		echo "#######################################################"
		echo ''

	else

		echo ''
		echo "#######################################"
		echo "#SUBMITTING FMRIPREP JOB FOR sub-${sub}"
		echo "#######################################"
		echo ''

		Pipeline=${script_root_dir}/fmriprep_preproc_pipeline.sh
		Freesurfer_License=${script_root_dir}/freesurfer_license.txt

		qsub -N ${JobName} ${Pipeline} ${sub} ${bids_root_dir} ${output_root_dir} ${Freesurfer_License} ${Singularity_Container}

	fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
