#!/bin/bash
###########

DIR_TOOLBOX=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

mkdir -p $DIR_PROJECT/apps/xcp-anat $DIR_PROJECT/datasets
module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

########################################################
### If Missing Build the XCPEngine Singularity Image ###
########################################################

SINGULARITY_CONTAINER=`echo $DIR_TOOLBOX/bids_apps/xcp-anat/container_xcpengine.simg`
if [[ ! -f $SINGULARITY_CONTAINER && ! -z $DIR_TOOLBOX ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "`basename $SINGULARITY_CONTAINER` Not Found - Building New Container "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	singularity build ${SINGULARITY_CONTAINER} docker://pennbbl/xcpengine:latest
fi

#################################################################
### If Missing Build Clone XCPEngine Design Files From GitHub ###
#################################################################

XCPENGINE_DESIGNS=`ls $DIR_TOOLBOX/bids_apps/xcp-anat/designs/* | head -n1`
if [[ ! -f $XCPENGINE_DESIGNS && ! -z $DIR_TOOLBOX ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo " Functional Design Files Not Found - Cloning the Default Ones From GitHub: "
	echo "         https://github.com/PennBBL/xcpEngine/tree/master/designs          "	
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	git clone https://github.com/PennBBL/xcpEngine.git
	mv ./xcpEngine/designs $DIR_TOOLBOX/bids_apps/xcp-anat
	chmod -R 775 $DIR_TOOLBOX/bids_apps/xcp-anat ; rm -rf ./xcpEngine 
fi

###################################################################
### NEED TO REVISE SPECIFICALLY FOR STRUC PIPELINE ###
###################################################################

SCRIPT_XCPENGINE=${DIR_LOCAL_SCRIPTS}/xcpengine_postproc_pipeline.sh
DESIGN_FILES="fc-aroma.dsn"
TEMPLATE_SPACE="MNI152NLin2009cAsym"
TASKS_LABELS="REST"

if [[ -f $SCRIPT_XCPENGINE && ! -z $TASKS_LABELS  && ! -z $DESIGN_FILES && -d $DIR_LOCAL_APPS/fmriprep ]] ; then
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
				echo "#######################################################"
				echo "#${JOBNAME} Is Currently Being Processed: ${JOBSTATUS} "
				echo "#######################################################"
			else
				echo ""
				echo "########################################################"
				echo "Submitting XCPEngine Job ${JOBNAME} For Post-Processing "
				echo "########################################################"
				qsub -N $JOBNAME $SCRIPT_XCPENGINE $DIR_LOCAL_SCRIPTS $DIR_LOCAL_APPS $TEMPLATE_SPACE $PIPELINES $SUBJECT $TASK
			fi
		done
	done
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
