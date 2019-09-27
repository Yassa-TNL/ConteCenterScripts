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

#######################################################
##### Build FMRIPREP Singularity Image if Missing #####
#######################################################

fmriprep_container=`echo /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fmriprep/fmriprep-latest.simg`
if [ -f $fmriprep_container ] ; then

  version=`singularity run --cleanenv $fmriprep_container --version | cut -d ' ' -f2`
  echo ''
  echo "Preprocessing will be Completed using the fmriprep Singularity Image: ${version}"
  echo ''

else

  echo ''
  echo "Singularity Image Not Found -- Building New Containter with Latest Version of fmriprep"
  echo ''
  singularity build ${fmriprep_container} docker://poldracklab/fmriprep:latest

fi

###############################################################
##### Define New Subjects to be Processed and Submit Jobs #####
###############################################################

AllSubs=`ls -d1 /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-*/ses-*/func | cut -d '/' -f8 | cut -d '-' -f2 | head -n25`

for sub in ${AllSubs} ; do

  output_base_dir=/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One

  qa=`echo ${output_base_dir}/fmriprep/sub-${sub}/ses-*/func/sub-${sub}_ses-*_task-*_desc-confounds_regressors.tsv | cut -d ' ' -f1`
  preproc=`echo ${output_base_dir}/fmriprep/sub-${sub}/ses-*/func/sub-${sub}_ses-*_task-*_*_desc-brain_mask.nii.gz | cut -d ' ' -f1`
  html=`echo ${output_base_dir}/fmriprep/sub-${sub}*.html`

  if [ -f ${qa} ] && [ -f ${preproc} ] && [ -f ${html} ] ; then

    echo ''
    echo "########################################################"
    echo "#sub-${sub} already ran through the fmriprep pipeline..."
    echo "########################################################"
    echo ''

  else

    job=`qstat -u $USER | grep FP${sub} | awk {'print $5'}`

    if [ "$job" == "r" ] || [ "$job" == "Rr" ] || [ "$job" == "Rq" ] || [ "$job" == "qw" ] ; then

       echo ''
       echo "###########################################"
       echo "#sub-${sub} is currently being processed..."
       echo "###########################################"
       echo ''

    else

       echo ''
       echo "##############################################"
       echo "#Fmriprep Job Being Submitted for sub-${sub}  "
       echo "##############################################"
       echo ''

       JobName=`echo FP${sub}`
       Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fmriprep/Conte-One/fmriprep_preproc_pipeline.sh
       
       qsub -N ${JobName} ${Pipeline} ${sub} ${fmriprep_container}
    fi
  fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
