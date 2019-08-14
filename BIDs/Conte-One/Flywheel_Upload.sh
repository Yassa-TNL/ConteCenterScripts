#!/bin/bash
#$ -N FlywheelBlitz
#$ -q ionode,ionode-lp
#$ -ckpt blcr
#$ -m e
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This scripts uploads the raw Conte Center 1.0 data onto flywheel for back up.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

##################################################
### Define Newly Found Subjects to be Uploaded ###
##################################################

dir_dicom=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One

fw ls "yassalab/Conte-One" | sed s@'rw '@''@g | grep -v csv | grep -v MRI | grep -v files > ${dir_dicom}/SUBS_fw.txt
ls /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One | grep -v txt > ${dir_dicom}/SUBS_hpc.txt
NewSubs=`diff ${dir_dicom}/SUBS_fw.txt ${dir_dicom}/SUBS_hpc.txt | grep '>' | sed s@'> '@@g`
rm ${dir_dicom}/SUBS_hpc.txt ${dir_dicom}/SUBS_fw.txt

if [ -z "$NewSubs" ]; then
  echo "Everything is up-to-date - No newly scanned subjects detected"
else
  echo 'Newly Scanned Subjects Detected: '$NewSubs 
fi

##########################################################
### Upload Newly Found RawFiles to Flywheel for BackUp ###
##########################################################

for subject in $NewSubs ; do

  subid=`echo $subject | cut -d '_' -f1`
  ses=`echo $subject | cut -d '_' -f3`
  datatype=`ls /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${ses}/`

  for data in $datatype ; do

  if [ $data = "DICOMS" ]; then
    echo "Dicoms Detected for $subject"
    dicom_dir=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${ses}/${data}`
    /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/UploadDicoms.exp ${dicom_dir} ${subject}
  fi

  if [ $data = "PARREC" ]; then
    echo "ParRec Files Detected for $subject"
    fw_date=`fw ls "yassalab/Conte-One/${subject}" | head -n1 | awk {'print $5,$6'}`
    parrec_dir=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${ses}/${data}`
    /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/UploadParRecs.exp ${parrec_dir} ${subject} "${fw_date}"
  fi

  if [ $data = "NIFTIS" ]; then
    echo "Nifti Files Detected for $fw_subid"
    nifti_dir=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${ses}/${data}`
    /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/UploadNiftis.exp ${nifti_dir}
  fi

  done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
