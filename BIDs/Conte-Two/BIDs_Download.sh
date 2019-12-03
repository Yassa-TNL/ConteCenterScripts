#!/bin/bash
#$ -q yassalab,ionode
#$ -pe openmp 8
#$ -R y
#$ -ckpt restart
################################
### Load Software and Inputs ###
################################

module purge ; module load anaconda/2.7-4.3.1 ; module load fsl/6.0.1
export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

subid=`echo $1`
site=`echo $2`
dir_dicom=`echo $3`

#############################
### Quality of Life Check ###
#############################

if [[ -z $subid || -z $site || -z $dir_dicom ]] ; then

	echo "Required Input Variables Not Define - Exiting..."
	exit 0

else

	config=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/config_Conte-Two.json
	mkdir -p ${dir_dicom}/${subid}/BIDs_Residual

fi

######################################
### Download and Reorganize Dicoms ###
######################################

mkdir -p ${dir_dicom}/${subid}
fw download "yassalab/Conte-Two-${site}/${subid}" \
	--include dicom \
	--force \
	--output ${dir_dicom}/${subid}/${subid}_fw_download.tar
tar -xvf ${dir_dicom}/${subid}/${subid}_fw_download.tar -C ${dir_dicom}/${subid}

CleanFileNames=`find ${dir_dicom}/${subid}/scitran/yassalab/Conte-Two-${site}/${subid} -name '*.dicom.zip' | sed s@' '@'TEMP'@g`
for RemoveSpaces in $CleanFileNames ; do

	mkdir -p `dirname $RemoveSpaces | sed s@'TEMP'@'_'@g`
	mv -f "`echo $RemoveSpaces | sed s@'TEMP'@' '@g`" `echo $RemoveSpaces | sed s@'TEMP'@'_'@g`

done

CompressedDicoms=`find ${dir_dicom}/${subid}/scitran/yassalab/Conte-Two-${site}/${subid} -name '*.dicom.zip'`
for UNZIP in $CompressedDicoms ; do

	Sequence=`echo $UNZIP | cut -d '/' -f14`
	mkdir -p ${dir_dicom}/${subid}/DICOMs/${Sequence}
	unzip $UNZIP -d	"${dir_dicom}/${subid}/DICOMs/${Sequence}"
	mv ${dir_dicom}/${subid}/DICOMs/${Sequence}/*/* ${dir_dicom}/${subid}/DICOMs/${Sequence}/
	rmdir `find ${dir_dicom}/${subid}/DICOMs/${Sequence}/ -type d -empty`

done

####################################
### Covert Dicoms To BIDs Format ###
####################################

dcm2bids -d ${dir_dicom}/${subid}/DICOMs \
	-p ${subid} \
	-s ${site} \
	-c ${config} \
	-o ${dir_dicom}/${subid}/BIDs_Residual \
	--forceDcm2niix \
	--clobber
	
######################################
### Reorganize Directory Structure ###
######################################

rm ${site}${subid}A.*
rm -rf ${dir_dicom}/${subid}/scitran
#rm -rf ${dir_dicom}/${subid}/DICOMs 
rm ${dir_dicom}/${subid}/${subid}_fw_download.tar

outdir=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-${subid}
mkdir -p ${outdir}
mv ${dir_dicom}/${subid}/BIDs_Residual/sub-${subid}/ses-${site} ${outdir}

chmod -R ug+wrx /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-${subid}
chmod -R ug+wrx ${dir_dicom}/${subid}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
