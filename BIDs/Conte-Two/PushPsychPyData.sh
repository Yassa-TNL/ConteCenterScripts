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
site=`echo $2`

#####################
### Quality Check ###
#####################

if [[ -z $subid || -z ${site} ]] ; then

  echo "Required Input Variables Not Define - Exiting..."
  exit 0

fi

###############################################
### Define Output File and Correctly Format ###
###############################################

Files=`ls /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/BIDs_Events/${subid}_DoorsTask_*-*_*.*`
time=`date +"%D %T" | sed s@' '@','@g`
chmod -R ug+wrx ${Files}

site_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/BIDs/sub-${subid}/ses-1/func/
bids_output=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-${subid}/ses-${site}/func/
event_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/${subid}/EventFiles
mkdir ${event_output}

#################################################
### Perform Quality CHecks And Log Any Errors ###
#################################################

if [[  -z "${Files}" ]] ; then
  echo "##########################################################################"
  echo "    $subid' ALL FILES ARE MISSING FROM TRANSFER -- PUSH AND PULL FAILED   "
  echo "              CREATING LOG FILE FOR FUTURE INVESTIGATION                  "
  echo "##########################################################################"
  echo ${subid},${time},"ALLMISSING" >> /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/EventFileErrors.csv
  exit 0
fi

if [[ -z `echo $Files | grep "tsv" | sed s@" "@""@g` ]] ; then
  echo "##########################################################################"
  echo " $subid' MRI Task Was Not Run To Completion Additional Processing Needed  "
  echo "              CREATING LOG FILE FOR FUTURE INVESTIGATION                  "
  echo "##########################################################################"
  echo ${subid},${time},"TSVFileMissing" >> /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/EventFileErrors.csv
fi

if [[ ! -d "${site_output}" ]] || [[ ! -d "${bids_output}" ]] || [[ ! -d "${event_output}" ]] ; then
  echo "##########################################################################"
  echo " $subid Not Transfered Correctly - Try Running BIDs_Coversion Script First"
  echo "              CREATING LOG FILE FOR FUTURE INVESTIGATION                  "
  echo "##########################################################################"
  echo ${subid},${time},"OutDirMissing" >> /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/EventFileErrors.csv
fi

########################################
### Move Files to Output Directories ###
########################################

for file in $Files ; do

  name=`basename $file` 
  cp $file $event_output

  filetype=`basename $file | cut -d '.' -f2`
  if [[ ${filetype} == 'tsv' ]] ; then

    cp $file ${site_output}/sub-${subid}_ses-${site}_task-doors_events.tsv
    cp $file ${bids_output}/sub-${subid}_ses-${site}_task-doors_events.tsv

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
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
