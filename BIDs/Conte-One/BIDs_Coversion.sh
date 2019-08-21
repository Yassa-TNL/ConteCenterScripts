#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This scripts coverts the raw Conte Center 1.0 data into BIDs Format & Logs Missing Files that 
can be resolved based on PARREC data.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module purge
module load anaconda/2.7-4.3.1
module load flywheel/8.5.0
export PATH=$PATH:/dfs3/som/rao_col/bin
export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

#############################################
### Find Newly Found Files To be Coverted ###
#############################################

audit_dir=/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One
echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/*/DICOMS | tr ' ' '\n' | cut -d '/' -f8 | cut -d '_' -f1,3 \
> ${audit_dir}/tmp_dicoms.txt
echo /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/*/* | tr ' ' '\n' | cut -d '-' -f3,4 | sed s@'/ses-'@'_'@g \
> ${audit_dir}/tmp_BIDS.txt
NewSubs=`diff ${audit_dir}/tmp_dicoms.txt ${audit_dir}/tmp_BIDS.txt | grep '<' | sed s@'< '@''@g`
rm ${audit_dir}/tmp_dicoms.txt ${audit_dir}/tmp_BIDS.txt 

echo `date +%m-%d-%Y` >> $audit_dir/Recover_Missing_Niftis.csv
echo 'subid,sequence' >> $audit_dir/Recover_Missing_Niftis.csv

###########################################
### Convert DICOMs files to BIDs Format ###
###########################################

for subid in $NewSubs ; do

  echo 'Converting Dicoms to BIDs for '$subid
  sub=`echo $subid | cut -d '_' -f1`
  ses=`echo $subid | cut -d '_' -f2` 
  Dicoms=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${sub}_*_${ses}/DICOMS
  Residual=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/${sub}_*_${ses}
  mkdir -p $Residual

  dcm2bids -d $Dicoms -p ${sub} -s ${ses} -c \
  /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/config_Conte-One.json \
  -o ${Residual} --forceDcm2niix --clobber

