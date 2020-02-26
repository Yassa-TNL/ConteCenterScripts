#!/bin/bash
###########

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/fmriprep
DIR_LOCAL_APPS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/apps
DIR_LOCAL_BIDS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/bids
DIR_LOCAL_DATA=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/datasets
mkdir -p $DIR_LOCAL_APPS $DIR_LOCAL_DATA

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3 > /dev/null 2>&1 &
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

#######################################################
### If Missing Build the Fmriprep Singularity Image ###
#######################################################

SINGULARITY_CONTAINER=`echo $DIR_LOCAL_SCRIPTS/container_fmriprep.simg`
if [[ ! -f $SINGULARITY_CONTAINER && ! -z $DIR_LOCAL_SCRIPTS ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "`basename $SINGULARITY_CONTAINER` Not Found - Building New Container "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	singularity build ${SINGULARITY_CONTAINER} docker://poldracklab/fmriprep:latest
fi

####################################################################
### If Missing Build Freesurfer License Needed For Preprocessing ###
####################################################################

FREESURFER_LICENSE=`echo $DIR_LOCAL_SCRIPTS/license_freesurfer.txt`
if [[ ! -f $FREESURFER_LICENSE && ! -z $DIR_LOCAL_SCRIPTS ]] ; then
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

#############################################
### Submit FMRIPREP Jobs For New Subjects ###
#############################################

SCRIPT_FMRIPREP=${DIR_LOCAL_SCRIPTS}/pipeline_preproc_fmriprep.sh
OUTPUT_SPACES="MNI152NLin2009cAsym"
OPT_STOP_FIRST_ERROR=FALSE
OPT_ICA_AROMA=FALSE

if [[ -f $SCRIPT_FMRIPREP && ! -z $OUTPUT_SPACES && -d $DIR_LOCAL_BIDS ]] ; then
	for SUBJECT in `ls ${DIR_LOCAL_BIDS} | grep -v dataset | tr '\n' ' ' | sed s@'sub-'@''@g | grep -v 'local'` ; do
		JOBNAME=`echo FP${SUBJECT} | cut -c1-10`
		JOBSTATUS=`qstat -u $USER | grep "${JOBNAME}\b" | awk {'print $5'}`
		OUTDIR=`echo $DIR_LOCAL_APPS/fmriprep/sub-${SUBJECT}`
		WORKDIR=`echo $DIR_LOCAL_APPS/fmriprep/workflows/fmriprep_wf/single_subject_${SUBJECT}_wf/`
		if [ -z `find ${DIR_LOCAL_BIDS}/sub-${SUBJECT} | grep bold.nii.gz | head -n1` ] ; then
			echo ""
			echo "######################################################"
			echo "#${SUBJECT} Does Not Have Functional Scans To Process "
			echo "######################################################"
		elif [[ ! -z "$JOBSTATUS" ]] ; then 
			echo ""
			echo "################################################################"
			echo "#${SUBJECT} FMRIPREP Job Was Previously Submitted: ${JOBSTATUS} "
			echo "################################################################"
		elif [[ ! -d  $WORKDIR && -d $OUTDIR ]] ; then
			echo ""
			echo "#######################################"
			echo "#${SUBJECT} Was Processed Successfully "
			echo "#######################################"
		else
			echo ""
			echo "################################################"
			echo "#Submitting FMRIPREP Job For Subect: ${SUBJECT} "
			echo "################################################"
			qsub -N $JOBNAME $SCRIPT_FMRIPREP $DIR_LOCAL_SCRIPTS $DIR_LOCAL_BIDS $DIR_LOCAL_APPS "$OUTPUT_SPACES" $SUBJECT $OPT_ICA_AROMA $OPT_STOP_FIRST_ERROR
		fi
	done
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
