#!/bin/bash
###########

DIR_TOOLBOX=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

mkdir -p $DIR_PROJECT/apps/qsiprep $DIR_PROJECT/datasets
module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

######################################################
### If Missing Build the QSIPREP Singularity Image ###
######################################################

SINGULARITY_CONTAINER=`echo $DIR_TOOLBOX/bids_apps/qsiprep/container_qsiprep.simg`
if [[ ! -f $SINGULARITY_CONTAINER && ! -z $DIR_TOOLBOX ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "`basename $SINGULARITY_CONTAINER` Not Found - Building New Container "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	singularity build ${SINGULARITY_CONTAINER} docker://pennbbl/qsiprep:latest
fi

####################################################################
### If Missing Build Freesurfer License Needed For Preprocessing ###
####################################################################

FREESURFER_LICENSE=`echo $DIR_TOOLBOX/bids_apps/freesurfer/license_freesurfer.txt`
if [[ ! -f $FREESURFER_LICENSE && ! -z $DIR_TOOLBOX ]] ; then
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

#########################################################
### If Missing Build Clone Pipeline Files From GitHub ###
#########################################################

QSIPREP_DESIGNS=`echo $DIR_TOOLBOX/bids_apps/qsiprep/designs/*.json | cut -d ' ' -f1`
if [[ ! -f $QSIPREP_DESIGNS && ! -z $QSIPREP_DESIGNS ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "    Recon Design Files Not Found - Cloning the Default Ones From GitHub:   "
	echo "   https://github.com/PennBBL/qsiprep/tree/master/qsiprep/data/pipelines   "	
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	git clone https://github.com/PennBBL/qsiprep.git
	mv ./qsiprep/qsiprep/data/pipelines/* $DIR_TOOLBOX/bids_apps/qsiprep/designs
	chmod -R 775 $DIR_TOOLBOX/bids_apps/qsiprep/designs 
	rm -rf ./qsiprep
fi

#################################################
### Submit QSIPREP PreProc Jobs For Raw Scans ###
#################################################

SCRIPT_PREPROC_QSIPREP=${DIR_TOOLBOX}/bids_apps/qsiprep/pipeline_preproc_qsiprep.sh
OPT_STOP_FIRST_ERROR=FALSE

if [[ -f $SCRIPT_PREPROC_QSIPREP && -d $DIR_LOCAL_BIDS ]] ; then
	for SUBJECT in `ls ${DIR_LOCAL_BIDS} | grep 'sub' | sed s@'sub-'@''@g | head -n1`  ; do
		JOBNAME=`echo QP${SUBJECT} | cut -c1-10`
		JOBSTATUS=`qstat -u $USER | grep "${JOBNAME}\b" | awk {'print $5'}`
		OUTDIR=`echo $DIR_PROJECT/apps/qsiprep/sub-${SUBJECT}`
		WORKDIR=`echo $DIR_PROJECT/apps/qsiprep/workflows/qsiprep_wf/single_subject_${SUBJECT}_wf`
		if [ -z `find ${DIR_PROJECT}/bids/sub-${SUBJECT} | grep dwi.nii.gz | head -n1` ] ; then
			echo ""
			echo "#####################################################"
			echo "#${SUBJECT} Does Not Have Diffusion Scans To Process "
			echo "#####################################################"
		elif [[ ! -z "$JOBSTATUS" ]] ; then 
			echo ""
			echo "###################################################################"
			echo "#${SUBJECT} QSI-PreProc Job Was Previously Submitted: ${JOBSTATUS} "
			echo "###################################################################"
		elif [[ ! -d  $WORKDIR && -d $OUTDIR ]] ; then
			echo ""
			echo "###############################################################"
			echo "#${SUBJECT} Was Successfully Processed Through QSIPREP PreProc "
			echo "###############################################################"
		else
			echo ""
			echo "#######################################################"
			echo "#Submitting QSIPREP PreProc Job For Subect: ${SUBJECT} "
			echo "#######################################################"
			qsub -N $JOBNAME $SCRIPT_PREPROC_QSIPREP $DIR_TOOLBOX $DIR_PROJECT $SUBJECT $OPT_STOP_FIRST_ERROR
		fi
	done
fi

#########################################################
### Submit QSIPREP Recon Jobs For Preproccessed Scans ###
#########################################################
<<SKIP
SCRIPT_RECON_QSIPREP=${DIR_LOCAL_SCRIPTS}/pipeline_recon_qsiprep.sh
DESIGN_FILES="mrtrix_multishell_msmt_noACT.json"

if [[ -f $SCRIPT_RECON_QSIPREP && -d $DIR_LOCAL_APPS/qsiprep ]] ; then
	for PIPE in $DESIGN_FILES ; do
		if [ ! -f $DIR_LOCAL_SCRIPTS/designs/${PIPE} ] ; then
			echo ""
			echo "###################################################################"
			echo "Design File Not Found For Pipe: ${PIPE} -- Skipping Job Submission "
			echo "###################################################################"
			break
		fi
	done
	PIPELINES=`echo $DESIGN_FILES | tr ' ' '@'`
	for SUBJECT in `ls ${DIR_LOCAL_APPS}/qsiprep | grep 'sub' | sed s@'sub-'@''@g` ; do
		JOBNAME_RECON=`echo QR${SUBJECT} | cut -c1-10`
		JOBNAME_PREPROC=`echo QP${SUBJECT} | cut -c1-10`
		JOBSTATUS_RECON=`qstat -u $USER | grep "${JOBNAME_RECON}\b" | awk {'print $5'}`
		JOBSTATUS_PREPROC=`qstat -u $USER | grep "${JOBNAME_PREPROC}\b" | awk {'print $5'}`
		OUTDIR=`echo $DIR_LOCAL_APPS/qsirecon/sub-${SUBJECT}`
		WORKDIR=`echo $DIR_LOCAL_APPS/qsirecon/workflows/qsiprep_wf/single_subject_${SUBJECT}_wf`
		elif [[ ! -d  $WORKDIR && -d $OUTDIR ]] ; then
			echo ""
			echo "#############################################################"
			echo "#${SUBJECT} Was Successfully Processed Through QSIPREP Recon "
			echo "#############################################################"
		elif [[ ! -z "$JOBSTATUS_RECON" ]] ; then
			echo ""
			echo "###################################################################"
			echo "#${SUBJECT} Recon Job Was Previously Submitted: ${JOBSTATUS_RECON} "
			echo "###################################################################"
		elif [[ ! -z "$JOBSTATUS_PREPROC" ]] ; then
			echo ""
			echo "#################################################################"
			echo "#Submitting QSIPREP Recon Job Immediately For Subect: ${SUBJECT} "
			echo "#################################################################"
			qsub -N $JOBNAME_RECON $SCRIPT_RECON_QSIPREP $DIR_LOCAL_SCRIPTS $DIR_LOCAL_APPS $PIPELINES $SUBJECT

		else
			echo ""
			echo "##################################################################################"
			echo "#Submitting Recon Job After Preproc (${JOBSTATUS_PREPROC}) For Subect: ${SUBJECT} "
			echo "##################################################################################"
			qsub -hold_jid $JOBNAME_PREPROC -N $JOBNAME_RECON $SCRIPT_RECON_QSIPREP $DIR_LOCAL_SCRIPTS $DIR_LOCAL_APPS $PIPELINES $SUBJECT 



 "$OUTPUT_SPACES" $SUBJECT $OPT_ICA_AROMA $OPT_STOP_FIRST_ERROR
		fi
	done
fi
SKIP
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
