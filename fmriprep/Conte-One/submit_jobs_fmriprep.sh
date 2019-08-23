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

module purge
module load singularity/3.0.0

#######################################################
##### Build FMRIPREP Singularity Image if Missing #####
#######################################################

fmriprep_container=`echo /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fmriprep/fmriprep-1.4.1.simg`

if [ -f $fmriprep_container ] ; then

   echo "Preprocessing will be completed using fmriprep singularity image - version 1.4.1"

else
   echo "Singularity Image Not Found -- Building New Containter with latest version of fmriprep"
   fmriprep_container=`echo ${fmriprep_container} | sed s@'fmriprep-1.4.1.simg'@'fmriprep-latest.simg'@g`
   singularity build ${fmriprep_container} docker://poldracklab/fmriprep:latest
fi

###############################################################
##### Define New Subjects to be Processed and Submit Jobs #####
###############################################################

AllSubs=`ls -d1 /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-*/ses-*/func | cut -d '/' -f8,9 | sed s@'sub-'@''@g | sed s@'/ses-'@'_'@g | head -n4`

for subject in ${AllSubs} ; do

  sub=`echo $subject | cut -d '_' -f1`
  ses=`echo $subject | cut -d '_' -f2`
  output_base_dir=/dfs2/yassalab/rjirsara/ConteCenter/fmriprep

  qa=`echo ${output_base_dir}/sub-${sub}/ses-${ses}/func/sub-${sub}_ses-${ses}_task-*_bold_confounds.tsv`
  preproc=`echo ${output_base_dir}/sub-${sub}/ses-${ses}/func/sub-${sub}_ses-${ses}_task-*_*_preproc.nii`
  html=`echo ${output_base_dir}/sub-${sub}.html`

  if [ -f ${qa} ] && [ -f ${preproc} ] && [ -f ${html} ] ; then

    echo ''
    echo "##################################################################"
    echo "#sub-${sub}/ses-${ses} already ran through the fmriprep pipeline..."
    echo "##################################################################"
    echo ''

  else

    jobstats=`qstat -u $USER | grep F${sub}x${ses} | awk {'print $5'}`

    if [ "$jobstats" == "r" ] || [ "$jobstats" == "qw" ]; then

       echo ''
       echo "#####################################################"
       echo "#sub-${sub}/ses-${ses} is currently being processed..."
       echo "#####################################################"
       echo ''

    else

       echo ''
       echo "########################################################"
       echo "#Fmriprep Job Being Submitted for sub-${sub}/ses-${ses} #"
       echo "########################################################"
       echo ''

       cat /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fmriprep/Conte-One/fmriprep_preproc_pipeline.sh | sed s@"SUB"@"$sub"@g \
       | sed s@"SES"@"$ses"@g | sed s@"CONTAINER"@"$fmriprep_container"@g > SUBMITJOB_TEMP.sh

       chmod 775 SUBMITJOB_TEMP.sh
       qsub SUBMITJOB_TEMP.sh
       rm SUBMITJOB_TEMP.sh

    fi
  fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
