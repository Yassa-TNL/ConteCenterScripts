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

mriqc_container=`echo /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/mriqc/mriqc-latest.simg`
if [ -f $mriqc_container ] ; then

  version=`singularity run --cleanenv $mriqc_container --version | cut -d ' ' -f2`
  echo "Preprocessing will be Completed using MRIQC Singularity Image: ${version}"

else

  echo "Singularity Image Not Found -- Building New Containter with Latest Version of MRIQC"
  singularity build ${mriqc_container} docker://poldracklab/mriqc:latest

fi

###############################################################
##### Define New Subjects to be Processed and Submit Jobs #####
###############################################################

AllSubs=`ls -d1 /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-* | cut -d '/' -f8,9 | sed s@'sub-'@''@g | sed s@'/ses-'@'_'@g | head -n3`

for subject in ${AllSubs} ; do

  sub=`echo $subject | cut -d '_' -f1`
  ses=`echo $subject | cut -d '_' -f2`
  output_base_dir=/dfs2/yassalab/rjirsara/ConteCenter/mriqc/Conte-One

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

    jobstats=`qstat -u $USER | grep QC${sub}x${ses} | awk {'print $5'}`

    if [ "$jobstats" == "r" ] || [ "$jobstats" == "qw" ]; then

       echo ''
       echo "#####################################################"
       echo "#sub-${sub}/ses-${ses} is currently being processed..."
       echo "#####################################################"
       echo ''

    else

       echo ''
       echo "######################################################"
       echo "#MRIQC JOB BEING SUBMITTED for sub-${sub}/ses-${ses} #"
       echo "######################################################"
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
