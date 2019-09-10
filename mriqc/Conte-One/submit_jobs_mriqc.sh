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
mriqc pipeline via singulatiry image.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module purge 2>/dev/null 
module load singularity/3.0.0 2>/dev/null 

#######################################################
##### Build MRIQC Singularity Image if Missing #####
#######################################################

mriqc_container=`echo /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/mriqc/mriqc-latest.simg`
if [ -f $mriqc_container ] ; then

  version=`singularity run --cleanenv $mriqc_container --version | cut -d ' ' -f2`
  echo ''
  echo "Preprocessing will be Completed using MRIQC Singularity Image: ${version}"
  echo ''

else

  echo ''
  echo "Singularity Image Not Found -- Building New Containter with Latest Version of MRIQC"
  echo ''
  singularity build ${mriqc_container} docker://poldracklab/mriqc:latest

fi

#########################################################
##### Define New Subjects that Need to Be Processed #####
#########################################################

AllSubs=`ls -d1 /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-*/ses-* | cut -d '/' -f8,9 | cut -d '-' -f2,3 | sed s@'/ses-'@'_'@g`

for subject in ${AllSubs} ; do

  sub=`echo $subject | cut -d '_' -f1`
  ses=`echo $subject | cut -d '_' -f2`
  output_base_dir=/dfs2/yassalab/rjirsara/ConteCenter/mriqc/Conte-One/sub-${sub}

  html=`echo ${output_base_dir}/sub-${sub}_ses-${ses}_*.html | cut -d ' ' -f1`

  if [ -f ${html} ] ; then

    echo ''
    echo "################################################################"
    echo "#sub-${sub}/ses-${ses} already ran through the mriqc pipeline..."
    echo "################################################################"
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
       echo "#####################################################"
       echo "#MRIQC JOB BEING SUBMITTED For sub-${sub}/ses-${ses} "
       echo "#####################################################"
       echo ''

       JobName=`echo QC${sub}x${ses}`
       Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/mriqc/Conte-One/mriqc_pipeline.sh 
       
       qsub -N ${JobName} ${Pipeline} ${sub} ${ses} ${mriqc_container}

    fi
  fi
done

####################################
##### Run Group-Level Analyses #####
####################################

JobStats=`qstat -u $USER | grep "QC_GROUP" | awk {'print $5'}`
GroupHTML=`echo ${output_base_dir}/sub-${sub}_ses-${ses}_*.html | cut -d ' ' -f1`

if [ "$JobStats" == "r" ] || [ "$JobStats" == "qw" ] || [ -f "$GroupHTML" ] ; then

  echo ''
  echo "############################################################"
  echo "# Group-Level Analyses Are Completed -- Skipping Processing "
  echo "############################################################"
  echo ''

else

  echo ''
  echo "###############################################"
  echo "# Job Being Submitted for Group-Level Analyses "
  echo "###############################################"
  echo ''

  JobName=`echo QC_GROUP`
  Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/mriqc/Conte-One/mriqc_pipeline.sh 
       
  qsub -N ${JobName} ${Pipeline} GROUP ${mriqc_container}

fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
