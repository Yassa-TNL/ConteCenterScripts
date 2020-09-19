#!/bin/bash
#$ -N BIDsxTwo 
#$ -q free*,yassalab
#$ -pe openmp 8
#$ -R y
#$ -ckpt restart
#########################################################
### Define Root Directories and Software Dependencies ###
#########################################################

DIR_TOOLBOX=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two

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
OPT_SUB_EXCLUDE="NIFTI gephys conte_success_20191122"

if [[ -f $SCRIPT_FW_DOWNLOAD && ! -z $DIR_FLYWHEEL && ! -z $FLYWHEEL_API_TOKEN ]] ; then 
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	echo "Downloading Data From Flywheel "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	$SCRIPT_FW_DOWNLOAD $DIR_FLYWHEEL $DIR_PROJECT/dicoms/UCI $FLYWHEEL_API_TOKEN $OPT_SUB_EXCLUDE
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

SCRIPT_EDIT_META=$DIR_LOCAL_SCRIPTS/bids_conversion/MetaData_Modification.py
OPT_MERGE_TASKxRUNS="doorsx3"
OPT_GEN_FMAP_FUNC=TRUE
OPT_GEN_FMAP_DWI=TRUE
OPT_ADD_DEFAULT_ST=FALSE

if [[ -f $SCRIPT_EDIT_META ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "Editing Meta Data to Adhere to BIDS Specifications "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	python $SCRIPT_EDIT_META $DIR_LOCAL_DICOMS/UCI $DIR_LOCAL_BIDS $OPT_MERGE_TASKxRUNS $OPT_GEN_FMAP_FUNC $OPT_GEN_FMAP_DWI $OPT_ADD_DEFAULT_ST
fi

#############################################
### Generate BIDS Validation & NDA Report ###
#############################################

SCRIPT_GEN_REPORT=$DIR_LOCAL_SCRIPTS/bids_conversion/Validation_Report.sh
OPT_NDA_UPLOAD_REPORT=TRUE

if [[ -f $SCRIPT_GEN_REPORT ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	echo "Generating BIDs Validation Report to Assess Standardization "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	$SCRIPT_GEN_REPORT $DIR_LOCAL_BIDS $DIR_LOCAL_AUDITS $OPT_NDA_UPLOAD_REPORT
fi

#################################
### Upload Events To Flywheel ###
#################################

SCRIPT_FW_UPLOAD=$DIR_LOCAL_SCRIPTS/flywheel/Flywheel_Upload.sh
DIR_FLYWHEEL=yassalab/Conte-Two-UCI
DIRNAMExTYPE="Eventsxfolder"

if [[ -f $SCRIPT_FW_UPLOAD ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "Uploading Events To Subject-Level Directories In Flyweel "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	$SCRIPT_FW_UPLOAD $DIR_LOCAL_DICOMS/UCI $DIR_FLYWHEEL $DIRNAMExTYPE $FLYWHEEL_API_TOKEN
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
