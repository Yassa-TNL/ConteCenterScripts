#!/bin/bash
#$ -N PREPxADRC 
#$ -q free*,yassalab
#$ -pe openmp 4
#$ -R y
#$ -ckpt restart
#########################################################
### Define Root Directories and Software Dependencies ###
#########################################################

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/xcpengine
DIR_LOCAL_APPS=/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/apps
DIR_LOCAL_DATA=/dfs2/yassalab/rjirsara/ConteCenterScripts/NinetyPlus/datasets
mkdir -p $DIR_LOCAL_APPS $DIR_LOCAL_DATA

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

########################################################
### If Missing Build the XCPEngine Singularity Image ###
########################################################

SINGULARITY_CONTAINER=`echo $DIR_LOCAL_SCRIPTS/container_xcpengine.simg`
if [[ ! -f $SINGULARITY_CONTAINER && ! -z $DIR_LOCAL_SCRIPTS ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "`basename $SINGULARITY_CONTAINER` Not Found - Building New Container "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	singularity build ${SINGULARITY_CONTAINER} docker://pennbbl/xcpengine:latest
fi

#################################################################
### If Missing Build Clone XCPEngine Design Files From GitHub ###
#################################################################

XCPENGINE_DESIGNS=`echo $DIR_LOCAL_SCRIPTS/designs/fc_* | cut -d ' ' -f1`
if [[ ! -f $XCPENGINE_DESIGNS && ! -z $DIR_LOCAL_XCPENGINE ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo " Functional Design Files Not Found - Cloning the Default Ones From GitHub: "
	echo "         https://github.com/PennBBL/xcpEngine/tree/master/designs          "	
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	git clone https://github.com/PennBBL/xcpEngine.git
	mv ./xcpEngine/atlas ${DIR_LOCAL_SCRIPTS}/parcellations
	mv ./xcpEngine/designs ${DIR_LOCAL_SCRIPTS}/
	chmod -R 775 ${DIR_LOCAL_SCRIPTS}
	rm -rf ./xcpEngine 
fi

###################################################################
### Submit XCPEngine Jobs For all Specified Tasks and Pipelines ###
###################################################################

SCRIPT_XCPENGINE=$DIR_LOCAL_SCRIPTS/xcpengine_postproc_pipeline.sh
DESIGN_FILES="fc-36p.dsn fc-36p_despike.dsn fc-36p_25scrub.dsn fc-36p_50scrub.dsn fc-acompcor.dsn fc-aroma.dsn fc-aroma_gsr.dsn"
TASKS_LABELS='rest'
TEMPLATE_SPACE="MNI152NLin6Asym"

if [[ -f $SCRIPT_XCPENGINE && ! -z $TASKS_LABELS  && ! -z $DESIGN_FILES && -d $DIR_LOCAL_APPS ]] ; then
	for TASK in $TASKS_LABELS ; do
		SCANS=`find $DIR_LOCAL_APPS/fmriprep | grep -v problematic | grep task-${TASK}_space-${SPACE_LABEL}_desc-preproc_bold.nii.gz`
		if (( 1 > `echo $SCANS | wc -l` )) ; then
			echo ""
			echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  # "
			echo "Subjects Not Found For Task: ${TASK} Space: ${TEMPLATE_SPACE} -- Skipping Job Submission "
			echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  # "
			break
		fi
		for PIPE in $DESIGN_FILES ; do
			if [ ! -f $DIR_LOCAL_SCRIPTS/designs/${PIPE} ] ; then
				echo ""
				echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
				echo "Design File Not Found For Pipe: ${PIPE} -- Skipping Job Submission "
				echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡"
				break
			fi
			JOBNAME=`echo ${TASK}${PIPE} | sed s@"fc-"@""@ | sed s@".dsn"@""@ | sed s@"p_"@""@g  | cut -c1-10`
			JOBSTATUS=`qstat -u $USER | grep "${JOBNAME}\b" | awk {'print $5'}`
			if [ ! -z "$JOBSTATUS" ] ; then 
				echo ""
				echo "#######################################################"
				echo "#${JOBNAME} Is Currently Being Processed: ${JOBSTATUS} "
				echo "#######################################################"
			else
				echo ""
				echo "#######################################################################"
				echo "Submitting XCPEngine Job For ${TASK} Task Through The ${PIPE} Pipeline "
				echo "#######################################################################"
				qsub -N $JOBNAME $SCRIPT_XCPENGINE $DIR_LOCAL_SCRIPTS $DIR_LOCAL_APPS $TEMPLATE_SPACE $TASK $PIPE 
			fi
		done
	done
fi

##########################################################################################
### Create QA Figure of Correlation Between Residual Signal and Framewsie Displacement ###
##########################################################################################

SCRIPT_RESID_COR_FCON=$DIR_LOCAL_SCRIPTS/evalqc/resid_cor_fcon.sh
ATLAS_LABELS="power264"

if [[ -f $SCRIPT_RESID_COR_FCON ]] ; then
	echo ""
	echo "#######################################################"
	echo "Creating Residual Correlations with Head-Motion Figure "
	echo "#######################################################"
	qsub -hold_jid ${JOBNAME} -N EXTRACTSIG $SCRIPT_RESID_COR_FCON $DIR_LOCAL_SCRIPTS $DIR_LOCAL_APPS $DIR_LOCAL_DATA "${ATLAS_LABEL}"
fi



###########################################################################
### Extract Signal From Each Atlas Across Each Subject-Level Timeseries ###
###########################################################################

SCRIPT_EXTRACT_SIGNAL=${DIR_LOCAL_SCRIPTS}/extract/xcpengine_signal_extract.sh

if [[ -f $SCRIPT_EXTRACT_SIGNAL ]] ; then
	echo ""
	echo "#####################################################"
	echo "Extracting Signal Across The Timeseries Of Each Scan "
	echo "#####################################################"
	qsub -hold_jid ${JOBNAME} -N EXTRACTSIG $SCRIPT_EXTRACT_SIGNAL $DIR_LOCAL_SCRIPTS $DIR_LOCAL_APPS 
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