#########################################################
### Convert PARREC files to NIFTI For Double Checking ###
#########################################################

  PARREC=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${sub}_*_${ses}/PARREC
  if [ ! -z "$PARREC" ] ; then

    parrec_output=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/${sub}_*_${ses}/tmp_parrec2bids
    mkdir -p ${parrec_output}
    dcm2niix ${PARREC}/*
    mv `ls ${PARREC}/* | grep _PARREC_` $parrec_output

#######################################################################
### Create Log File To Determine Missing Files that can be Resolved ###
#######################################################################

    existing_nifti=`ls ${Residual}/sub-${sub}/ses-${ses}/anat/*T1w*.nii.gz`
    T1w_parrec_nifti=`ls $parrec_output/*.nii.gz |tr ' ' '\n' | grep MPrage | tail -n1`
    T1w_parrec_json=`ls $parrec_output/*.json |tr ' ' '\n' | grep MPrage | tail -n1`

    if [ -z "${existing_nifti}" ] && [ ! -z "${T1w_parrec_nifti}" ] ; then
      echo 'Replacing Missing T1-weighted Nifti with PARREC data'
      echo "${subid},T1w" >> /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/PARREC_Replacements.csv
    fi

    existing_nifti=`ls ${Residual}/sub-${sub}/ses-${ses}/dwi/*dwi*.nii.gz`
    DWI_parrec_nifti=`ls $parrec_output/*.nii.gz |tr ' ' '\n' | grep DTI `
    DWI_parrec_json=`ls $parrec_output/*.json |tr ' ' '\n' | grep DTI `

    if [ -z "${existing_nifti}" ] && [ ! -z "${DWI_parrec_nifti}" ] ; then
      echo 'Replacing Missing difussion-weighted Nifti with PARREC data'
      echo "${subid},dwi" >> /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/PARREC_Replacements.csv
    fi

    existing_nifti=`ls ${Residual}/sub-${sub}/ses-${ses}/func/*REST*.nii.gz`
    rest_parrec_nifti=`ls $parrec_output/*.nii.gz |tr ' ' '\n' | grep RestfMRI`
    rest_parrec_json=`ls $parrec_output/*.json |tr ' ' '\n' | grep RestfMRI`

    if [ -z "${existing_nifti}" ] && [ ! -z "${rest_parrec_nifti}" ] ; then
      echo 'Replacing Missing Resting-state Nifti with PARREC data'
      echo "${subid},REST" >> /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/PARREC_Replacements.csv  
    fi

    existing_nifti=`ls ${Residual}/sub-${sub}/ses-${ses}/func/*HIPP*.nii.gz`
    hipp_parrec_nifti=`ls $parrec_output/*.nii.gz |tr ' ' '\n' | grep HippTask`
    hipp_parrec_json=`ls $parrec_output/*.json |tr ' ' '\n' | grep HippTask`

    if [ -z "${existing_nifti}" ] && [ ! -z "${hipp_parrec_nifti}" ] ; then
      echo 'Replacing Missing Hipp Task-Based Nifti with PARREC data'
      echo "${subid},Hipp" >> /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/PARREC_Replacements.csv
    fi

    existing_nifti=`ls ${Residual}/sub-${sub}/ses-${ses}/func/*AMG*.nii.gz`
    amygdala_parrec_nifti=`ls $parrec_output/*.nii.gz |tr ' ' '\n' | grep AmygdalaTask`
    amygdala_parrec_json=`ls $parrec_output/*.json |tr ' ' '\n' | grep AmygdalaTask`

    if [ -z "${existing_nifti}" ] && [ ! -z "${amygdala_parrec_nifti}" ] ; then
      echo 'Replacing Missing Amygdala Task-Based Nifti with PARREC data'
      echo "${subid},AMG" >> /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/PARREC_Replacements.csv 
    fi
  fi

##############################################################
### Move Files to Permanent Locations & Adjust Permissions ###
##############################################################

  OUTPUT=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-${sub}
  mkdir -p ${OUTPUT}
  mv /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/${sub}_*_${ses}/sub-${sub}/ses-${ses} ${OUTPUT}
  chmod -R 775 ${OUTPUT}

  mkdir /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${sub}_*_${ses}/NIFTIS
  mv /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/${sub}_*_${ses}/tmp_* /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${sub}_*_${ses}/NIFTIS/
  chmod -R 775 /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${sub}_*_${ses}

  cat /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling/PARREC_Replacements.csv >> $audit_dir/Recover_Missing_Niftis.csv
  rm -rf /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/Spooling
  chmod 775 $audit_dir/Recover_Missing_Niftis.csv

done

###############################################################
### Define the Newly Scanned Subjects from Baseline Dataset ###
###############################################################

audit_dir=/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One
echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/*_0 | tr ' ' '\n' | cut -d '/' -f8 | cut -d '_' -f1,3 \
> ${audit_dir}/tmp_nifti.txt
echo /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-*/ses-0 | tr ' ' '\n' | cut -d '-' -f3,4 | sed s@'/ses-'@'_'@g \
> ${audit_dir}/tmp_BIDS.txt
NewSubs=`diff ${audit_dir}/tmp_nifti.txt ${audit_dir}/tmp_BIDS.txt | grep '<' | sed s@'< '@''@g`
rm ${audit_dir}/tmp_nifti.txt ${audit_dir}/tmp_BIDS.txt 

######################################
### Copy NIFTI Files From Baseline ###
######################################

for subid in $NewSubs ; do

  echo 'Copying Niftis to BIDs for '$subid
  sub=`echo $subid | cut -d '_' -f1`
  ses=`echo $subid | cut -d '_' -f2` 

  nifti=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${sub}_*_${ses}/NIFTIS/sub-${sub}_ses-${ses}_T1w.nii.gz
  bids_dir=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-${sub}/ses-${ses}/anat/
  mkdir -p $bids_dir

  cp $nifti $bids_dir
  chmod -R 775 /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-${sub}
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
