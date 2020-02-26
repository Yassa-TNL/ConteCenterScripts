#!/bin/bash
###########

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/xcpengine
DIR_LOCAL_APPS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/apps
DIR_LOCAL_DATA=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/datasets
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
	mkdir -p ${DIR_LOCAL_SCRIPTS}/atlases/ ${DIR_LOCAL_SCRIPTS}/designs/
	git clone https://github.com/PennBBL/xcpEngine.git
	mv ./xcpEngine/atlas/* ${DIR_LOCAL_SCRIPTS}/atlases/
	mv ./xcpEngine/designs/* ${DIR_LOCAL_SCRIPTS}/designs/
	chmod -R 775 ${DIR_LOCAL_SCRIPTS}/
	rm -rf ./xcpEngine 
fi

###################################################################
### Submit XCPEngine Jobs For all Specified Tasks and Pipelines ###
###################################################################

SCRIPT_FUNC_XCPENGINE=${DIR_LOCAL_SCRIPTS}/pipeline_func_xcpengine.sh
DESIGN_FILES="fc-36p.dsn fc-36p_despike.dsn"
TEMPLATE_SPACE="MNI152NLin2009cAsym"
TASKS_LABELS="REST doors"

if [[ -f $SCRIPT_FUNC_XCPENGINE && ! -z $TASKS_LABELS  && ! -z $DESIGN_FILES && -d $DIR_LOCAL_APPS/fmriprep ]] ; then
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
	SUBJECTS=`ls ${DIR_LOCAL_APPS}/fmriprep/sub-*.html | rev | cut -d '/' -f1 | rev | sed s@'sub-'@@g | sed s@'.html'@@g`
	for SUBJECT in $SUBJECTS ; do
		for TASK in $TASKS_LABELS ; do
			JOBNAME=`echo ${TASK}${SUBJECT} | cut -c1-10`
			JOBSTATUS=`qstat -u $USER | grep "${JOBNAME}\b" | awk {'print $5'}`
			if [[ ! -z "$JOBSTATUS" ]] ; then 
				echo ""
				echo "################################################################"
				echo "#${SUBJECT} XCP-Func Job Was Previously Submitted: ${JOBSTATUS} "
				echo "################################################################"
			else
				echo ""
				echo "######################################################"
				echo "#Submitting XCPEngine Func Job For Subect: ${SUBJECT} "
				echo "######################################################"
				qsub -N $JOBNAME $SCRIPT_FUNC_XCPENGINE $DIR_LOCAL_SCRIPTS $DIR_LOCAL_APPS $TEMPLATE_SPACE $PIPELINES $SUBJECT $TASK
			fi
		done
	done
fi

####################################################################################
### Create QA Figures of Residual Correlations and Distance Dependance Artifacts ###
####################################################################################

SCRIPT_RESID_COR_FCON=$DIR_LOCAL_SCRIPTS/visualize_residcor_distdep.sh
ATLAS_LABEL="power264"

if [[ -f $SCRIPT_RESID_COR_FCON ]] ; then
	echo ""
	echo "############################################################################"
	echo "Creating Figures of Residual Correlations and Distance Dependance Artifacts "
	echo "############################################################################"
	qsub -hold_jid ${JOBNAME} -N QAFIGS $SCRIPT_RESID_COR_FCON $DIR_LOCAL_SCRIPTS $DIR_LOCAL_APPS $DIR_LOCAL_DATA ${ATLAS_LABEL}
fi

##############################################################################
### Create Histograms OF Degrees Of Freedom Lost and Prepare Brain Visuals ###
##############################################################################

SCRIPT_HIST_DOF_LOSS=$DIR_LOCAL_SCRIPTS/visualize_temporal_dof_loss.R

if [[ -f $SCRIPT_HIST_DOF_LOSS ]] ; then
	echo ""
	echo "############################################################################"
	echo "Creating Figures of Residual Correlations and Distance Dependance Artifacts "
	echo "############################################################################"
	qsub -hold_jid ${JOBNAME} -N QAFIGS $SCRIPT_HIST_DOF_LOSS $DIR_LOCAL_APPS $DIR_LOCAL_DATA
fi

###########################################################################
### Extract Signal From Each Atlas Across Each Subject-Level Timeseries ###
###########################################################################

SCRIPT_EXTRACT_SIGNAL=${DIR_LOCAL_SCRIPTS}/extract_timeseries_signal.sh

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
