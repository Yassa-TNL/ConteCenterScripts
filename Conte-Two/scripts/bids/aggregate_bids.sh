#!/bin/bash
#$ -N BIDsxTwo 
#$ -q free*,yassalab
#$ -pe openmp 8
#$ -R y
#$ -ckpt restart
#########################################################
### Define Root Directories and Software Dependencies ###
#########################################################

DIR_TOOLBOX=/dfs7/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs7/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two

mkdir -p $DIR_PROJECT/dicoms/UCI/bids $DIR_PROJECT/dicoms/UCSD/bids $DIR_PROJECT/bids
module purge ; module load anaconda/2.7-4.3.1 fsl/6.0.1
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

################################
### UCI: Download From FIBRE ###
################################

SCRIPT_FIBRE=$DIR_TOOLBOX/dicom_management/fibre/FIBRE_Download.exp
DIR_FIBRE=/mridata/upload/Yassa/Conte-Two/BanditTask/*

if [[ -f $SCRIPT_FIBRE && ! -z $DIR_FIBRE && ! -z $FIBRE_PASSWORD ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #"
	echo "Downloading Data From FIBRE "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #"
	$SCRIPT_FIBRE $DIR_FIBRE $DIR_PROJECT/dicoms/UCI/events $FIBRE_PASSWORD
fi

###################################
### UCI: Download From Flywheel ###
###################################

SCRIPT_FW_DOWNLOAD=$DIR_TOOLBOX/dicom_management/flywheel/Flywheel_Download.sh
DIR_FLYWHEEL=yassalab/Conte-Two-UCI
OPT_SUB_EXCLUDE="NIFTI gephys conte_success_20191122 FINAL Test TEST"

if [[ -f $SCRIPT_FW_DOWNLOAD && ! -z $DIR_FLYWHEEL && ! -z $FLYWHEEL_API_TOKEN ]] ; then 
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	echo "Downloading Data From Flywheel "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	$SCRIPT_FW_DOWNLOAD $DIR_FLYWHEEL $DIR_PROJECT/dicoms/UCI $FLYWHEEL_API_TOKEN "$OPT_SUB_EXCLUDE"
fi

####################################################
### UCI: Brain Imaging Data Structure Conversion ###
####################################################

SCRIPT_DCM2BIDS=$DIR_TOOLBOX/dicom_management/bids_conversion/Conversion_dcm2bids.sh
FILE_CONFIG=$DIR_PROJECT/scripts/bids/config_bids.json
OPT_LONGITUDINAL=UCI
OPT_RM_DICOMS=FALSE

if [[ -f $SCRIPT_DCM2BIDS && -f $FILE_CONFIG ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	echo "Coverting Data into BIDs Format - dcm2bids "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	$SCRIPT_DCM2BIDS $DIR_PROJECT/dicoms/UCI $FILE_CONFIG $OPT_LONGITUDINAL $OPT_RM_DICOMS
fi

########################################################
### Modify MetaData to Adhere to BIDS Specifications ###
########################################################

SCRIPT_EDIT_META=$DIR_TOOLBOX/dicom_management/bids_conversion/MetaData_Modification.py
OPT_GEN_FMAP_FUNC=TRUE
OPT_GEN_FMAP_DWI=TRUE
OPT_ADD_DEFAULT_ST=FALSE

if [[ -f $SCRIPT_EDIT_META ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "Editing Meta Data to Adhere to BIDS Specifications "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	python $SCRIPT_EDIT_META $DIR_PROJECT/dicoms/UCI $OPT_GEN_FMAP_FUNC $OPT_GEN_FMAP_DWI $OPT_ADD_DEFAULT_ST
fi

#############################################
### Generate BIDS Validation & NDA Report ###
#############################################

SCRIPT_GEN_REPORT=$DIR_TOOLBOX/dicom_management/bids_conversion/Validation_Report.sh
OPT_GUID_FILE=$DIR_PROJECT/audits/GUID_reference-UCI.txt

if [[ -f $SCRIPT_GEN_REPORT ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	echo "Generating BIDs Validation Report to Assess Standardization "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	$SCRIPT_GEN_REPORT $DIR_PROJECT/dicoms/UCI ${OPT_GUID_FILE}
fi

#################################
### Upload Events To Flywheel ###
#################################

SCRIPT_FW_UPLOAD=$DIR_TOOLBOX/dicom_management/flywheel/Flywheel_Upload.sh
DIR_FLYWHEEL=yassalab/Conte-Two-UCI
DIRNAMExTYPE="Eventsxfolder"

if [[ -f $SCRIPT_FW_UPLOAD  ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "Uploading Events To Subject-Level Directories In Flyweel "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	#USE AFTER EVENT FILES HAVE BEEN CLEANED AND REFORMATTED
	#echo "$SCRIPT_FW_UPLOAD $DIR_PROJECT/dicoms/UCI $DIR_FLYWHEEL $DIRNAMExTYPE $FLYWHEEL_API_TOKEN"
fi


#   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡  ⚡   ⚡   ⚡  #
####################################
### UCSD: Download From Flywheel ###
####################################
#   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡  ⚡   ⚡   ⚡  #

SCRIPT_FW_DOWNLOAD=$DIR_TOOLBOX/dicom_management/flywheel/Flywheel_Download.sh
DIR_FLYWHEEL=yassalab/Conte-Two-UCSD
OPT_SUB_EXCLUDE=""

SCRIPT_EDIT_META=$DIR_TOOLBOX/dicom_management/bids_conversion/MetaData_Modification.py
OPT_GEN_FMAP_FUNC=FALSE
OPT_GEN_FMAP_DWI=FALSE
OPT_ADD_DEFAULT_ST=FALSE

SCRIPT_GEN_REPORT=$DIR_TOOLBOX/dicom_management/bids_conversion/Validation_Report.sh
OPT_GUID_FILE=$DIR_PROJECT/audits/GUID_reference-UCSD.txt

if [[ -f $SCRIPT_FW_DOWNLOAD && ! -z $DIR_FLYWHEEL && ! -z $FLYWHEEL_API_TOKEN ]] ; then 
	$SCRIPT_FW_DOWNLOAD $DIR_FLYWHEEL $DIR_PROJECT/dicoms/UCSD $FLYWHEEL_API_TOKEN "$OPT_SUB_EXCLUDE"
	python $SCRIPT_EDIT_META $DIR_PROJECT/dicoms/UCSD $OPT_GEN_FMAP_FUNC $OPT_GEN_FMAP_DWI $OPT_ADD_DEFAULT_ST
	for FILE in `find $DIR_PROJECT/dicoms/UCSD -iname *.nii.gz.json` ; do
		mv $FILE `echo $FILE | sed s@'.nii.gz.'@'.'@g`
	done
	$SCRIPT_GEN_REPORT $DIR_PROJECT/dicoms/UCSD ${OPT_GUID_FILE}	
fi

#   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡  ⚡   ⚡   ⚡  #
####################################
###   Transfer A Copy To Zion    ###
####################################
#   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡  ⚡   ⚡   ⚡  #

SCRIPT_ZION_UPLOAD=${DIR_TOOLBOX}/dicom_management/zion/Zion_Upload.exp
DIR_HPC=${DIR_PROJECT}/dicoms
DIR_ZION=/tmp/yassamri/Conte_Center/rjirsara/nda_upload
ZION_USERNAME=`whoami`

if [[ -f $SCRIPT_ZION_UPLOAD && ! -z $DIR_ZION && ! -z $ZION_PASSWORD ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "Uploading Processed Data To Zion "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	$SCRIPT_ZION_UPLOAD $DIR_HPC $DIR_ZION $ZION_USERNAME $ZION_PASSWORD
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
