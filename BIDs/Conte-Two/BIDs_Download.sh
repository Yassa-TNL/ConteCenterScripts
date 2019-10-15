#!/bin/bash
#$ -q ionode,yassalab
#$ -pe openmp 8
#$ -R y
#$ -ckpt restart
########################################
### Load Software & Define Variables ###
########################################

module purge ; module load anaconda/2.7-4.3.1
module load fsl/6.0.1
module load flywheel/8.5.0
export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
export PATH=$PATH:/dfs3/som/rao_col/bin
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

subid=`echo $1`
site=`echo $2`
dir_dicom=`echo $3`

#####################################
### Download Dicoms from Flywheel ###
#####################################

mkdir -p ${dir_dicom}/${subid}
fw download "yassalab/Conte-Two-${site}/${subid}/Brain^ConteTwo" --include dicom --force --output ${dir_dicom}/${subid}/${subid}_fw_download.tar
tar -xvf ${dir_dicom}/${subid}/${subid}_fw_download.tar -C ${dir_dicom}/${subid}
rm ${dir_dicom}/${subid}/${subid}_fw_download.tar

CompressedDicoms=`find ${dir_dicom}/${subid}/scitran/yassalab/Conte-Two-UCI/${subid}/BrainConteTwo -name '*.dicom.zip'`
  
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

mkdir -p ${dir_dicom}/${subid}/BIDs_Residual

dcm2bids -d ${dir_dicom}/${subid}/DICOMs \
  -p ${subid} \
  -s 1 \
  -c /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/config_Conte-Two.json \
  -o ${dir_dicom}/${subid}/BIDs_Residual \
  --forceDcm2niix \
  --clobber

######################################
### Reorganize Directory Structure ###
######################################

cp -r ${dir_dicom}/${subid}/BIDs_Residual/sub-${subid} ${dir_dicom}/BIDs/sub-${subid}
cp -r ${dir_dicom}/${subid}/BIDs_Residual/sub-${subid} /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/
  
zip ${dir_dicom}/${subid}/${subid}_DICOMs.zip -r ${dir_dicom}/${subid}/DICOMs
chmod -R ug+wrx /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-${subid}
chmod -R ug+wrx ${dir_dicom}/BIDs/sub-${subid}
chmod -R ug+wrx ${dir_dicom}/${subid}
rm -rf ${dir_dicom}/${subid}/DICOMs  
rm -rf ${dir_dicom}/${subid}/scitran
rm -rf ${dir_dicom}/${subid}/BIDs_Residual/sub-${subid}
rm ${site}${subid}.e* ${site}${subid}.o*

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
