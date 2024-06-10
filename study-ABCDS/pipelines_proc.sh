#!/usr/bin/env bash
#singularity build freesurfer.simg docker://nipreps/freesurfer:7.1.1-infant-4a14499-rca2 
#singularity build freesurfer_v7.4.1.simg docker://bids/freesurfer:7.4.1-unstable 
#singularity build freesurfer_v7.simg docker://bids/freesurfer:7-unstable
#singularity build freesurfer_latest.simg docker://bids/freesurfer:latest #version 6
###################

DIR_PROJECT=/dfs9/yassalab/ABCDS
DIR_TOOLBOX=/dfs9/yassalab/rjirsara/ConteCenterScripts/ToolBox
FMRIPREP_CONTAINER=`echo $DIR_TOOLBOX/bids_apps/dependencies/fmriprep_v23.1.3.simg`
FREESURF_CONTAINER=`echo $DIR_TOOLBOX/bids_apps/dependencies/freesurfer_v7.4.1.simg`
FREESURFER_LICENSE=`echo $DIR_TOOLBOX/bids_apps/dependencies/freesurfer_license.txt`

#####
### Build Prerequest Files if Nessessary 
#####

#Containers
if [[ ! -f `echo $FMRIPREP_CONTAINER` ]] || [[ ! -f `echo $FREESURF_CONTAINER` ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	echo " SINGULARITY CONTAINERS NOT FOUND - BUILDING NOW "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
	singularity build ${FMRIPREP_CONTAINER} docker://nipreps/fmriprep:latest
	singularity build ${FREESURF_CONTAINER} docker://bids/freesurfer:7.4.1-unstable 
else
	SINGULARITY_CONTAINER=`ls -t $SINGULARITY_CONTAINER  | head -n1`
fi

#Licenses
if [[ ! -f $FREESURFER_LICENSE && ! -z $DIR_TOOLBOX ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	echo "`basename $FREESURFER_LICENSE` Not Found - Register For One Here: "
	echo "       https://surfer.nmr.mgh.harvard.edu/registration.html       "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	printf "rjirsara@uci.edu
		40379 
		*CBT0GfF/00EU 
		FSP82KoWQu0tA \n" | grep -v base forged > $FREESURFER_LICENSE
fi

#####
### Submit FREESURF Anatomical Jobs
#####

SCRIPT_FREESURFER=${DIR_TOOLBOX}/bids_apps/freesurfer/pipeline_preproc_freesurfer.sh
PROC_TYPE=LOCAL ; OPT_SUB_UNITS=TRUE ; OPT_EULER_NUMBER=TRUE 

if [[ -f $SCRIPT_FREESURFER && -d $DIR_PROJECT ]] ; then
	for SUBJECT in `ls ${DIR_PROJECT}/bids/ | grep 'sub-'` ; do
		SUB=`echo ${SUBJECT}  | sed s@'NDAR'@''@g | sed s@'INV'@@''g`
		JOBNAME=`echo ${SUB} | cut -c1-8`
		SCANS=`find ${DIR_PROJECT}/bids/sub-${SUBJECT} | grep T1w.nii`
		ASEGS=`echo ${DIR_PROJECT}/pipelines/freesurfer/${SUBJECT}/stats/aseg.stats`
		if [ ! -z `squeue -u $USER | grep "${JOBNAME}\b" | awk {'print $6'}` ] ; then
			echo ""
			echo "###### ⚡⚡⚡⚡ ######"
			echo "### Job Status for ${SUBJECT}:  `squeue -u $USER | grep ${JOBNAME} | awk {'print $6'}`"
		elif (( `echo $SCANS | wc -w` != `echo $ASEGS | wc -w` )) || [[ ! -f `echo $ASEGS | cut -d ' ' -f1` ]] ; then
			echo ""
			echo "###### ⚡⚡⚡⚡ ##### ⚡⚡⚡⚡ ###### ⚡⚡⚡⚡ ######"
			echo "Submitting FREESURF Job for ${SUBJECT}   "
			sbatch -A myassa_lab --job-name=$JOBNAME --partition=standard --nodes=1 --ntasks=4 --mem-per-cpu=6G \
				$SCRIPT_FREESURFER $DIR_TOOLBOX $DIR_PROJECT $SUBJECT $PROC_TYPE $OPT_SUB_UNITS $OPT_EULER_NUMBER
		fi
	done
fi

#####
### Submit FMRIPREP Preprocessing Jobs
#####

SCRIPT_FMRIPREP=${DIR_TOOLBOX}/bids_apps/fmriprep/pipeline_preproc_fmriprep.sh
TEMPLATE_SPACE=MNI152NLin6Asym  ; OPT_STOP_FIRST_ERROR=TRUE

if [[ -f $SCRIPT_FMRIPREP && -d $DIR_PROJECT ]] ; then
	for SUBJECT in `ls ${DIR_PROJECT}/bids/ | grep sub- | sed s@'sub-'@''@g` ; do
		JOBNAME=`echo ${SUBJECT} | cut -c1-8`
		SUBDIR=`echo ${DIR_PROJECT}/pipelines/fmriprep/sub-${SUBJECT}`
		SCANS=`echo ${DIR_PROJECT}/bids/sub-${SUBJECT}/func/*_bold.nii.gz`
		PREPROC=`echo $SUBDIR/func/sub-${SUBJECT}_task-*_space-${TEMPLATE_SPACE}_desc-preproc_bold.nii.gz`
		if [[ -f `echo $SCANS | cut -d ' ' -f1` ]] ; then
			if [ ! -z `squeue -u $USER | grep "${JOBNAME}\b" | awk {'print $6'}` ] ; then
				echo ""
				echo "###### ⚡⚡⚡⚡ ######"
				echo "### Job Status for ${SUBJECT}:  `squeue -u $USER | grep ${JOBNAME} | awk {'print $6'}`"
			elif (( `echo $SCANS | wc -w` != `echo $PREPROC | wc -w` )) || [[ ! -f `echo $PREPROC | cut -d ' ' -f1` ]] ; then
				echo ""
				echo "###### ⚡⚡⚡⚡ ##### ⚡⚡⚡⚡ ###### ⚡⚡⚡⚡ ######"
				echo "Submitting FMRIPREP Job for ${SUBJECT}   "
				sbatch -A myassa_lab --job-name=$JOBNAME --partition=standard --nodes=1 --ntasks=4 --mem-per-cpu=6G \
					$SCRIPT_FMRIPREP $DIR_TOOLBOX $DIR_PROJECT "${TEMPLATE_SPACE}" $SUBJECT $OPT_STOP_FIRST_ERROR
			fi
		fi
	done
fi

#####
### Submit XCP-FCON Processing Jobs
#####

SCRIPT_XCP_FCON=$DIR_TOOLBOX/bids_apps/xcp-fcon/pipeline_fcon_xcpengine.sh
DESIGN="fc-36p_scrub_sm0" ; TEMPLATE=MNI152NLin6Asym ; TASK="rest"

if [[ -f $SCRIPT_XCP_FCON && -d $DIR_PROJECT ]] ; then
	for SUBJECT in ` ls ${DIR_PROJECT}/pipelines/fmriprep | grep 'sub-' | cut -d '-' -f2 | cut -d '.' -f1 | uniq` ; do
		PIPE_LABEL=`echo $DESIGN | sed s@'fc-'@''@g`
		PREPROC=`find ${DIR_PROJECT}/pipelines/fmriprep/sub-${SUBJECT} | grep "task-${TASK}_space-${TEMPLATE}_desc-preproc_bold.nii.gz"`
		XCPPROC=`find ${DIR_PROJECT}/pipelines/xcpengine/pipe-${PIPE_LABEL}_task-${TASK} | grep "sub-${SUBJECT}_residualised.nii.gz"`
		JOBNAME=`echo ${SUBJECT} | cut -c1-8`
		echo $SUBJECT
		if [[ -f `echo $PREPROC | cut -d ' ' -f1` ]] ; then
			if [ ! -z `squeue -u $USER | grep "${JOBNAME}\b" | awk {'print $6'}` ] ; then
				echo ""
				echo "###### ⚡⚡⚡⚡ ######"
				echo "### Job Status for ${SUBJECT}:  `squeue -u $USER | grep ${JOBNAME} | awk {'print $6'}`"
			elif (( `echo $XCPPROC | wc -w` != `echo $PREPROC | wc -w` )) || [[ ! -f `echo $XCPPROC | cut -d ' ' -f1` ]] ; then
				echo ""
				echo "###### ⚡⚡⚡⚡ ##### ⚡⚡⚡⚡ ###### ⚡⚡⚡⚡ ######"
				echo "Submitting FMRIPREP Job for ${SUBJECT}   "
				sbatch -A myassa_lab --job-name=$JOBNAME --partition=standard --nodes=1 --ntasks=4 --mem-per-cpu=6G \
					$SCRIPT_XCP_FCON $DIR_TOOLBOX $DIR_PROJECT ${TEMPLATE} ${DESIGN} $SUBJECT $TASK
			fi
		fi
	done
fi

########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######