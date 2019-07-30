#!/bin/bash
#$ -N DataStorm
#$ -q ionode,ionode-lp
#$ -R y
#$ -ckpt blcr
#$ -m e
###################################################################################################
##########################              CONTE Center 2.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script automatically downloads the PsychoPy data from the Doors Guessing Task that is administered for
the Conte-Two Study. The data is automatically pulled from FIBRE than moved to subject-level directories 
and backup copies are uploaded to flywheel.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load flywheel/8.5.0 
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

##############################################################
### Run Expect Script to Download Data from Fibre's Server ###
##############################################################

/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/PullPsychoPyData.exp ${FIBRE_PASSWORD}

##################################################
### Move Files to Subject Specific Directories ###
##################################################

Files=`ls /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/*_doorsTask_log.txt`
time=`date +"%D %T" | sed s@' '@','@g`

for file in $Files ; do

  subid=`echo $file | cut -d '/' -f9 | cut -d '_' -f1`
  dir_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two/${subid}/PsychoPy
  mkdir ${dir_output}
  
  if [[ ! -d "${dir_output}" ]] ; then
    echo $subid' does not aligned with any of the existing subids from previous MRI sessions'
    echo ${subid}' will not be transfered but a Log will be Stored for Future Investigating'
    echo ${subid},${time} >> /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/PsychoPy/FailedUploads.csv
    rm /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/${subid}_doorsTask_log.txt
    break
  fi

  mv $file /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two/${subid}/PsychoPy/
  chmod -R ug+wrx /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two/${subid}

################################################
### Upload Copies to Flywheel to be Archived ###
################################################

  fw upload "yassalab/Conte-Two/${subid}/Brain^ConteTwo/" /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two/${subid}_doorsTask_log.txt

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
