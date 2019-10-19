#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 4
#$ -R n
#$ -ckpt restart
################################
### Load Software and Inputs ###
################################

export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
source /data/users/rjirsara/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

subid=`echo $1`

#####################
### Quality Check ###
#####################

if [[ -z $subid ]] ; then

  echo "Required Input Variables Not Define - Exiting..."
  exit 0

fi

###############################################
### Define Output File and Correctly Format ###
###############################################

Files=`ls /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/BIDs_Events/${subid}_DoorsTask_*-*_*.*`
time=`date +"%D %T" | sed s@' '@','@g`
chmod -R ug+wrx ${Files}

for file in $Files ; do

  name=`basename $file` 
  site_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/BIDs/sub-${subid}/ses-1/func/
  bids_output=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-${subid}/ses-1/func/
  event_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/${subid}/EventFiles

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

  cp $file $event_output

  filetype=`basename $file | cut -d '.' -f2`
  if [[ ${filetype} == 'tsv' ]] ; then

    cp $file ${site_output}/sub-${subid}_ses-1_task-doors_events.tsv
    cp $file ${bids_output}/sub-${subid}_ses-1_task-doors_events.tsv

  fi

################################################
### Upload Copies to Flywheel to be Archived ###
################################################

  EXISTING=`fw ls "yassalab/Conte-Two-UCI/${subid}/Brain^ConteTwo/files/${name}" | cut -d ' ' -f6`

  if [ -z $EXISTING ] ; then
    fw upload "yassalab/Conte-Two-UCI/${subid}/Brain^ConteTwo/" ${file}
  fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
