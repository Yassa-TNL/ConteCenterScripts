#!/bin/bash
#$ -N BIDsxONE 
#$ -q free*,yassalab
#$ -pe openmp 8
#$ -R y
#$ -ckpt restart
#########################################################
### Define Root Directories and Software Dependencies ###
#########################################################

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/dicom_management
DIR_LOCAL_AUDITS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits
DIR_LOCAL_DICOMS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/dicoms
DIR_LOCAL_BIDS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/bids
mkdir -p $DIR_LOCAL_DICOMS $DIR_LOCAL_BIDS

module purge ; module load anaconda/2.7-4.3.1 fsl/6.0.1
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

###############################################
### Brain Imaging Data Structure Conversion ###
###############################################

SCRIPT_DCM2BIDS=${DIR_LOCAL_SCRIPTS}/bids_conversion/Conversion_dcm2bids.sh
FILE_CONFIG=./config_bids.json
OPT_LONGITUDINAL=sub_beh_ses
OPT_RM_DICOMS=FALSE

if [[ -f $SCRIPT_DCM2BIDS && -f $FILE_CONFIG ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	echo "Coverting Data into BIDs Format - dcm2bids "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	${SCRIPT_DCM2BIDS} ${DIR_LOCAL_DICOMS} ${FILE_CONFIG} ${OPT_LONGITUDINAL} ${OPT_RM_DICOMS}
fi

########################################################
### Modify MetaData to Adhere to BIDS Specifications ###
########################################################

SCRIPT_EDIT_META=$DIR_LOCAL_SCRIPTS/bids_conversion/MetaData_Modification.py
OPT_MERGE_TASKxRUNS="RESTx2"
OPT_GEN_FMAP_FUNC=FALSE
OPT_GEN_FMAP_DWI=FALSE
OPT_ADD_DEFAULT_ST=TRUE

if [[ -f $SCRIPT_EDIT_META ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "Editing Meta Data to Adhere to BIDS Specifications "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	python $SCRIPT_EDIT_META $DIR_LOCAL_DICOMS $DIR_LOCAL_BIDS $OPT_MERGE_TASKxRUNS $OPT_GEN_FMAP_FUNC $OPT_GEN_FMAP_DWI $OPT_ADD_DEFAULT_ST
fi

#######################################
### Generate BIDS Validation Report ###
#######################################

SCRIPT_GEN_REPORT=$DIR_LOCAL_SCRIPTS/bids_conversion/Validation_Report.sh

if [[ -f $SCRIPT_GEN_REPORT ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	echo "Generating BIDs Validation Report to Assess Standardization "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	$SCRIPT_GEN_REPORT $DIR_LOCAL_BIDS $DIR_LOCAL_AUDITS
fi

#################################
### Upload Events To Flywheel ###
#################################

SCRIPT_FW_UPLOAD=$DIR_LOCAL_SCRIPTS/flywheel/Flywheel_Upload.sh
DIR_FLYWHEEL=yassalab/Conte-Two-UCI
DIRNAMExTYPE="DICOMSxdicom PARRECxparrec NIFTIxfolder"

if [[ -f $SCRIPT_FW_UPLOAD ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "Uploading Events To Subject-Level Directories In Flyweel "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	$SCRIPT_FW_UPLOAD $DIR_LOCAL_DICOMS/UCI $DIR_FLYWHEEL $DIRNAMExTYPE $FLYWHEEL_API_TOKEN
fi

########################################
### Uploading Processed Data To Zion ###
########################################

SCRIPT_ZION_UPLOAD=$DIR_LOCAL_SCRIPTS/zion/Zion_Upload.exp
DIR_HPC=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/bids
DIR_ZION=/tmp/yassamri/Conte_Center/Processed_Data/rjirara
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
