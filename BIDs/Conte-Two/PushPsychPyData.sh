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

########################################################
### Check Output Files Exist and Correctly Formatted ###
########################################################

Files=`ls ${output_dir}/*_DoorsTask_*-*_*.*`
time=`date +"%D %T" | sed s@' '@','@g`
chmod -R ug+wrx ${output_dir}

for file in $Files ; do

  name=`basename $file` 
  subid=`echo $name | cut -d '_' -f1`
  site_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/BIDs/sub-${subid}/ses-1/func/
  bids_output=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-${subid}/ses-1/func/
  event_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/${subid}/EventFiles
  EXISTING=`fw ls "yassalab/Conte-Two-UCI/${subid}/Brain^ConteTwo/files/${name}"`

  if [ ! -z $EXISTING ] ; then
    break
  fi
  
  if [ ! -d ${event_output} ] ; then
    mkdir ${event_output} 
  fi

  if [[ ! -d "${site_output}" ]] || [[ ! -d "${bids_output}" ]] || [[ ! -d "${event_output}" ]] ; then
    echo "##########################################################################"
    echo "$subid' not transfered correctly - try running BIDs_Coversion Script First"
    echo "              CREATING LOG FILE FOR FUTURE INVESTIGATION                  "
    echo "##########################################################################"
    echo ${subid},${time} >> /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/Failed_Event_FW-Uploads.csv
    break
  fi

########################################
### Move Files to Output Directories ###
########################################

  filetype=`basename $file | cut -d '.' -f2`
  if [[ ${filetype} == 'tsv' ]] ; then

    cp $file ${site_output}/sub-${subid}_ses-1_task-doors_events.tsv
    cp $file ${bids_output}/sub-${subid}_ses-1_task-doors_events.tsv

  fi

  cp $file $event_output

################################################
### Upload Copies to Flywheel to be Archived ###
################################################

  fw upload "yassalab/Conte-Two-UCI/${subid}/Brain^ConteTwo/" ${file}

done

rm -rf ${output_dir}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
