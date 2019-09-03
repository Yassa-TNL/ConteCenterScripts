#!/bin/bash
#$ -N DataStorm
#$ -q ionode,ionode-lp
#$ -R y
#$ -ckpt blcr
#$ -m e
###################################################################################################
##########################                     ORE                       ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script automatically downloads the raw ORE data from Flywheel and converts the images
to BIDs format where they will be processed further through various pipelines for Jessie's Study.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module purge ; module load anaconda/2.7-4.3.1
module load fsl/6.0.1
module load flywheel/8.5.0
export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
export PATH=$PATH:/dfs3/som/rao_col/bin
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

########################################################
### Set Output Paths and Find Newly Scanned Subjects ###
########################################################

dir_dicom=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/ORE
dir_bids=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/ORE

fw ls "yassalab/ORE" | sed s@'rw '@''@g | grep -v test | grep -v Pilot > ${dir_dicom}/SUBS_fw.txt
ls ${dir_bids} | sed s@'sub-'@''@g | grep -v dataset > ${dir_dicom}/SUBS_hpc.txt
NewSubs=`diff ${dir_dicom}/SUBS_fw.txt ${dir_dicom}/SUBS_hpc.txt | sed -n '1!p' | sed s@'< '@''@ | grep -v 3d3 `
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
  fw download "yassalab/ORE/${subid}/Brain^ORE" --include dicom --force --output ${dir_dicom}/${subid}/${subid}_fw_download.tar
  tar -xvf ${dir_dicom}/${subid}/${subid}_fw_download.tar -C ${dir_dicom}/${subid}
  rm ${dir_dicom}/${subid}/${subid}_fw_download.tar

  CompressedDicoms=`find ${dir_dicom}/${subid}/scitran/yassalab/ORE/${subid}/BrainORE -name '*.dicom.zip'`
  
  for UNZIP in $CompressedDicoms ; do
    Sequence=`ls $UNZIP | cut -d '/' -f13`
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
  /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/ORE/config_ORE.json \
  -o ${dir_dicom}/${subid}/BIDs_Residual --forceDcm2niix --clobber

########################################
### Generate TSNR Maps of Func Scans ###
########################################

  mkdir -p ${dir_dicom}/${subid}/TSNR_Maps
  imgs=`ls ${dir_dicom}/${subid}/BIDs_Residual/sub-${subid}/ses-1/func/sub-${subid}_ses-1_task-*.nii.gz`
  for img in $imgs ; do
    base=`echo ${img} | cut -d '/' -f12 | cut -d '_' -f1,2,3,4`
    fslmaths ${img} -Tstd ${dir_dicom}/${subid}/TSNR_Maps/${base}_tstd.nii.gz
    fslmaths ${img} -Tmean ${dir_dicom}/${subid}/TSNR_Maps/${base}_tmean.nii.gz
    fslmaths ${dir_dicom}/${subid}/TSNR_Maps/${base}_tmean.nii.gz -div ${dir_dicom}/${subid}/TSNR_Maps/${base}_tstd.nii.gz \
    ${dir_dicom}/${subid}/TSNR_Maps/${base}_tsnr.nii.gz
  done 

######################################
### Reorganize Directory Structure ###
######################################

  echo 'Reorganizing Directory Structure for '$subid
  echo '⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡ '
  mv ${dir_dicom}/${subid}/BIDs_Residual/sub-${subid} ${dir_bids}
  chmod -R ug+wrx ${dir_bids}/sub-${subid}
  
  zip ${dir_dicom}/${subid}/${subid}_DICOMs.zip -r ${dir_dicom}/${subid}/DICOMs
  rm -rf ${dir_dicom}/${subid}/DICOMs  
  rm -rf ${dir_dicom}/${subid}/scitran 
  chmod -R ug+wrx ${dir_dicom}/${subid}

done
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
