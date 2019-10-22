#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 4
#$ -R y
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

Files=`ls /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-${site}/BIDs_Events/${subid}_DoorsTask_*-*_*.*`
time=`date +"%D %T" | sed s@' '@','@g`
chmod -R ug+wrx ${Files}

site_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-${site}/BIDs/sub-${subid}/ses-${site}/func
bids_output=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-${subid}/ses-${site}/func
event_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-${site}/${subid}/EventFiles
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
  rm ${site}${subid}B.*
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

  cat $file | sed s@'NA'@'N/A'@g > ${file}_NEW
  mv ${file}_NEW $file

  cp $file $event_output
  name=`basename $file` 

  filetype=`basename $file | cut -d '.' -f2`
  if [[ ${filetype} == 'tsv' ]] ; then

    SiteFile=${site_output}/sub-${subid}_ses-${site}_task-doors_events.tsv
    BIDsFile=${bids_output}/sub-${subid}_ses-${site}_task-doors_events.tsv

    awk -F'\t' '{print $10,2.5,$7,$9,$10,$5}' OFS='\t' "$file" > ${SiteFile}
    awk -F'\t' '{print $10,2.5,$7,$9,$10,$5}' OFS='\t' "$file" > ${BIDsFile}
    
    OldLabel=`head -n1 ${SiteFile}`
    NewLabel=`head -n1 ${SiteFile} | sed s@'DoorsAppearTimeTotal'@'onset'@g`
    NewLabel=`echo ${NewLabel} | sed s@'6'@'duration'@g`
    NewLabel=`echo ${NewLabel} | sed s@'Response'@'responce'@g`
    NewLabel=`echo ${NewLabel} | sed s@'Contrasts'@'contrast'@g`
    NewLabel=`echo ${NewLabel} | sed s@'FeedbackAppearTimeTotal'@'feedback_onset'@g`
    NewLabel=`echo ${NewLabel} | sed s@'TrailNumTotal'@'trail_num'@g`

    cat ${SiteFile} | sed s@"${OldLabel}"@"${NewLabel}"@g | tr ' ' '\t' > ${SiteFile}_NEW
    mv ${SiteFile}_NEW ${SiteFile}

    cat ${BIDsFile} | sed s@"${OldLabel}"@"${NewLabel}"@g | tr ' ' '\t' > ${BIDsFile}_NEW
    mv ${BIDsFile}_NEW ${BIDsFile}

  fi

################################################
### Upload Copies to Flywheel to be Archived ###
################################################

  EXISTING=`fw ls "yassalab/Conte-Two-${site}/${subid}/Brain^ConteTwo/files/${name}" | cut -d ' ' -f6`

  if [ -z $EXISTING ] ; then
    fw upload "yassalab/Conte-Two-${site}/${subid}/Brain^ConteTwo/" ${file}
  fi
done

rm ${site}${subid}B.*

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
