#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

Audits MRI scans that did not successful pass through the MRIQC problem due to problems with the raw
acquistion files (PAR/REC & DICOMs).

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

AllScans=`ls -d1 /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-*/ses-*/*/* | grep -v dwi | grep .nii.gz | cut -d '/' -f11`

i=0
for scan in $AllScans ; do
 
  sub=`echo $scan | cut -d '-' -f2 | cut -d '_' -f1`
  ses=`echo $scan | cut -d '-' -f3 | cut -d '_' -f1`
  mriqc_name=`echo $scan | sed s@".nii.gz"@".html"@g`
  mriqc_fullpath=/dfs2/yassalab/rjirsara/ConteCenter/mriqc/Conte-One/sub-${sub}/${mriqc_name}
  
  if [ -f ${mriqc_fullpath} ] ; then
    
    echo ""
    echo "################################"
    echo "QC Report Existing for MRI scan:" $scan             
    echo "################################"
    echo ""

  else

    echo ""
    echo "#####################"
    echo "Manual QC Needed For:" $scan
    echo "#####################"
    echo ""

    troubleshoot[i]=$(echo $scan)

    (( i++ ))


  fi
done






for check in ${troubleshoot[@]} ; do

  echo $check

done




  sub=`echo $subject | cut -d '_' -f1`
  ses=`echo $subject | cut -d '_' -f2`
  output_base_dir=/dfs2/yassalab/rjirsara/ConteCenter/mriqc/Conte-One/sub-${sub}

  html=`echo ${output_base_dir}/sub-${sub}_ses-${ses}_*.html | cut -d ' ' -f1`

  if [ -f ${html} ] ; then
