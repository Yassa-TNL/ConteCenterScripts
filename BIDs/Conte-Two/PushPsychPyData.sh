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

output_dir=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/Spooling
mkdir -p $output_dir

/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/PullPsychoPyData.exp ${FIBRE_PASSWORD} ${output_dir}

##################################################
### Move Files to Subject Specific Directories ###
##################################################

Files=`ls /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/*_DoorsTask_*-*_*.txt`
time=`date +"%D %T" | sed s@' '@','@g`

for file in $Files ; do

  name=`basename $file` 
  subid=`echo $name | cut -d '_' -f1`
  dir_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/${subid}/PsychoPy
  mkdir ${dir_output}
  
  if [[ ! -d "${dir_output}" ]] ; then
    echo '#########################################################################'
    echo $subid' not transfered correctly - try running BIDs_Coversion Script First'
    echo '             CREATING LOG FILE FOR FUTURE INVESTIGATION                  '
    echo '#########################################################################'
    echo ${subid},${time} >> /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/FailedUploads.csv
    rm ${file}
    break
  fi

  mv $file /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/${subid}/PsychoPy/
  chmod -R ug+wrx /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/${subid}

################################################
### Upload Copies to Flywheel to be Archived ###
################################################

  fw upload "yassalab/Conte-Two/${subid}/Brain^ConteTwo/" /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two/${subid}_doorsTask_log.txt

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
