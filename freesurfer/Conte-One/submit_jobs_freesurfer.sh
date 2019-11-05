#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script identifies subjects from Conte-One who did not run through DBK's freesurfer processing
pipeline and reruns them via singulatiry image.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module purge 2>/dev/null
module load singularity/3.0.0 2>/dev/null

#########################################################
##### Define New Subjects that Need to Be Processed #####
#########################################################

AllSubs=`ls -d1 /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-*/ses-*/anat/*T1w.nii.gz | cut -d '/' -f8,9 | cut -d '-' -f2,3 | sed s@'/ses-'@','@g`

for subject in ${AllSubs} ; do

  sub=`echo $subject | cut -d ',' -f1`
  ses=`echo $subject | cut -d ',' -f2`
  DBK_Data=/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-One/${sub}_tp${ses}/stats/aseg.stats
  FS_Data=/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-One-DBK/${sub}_tp${ses}/stats/aseg.stats

  if [ -f ${DBK_Data} ] || [ -f ${FS_Data} ] ; then
    
    echo ''
    echo "####################################################################"
    echo "# Data was found for sub-${sub}/ses-${ses} -- Skipping Processing..."
    echo "####################################################################"
    echo ''

  else

    jobstats=`qstat -u $USER | grep FS${sub}x${ses} | awk {'print $5'}`

    if [ ! -z "$jobstats" ]; then

       echo ''
       echo "#######################################################"
       echo "# sub-${sub}/ses-${ses} is currently being processed..."
       echo "#######################################################"
       echo ''

    else

       echo ''
       echo "###########################################################"
       echo "# Freesurfer JOB BEING SUBMITTED For sub-${sub}/ses-${ses} "
       echo "###########################################################"
       echo ''

       JobName=`echo FS${sub}x${ses}`
       Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/freesurfer/Conte-One/freesurfer_pipeline.sh 
       
       qsub -N ${JobName} ${Pipeline} ${sub} ${ses}

    fi
  fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
