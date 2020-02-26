#!/bin/bash
###########

DIR_LOCAL_SCRIPTS=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/xcpengine
DIR_LOCAL_BIDS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-Two/analyses/HarmonizePilots/bids
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

XCPENGINE_DESIGNS=`echo $DIR_LOCAL_SCRIPTS/designs/anat_* | cut -d ' ' -f1`
if [[ ! -f $XCPENGINE_DESIGNS && ! -z $DIR_LOCAL_XCPENGINE ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo " Functional Design Files Not Found - Cloning the Default Ones From GitHub: "
	echo "         https://github.com/PennBBL/xcpEngine/tree/master/designs          "	
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	mkdir -p ${DIR_LOCAL_SCRIPTS}/atlas ${DIR_LOCAL_SCRIPTS}/designs
	git clone https://github.com/PennBBL/xcpEngine.git
	mv ./xcpEngine/atlas/* ${DIR_LOCAL_SCRIPTS}/atlas
	mv ./xcpEngine/designs/* ${DIR_LOCAL_SCRIPTS}/designs
	chmod -R 775 ${DIR_LOCAL_SCRIPTS}/
	rm -rf ./xcpEngine 
fi

###################################################################
### Submit XCPEngine Jobs For all Specified Tasks and Pipelines ###
###################################################################

SCRIPT_ANAT_XCPENGINE=${DIR_LOCAL_SCRIPTS}/pipeline_anat_xcpengine.sh
DESIGN_FILES="anat-antsct.dsn"

if [[ -f $SCRIPT_ANAT_XCPENGINE  && ! -z $DESIGN_FILES && -d $DIR_LOCAL_BIDS ]] ; then
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
	for SUBJECT in `ls ${DIR_LOCAL_BIDS} | grep 'sub' | sed s@'sub-'@''@g` ; do
		JOBNAME=`echo ANAT${SUBJECT} | cut -c1-10`
		JOBSTATUS=`qstat -u $USER | grep "${JOBNAME}\b" | awk {'print $5'}`
		if [ -z `find ${DIR_LOCAL_BIDS}/sub-${SUBJECT} | grep dwi.nii.gz | head -n1` ] ; then
			echo ""
			echo "##########################################################"
			echo "#${SUBJECT} Does Not Have Anatomical T1w Scans To Process "
			echo "##########################################################"
		elif [[ ! -z "$JOBSTATUS" ]] ; then 
			echo ""
			echo "################################################################"
			echo "#${SUBJECT} XCP-Anat Job Was Previously Submitted: ${JOBSTATUS} "
			echo "################################################################"
		else
			echo ""
			echo "######################################################"
			echo "#Submitting XCPEngine Anat Job For Subect: ${SUBJECT} "
			echo "######################################################"
			qsub -N $JOBNAME $SCRIPT_ANAT_XCPENGINE $DIR_LOCAL_SCRIPTS $DIR_LOCAL_BIDS $DIR_LOCAL_APPS $PIPELINES $SUBJECT
		fi
	done
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
