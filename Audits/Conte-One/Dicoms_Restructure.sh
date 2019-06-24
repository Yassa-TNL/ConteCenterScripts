#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script reorganizes the dicoms and PARREC files for the Conte Center 1.0 data and takes an audit
of any potentially missing files based on a csv that Dr. Keator sent via email.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

input_dir=`echo /dfs2/yassalab/ConteCenter/1point0/RawData`
output_dir_audits=`echo /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One`
output_dir_dicoms=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One`

############################################################################
### Create new directory structure to organize dicoms and PAR/REC files  ###
############################################################################

### Scans Directory ###

for sub in `echo ${input_dir}/Scans/*_*_MRI*` ; do

  SUBID=`echo $sub | cut -d '/' -f8 | cut -d '_' -f1`
  STUDY_VISIT=`echo $sub | cut -d '/' -f8 | cut -d '_' -f2`
  MRI_VISIT=`echo $sub | cut -d '/' -f8 | cut -d '_' -f3 | sed s@'MRI'@''@g`
  
  mkdir -p ${output_dir_dicoms}/sub-${SUBID}/ses-${MRI_VISIT}
  cp -r ${input_dir}/Scans/${SUBID}_${STUDY_VISIT}_MRI${MRI_VISIT}/DICOM ${output_dir_dicoms}/sub-${SUBID}/ses-${MRI_VISIT}/ 2>/dev/null
  cp -r ${input_dir}/Scans/${SUBID}_${STUDY_VISIT}_MRI${MRI_VISIT}/PARREC ${output_dir_dicoms}/sub-${SUBID}/ses-${MRI_VISIT}/ 2>/dev/null
  echo 'Completed Reorganizing Subject '$SUBID' Session Number '${MRI_VISIT}

done

###  Recent Scans Directory ###

for sub in `echo ${input_dir}/RecentScans_1point0/*_0*_0*` ; do

  SUBID=`echo $sub | cut -d '/' -f8 | cut -d '_' -f1`
  STUDY_VISIT=`echo $sub | cut -d '/' -f8 | cut -d '_' -f2 | sed s@'0'@''@g`
  MRI_VISIT=`echo $sub | cut -d '/' -f8 | cut -d '_' -f3 | sed s@'0'@''@g`
  
  mkdir -p ${output_dir_dicoms}/sub-${SUBID}/ses-${MRI_VISIT}
  cp -r ${input_dir}/RecentScans_1point0/${SUBID}_*${STUDY_VISIT}_*${MRI_VISIT}/DICOM ${output_dir_dicoms}/sub-${SUBID}/ses-${MRI_VISIT}/ 2>/dev/null
  cp -r ${input_dir}/RecentScans_1point0/${SUBID}_*${STUDY_VISIT}_*${MRI_VISIT}/ParRec ${output_dir_dicoms}/sub-${SUBID}/ses-${MRI_VISIT}/ 2>/dev/null
  echo 'Completed Reorganizing Subject '$SUBID' Session Number '${MRI_VISIT}

done

find ${output_dir_dicoms} -type d -empty > ${output_dir_audits}/logs/DicomsandPARRECs_Missing.txt

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
