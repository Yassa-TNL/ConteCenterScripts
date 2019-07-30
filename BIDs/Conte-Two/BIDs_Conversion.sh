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

This script automatically downloads the raw Conte Center 2.0 data from Flywheel and converts the images
to BIDs format where they will be processed further through various pipelines.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module purge ; module load anaconda/2.7-4.3.1 ; module load flywheel/8.5.0 
export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
export PATH=$PATH:/dfs3/som/rao_col/bin
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

########################################################
### Set Output Paths and Find Newly Scanned Subjects ###
########################################################

dir_dicom=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two

fw ls "yassalab/Conte-Two" | sed s@'rw '@''@g | grep -v test | grep -v Pilot > ${dir_dicom}/SUBS_fw.txt
ls /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/ | sed s@'sub-'@''@g > ${dir_dicom}/SUBS_hpc.txt
NewSubs=`diff ${dir_dicom}/SUBS_fw.txt ${dir_dicom}/SUBS_hpc.txt | sed -n '1!p' | sed s@'< '@''@`
rm ${dir_dicom}/SUBS_hpc.txt ${dir_dicom}/SUBS_fw.txt

if [ -z "$NewSubs" ]; then
  echo "Everything is up-to-date - No newly scanned subjects detected"
else  
  echo '⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡ '
  echo 'Newly Scanned Subjects Detected: '$NewSubs 
fi

########################################################
### Unpack the Dicoms to Prepare for BIDs Conversion ###
########################################################

for subid in $NewSubs ; do

  echo 'Downloading Dicoms for '$subid  
  mkdir -p ${dir_dicom}/${subid}
  fw download "yassalab/Conte-Two/${subid}/Brain^ConteTwo" --include dicom --force --output ${dir_dicom}/${subid}/${subid}_fw_download.tar
  tar -xvf ${dir_dicom}/${subid}/${subid}_fw_download.tar -C ${dir_dicom}/${subid}
  rm ${dir_dicom}/${subid}/${subid}_fw_download.tar

  CompressedDicoms=`find ${dir_dicom}/${subid}/scitran/yassalab/Conte-Two/${subid}/BrainConteTwo -name '*.dicom.zip'`
  
  for UNZIP in $CompressedDicoms ; do
    Sequence=`ls $UNZIP | cut -d '/' -f14`
    mkdir -p ${dir_dicom}/${subid}/DICOMs/${Sequence}
    unzip $UNZIP -d  ${dir_dicom}/${subid}/DICOMs/${Sequence}
    mv ${dir_dicom}/${subid}/DICOMs/${Sequence}/*/* ${dir_dicom}/${subid}/DICOMs/${Sequence}/
    rmdir `find ${dir_dicom}/${subid}/DICOMs/${Sequence}/ -type d -empty`
  done

####################################
### Covert Dicoms To BIDs Format ###
####################################

  echo 'Converting Dicoms to BIDs for '$subid
  mkdir -p ${dir_dicom}/${subid}/BIDs_Residual

  dcm2bids -d ${dir_dicom}/${subid}/DICOMs -p ${subid} -s 1 -c \
  /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/config_Conte-Two.json \
  -o ${dir_dicom}/${subid}/BIDs_Residual --forceDcm2niix --clobber

######################################
### Reorganize Directory Structure ###
######################################

  echo 'Reorganizing Directory Structure for '$subid
  echo '⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡ '
  mv ${dir_dicom}/${subid}/BIDs_Residual/sub-${subid} /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/
  chmod -R ug+wrx /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-${subid}
  
  zip ${dir_dicom}/${subid}/${subid}_DICOMs.zip -r ${dir_dicom}/${subid}/DICOMs
  rm -rf ${dir_dicom}/${subid}/DICOMs  
  rm -rf ${dir_dicom}/${subid}/scitran 
  chmod -R ug+wrx ${dir_dicom}/${subid}

done
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
