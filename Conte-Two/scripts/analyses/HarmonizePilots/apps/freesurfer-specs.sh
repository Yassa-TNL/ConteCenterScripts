#!/bin/bash
###########

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/freesurfer
DIR_LOCAL_BIDS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/bids
DIR_LOCAL_APPS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/apps
DIR_LOCAL_DATA=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/datasets
mkdir -p $DIR_LOCAL_APPS $DIR_LOCAL_DATA

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

#########################################################
### If Missing Build the Freesurfer Singularity Image ###
#########################################################

SINGULARITY_CONTAINER=`echo $DIR_LOCAL_SCRIPTS/container_freesurfer.simg`
if [[ ! -f $SINGULARITY_CONTAINER && ! -z $DIR_LOCAL_SCRIPTS ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "`basename $SINGULARITY_CONTAINER` Not Found - Building New Container "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	singularity build ${SINGULARITY_CONTAINER} docker://bids/freesurfer
fi

#################################################################
### If Missing Build Freesurfer License Needed For Processing ###
#################################################################

FREESURFER_LICENSE=`echo $DIR_LOCAL_SCRIPTS/license_freesurfer.txt`
if [[ ! -f $FREESURFER_LICENSE && ! -z $DIR_LOCAL_FMRIPREP ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	echo "`basename $FREESURFER_LICENSE` Not Found - Register For One Here: "
	echo "       https://surfer.nmr.mgh.harvard.edu/registration.html       "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	printf "rjirsara@uci.edu
		40379 
		*CBT0GfF/00EU 
		FSP82KoWQu0tA \n" | grep -v local > $FREESURFER_LICENSE
fi

###############################################
### Submit FREESURFER Jobs For All Subjects ###
###############################################

SCRIPT_FREESURFER=${DIR_LOCAL_SCRIPTS}/pipeline_anatomical_freesurfer.sh
BYPASS_SINGULARITY_IMAGE=FALSE
OPT_REFINESURF_ACQ=FALSE

if [[ -f $SCRIPT_FREESURFER && ! -z $BYPASS_SINGULARITY_IMAGE && -d $DIR_LOCAL_BIDS ]] ; then
	for SUBJECT in `ls ${DIR_LOCAL_BIDS} | grep -v dataset | tr '\n' ' ' | grep 'sub' | sed s@'sub-'@''@g` ; do
		JOBNAME=`echo FS${SUBJECT} | cut -c1-10`
		JOBSTATUS=`qstat -u $USER | grep "${JOBNAME}\b" | awk {'print $5'}`
		OUTLOG1=`echo ${DIR_LOCAL_APPS}/freesurfer/sub-${SUBJECT}/scripts/recon-all-status.log`
		OUTLOG2=`echo ${DIR_LOCAL_APPS}/freesurfer/sub-${SUBJECT}_ses-*/scripts/recon-all-status.log | head -n1`
		if [[ -f $OUTLOG1 ]] ; then 
			OUTLOG=`cat $OUTLOG1 | grep 'finished without error' | sed s@' '@'_'@g`
		elif [[ -f `echo $OUTLOG2 | head -n1` ]] ; then 
			OUTLOG=`cat $OUTLOG2 | grep 'finished without error' | sed s@' '@'_'@g`
		fi
		if [ -z `find ${DIR_LOCAL_BIDS}/sub-${SUBJECT} | grep T1w.nii.gz | head -n1` ] ; then
			echo ""
			echo "##########################################################"
			echo "#${SUBJECT} Does Not Have T1w Structural Scans To Process "
			echo "##########################################################"
		elif [[ ! -z "$JOBSTATUS" ]] ; then 
			echo ""
			echo "##################################################################"
			echo "#${SUBJECT} FREESURFER Job Was Previously Submitted: ${JOBSTATUS} "
			echo "##################################################################"
		elif [[ ! -z $OUTLOG ]] ; then
			echo ""
			echo "#######################################"
			echo "#${SUBJECT} Was Processed Successfully "
			echo "#######################################"
		else
			echo ""
			echo "#################################################"
			echo "Submitting FREESURFER Job For Subect: ${SUBJECT} "
			echo "#################################################"
			qsub -N $JOBNAME $SCRIPT_FREESURFER $DIR_LOCAL_SCRIPTS $DIR_LOCAL_BIDS $DIR_LOCAL_APPS $BYPASS_SINGULARITY_IMAGE $SUBJECT $OPT_REFINESURF_ACQ
		fi
	done
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
