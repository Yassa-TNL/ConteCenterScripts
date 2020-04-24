#!/bin/bash
#$ -N BIDsxORE 
#$ -q free*,yassalab
#$ -pe openmp 8
#$ -R y
#$ -ckpt restart
#########################################################
### Define Root Directories and Software Dependencies ###
#########################################################

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/dicom_management
DIR_LOCAL_AUDITS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ORE/audits
DIR_LOCAL_DICOMS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ORE/dicoms
DIR_LOCAL_BIDS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ORE/bids
mkdir -p $DIR_LOCAL_DICOMS $DIR_LOCAL_BIDS

module purge ; module load anaconda/2.7-4.3.1 fsl/6.0.1
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

##############################
### Download From Flywheel ###
##############################

SCRIPT_FW_DOWNLOAD=${DIR_LOCAL_SCRIPTS}/flywheel/Flywheel_Download.sh
DIR_FLYWHEEL=yassalab/ORE
OPT_SUB_EXCLUDE="Pilot"

if [[ -f $SCRIPT_FW_DOWNLOAD && ! -z $DIR_FLYWHEEL && ! -z $FLYWHEEL_API_TOKEN ]] ; then 
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	echo "Downloading Data From Flywheel "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	${SCRIPT_FW_DOWNLOAD} ${DIR_FLYWHEEL} ${DIR_LOCAL_DICOMS} ${DIR_LOCAL_BIDS} ${FLYWHEEL_API_TOKEN} "${OPT_SUB_EXCLUDE}"
fi

###############################################
### Brain Imaging Data Structure Conversion ###
###############################################

SCRIPT_DCM2BIDS=${DIR_LOCAL_SCRIPTS}/bids_conversion/Conversion_dcm2bids.sh
FILE_CONFIG=./config_bids.json
OPT_LONGITUDINAL="1"
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
OPT_MERGE_TASKxRUNS=FALSE
OPT_GEN_FMAP_FUNC=TRUE
OPT_GEN_FMAP_DWI=TRUE
OPT_ADD_DEFAULT_ST=FALSE

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

########################################
### Uploading Processed Data To Zion ###
########################################

SCRIPT_ZION_UPLOAD=$DIR_LOCAL_SCRIPTS/zion/Zion_Upload.exp
DIR_HPC=/dfs2/yassalab/rjirsara/ConteCenterScripts/ORE/bids
DIR_ZION=/tmp/yassamri2/ORE/ProcessedData/rjirsara
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
