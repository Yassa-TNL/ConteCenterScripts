#!/bin/bash
###########

DIR_TOOLBOX=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

mkdir -p $DIR_PROJECT/apps/xcp-fcon $DIR_PROJECT/datasets
module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3 fsl/6.0.1
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

########################################################
### If Missing Build the XCPEngine Singularity Image ###
########################################################

SINGULARITY_CONTAINER=`echo $DIR_TOOLBOX/bids_apps/dependencies/xcpengine_v*.simg`
if [[ ! -f $SINGULARITY_CONTAINER && ! -z $DIR_TOOLBOX ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "`basename $SINGULARITY_CONTAINER` Not Found - Building New Container "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	singularity build ${SINGULARITY_CONTAINER} docker://pennbbl/xcpengine:latest
else
	SINGULARITY_CONTAINER=`ls -t $SINGULARITY_CONTAINER  | head -n1`
fi

#################################################################
### If Missing Build Clone XCPEngine Design Files From GitHub ###
#################################################################

XCPENGINE_DESIGNS=`echo $DIR_TOOLBOX/bids_apps/dependencies/designs_xcp/fc-*.dsn | tr ' ' '\n' |head -n1`
if [[ ! -f $XCPENGINE_DESIGNS && ! -z $DIR_TOOLBOX ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo " Task Design Files Not Found - Cloning the Default Ones From GitHub: "
	echo "         https://github.com/PennBBL/xcpEngine/tree/master/designs    "	
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	git clone https://github.com/PennBBL/xcpEngine.git ; mkdir -p $(dirname $XCPENGINE_DESIGNS)
	mv ./xcpEngine/designs/* $DIR_TOOLBOX/bids_apps/dependencies/designs_xcp
	chmod -R 775 $DIR_TOOLBOX/bids_apps/dependencies ; rm -rf ./xcpEngine 
fi

###################################################################
### Submit XCPEngine Jobs For all Specified Tasks and Pipelines ###
###################################################################

SCRIPT_XCP_FCON=$DIR_TOOLBOX/bids_apps/xcp-fcon/pipeline_fcon_xcpengine.sh
TEMPLATE_SPACE=$DIR_TOOLBOX/bids_apps/atlases/tpl-MNI152NLin6Asym_res-02_desc-brain_T1w.nii.gz
DESIGN_FILES="fc-aroma.dsn"
TASK_LABELS="AMG REST"

if [[ -f $SCRIPT_XCP_FCON && ! -z $TASK_LABELS && -d $DIR_PROJECT/apps/fmriprep ]] ; then
	for PIPE in $DESIGN_FILES ; do
		if [ ! -f $DIR_TOOLBOX/bids_apps/dependencies/designs_xcp/${PIPE} ] ; then
			echo ""
			echo "###################################################################"
			echo "Design File Not Found For Pipe: ${PIPE} -- Skipping Job Submission "
			echo "###################################################################"
			break
		fi
	done
	if [[ ! -f $TEMPLATE_SPACE && $TEMPLATE_LABEL != 'fsnative' && $TEMPLATE_LABEL != 'anat' ]] ; then
		TEMPLATE_LABEL=$(basename $TEMPLATE_SPACE | cut -d '_' -f1 | cut -d '-' -f2)
		mkdir -p $DIR_TOOLBOX/bids_apps/atlases
		python -m pip install templateflow
		python -c "from templateflow import api; api.get('${TEMPLATE_LABEL}')"
		cp -r $HOME/.cache/templateflow/tpl-${TEMPLATE_LABEL}/*T1w.nii.gz $DIR_TOOLBOX/bids_apps/atlases
		DIM1=$(fslinfo `find ${DIR_PROJECT}/apps/fmriprep | grep space-${TEMPLATE_LABEL}_desc-preproc_bold.nii.gz | head -n1` | grep ^dim1  | awk '{print $2}')
		DIM2=$(fslinfo `find ${DIR_PROJECT}/apps/fmriprep | grep space-${TEMPLATE_LABEL}_desc-preproc_bold.nii.gz | head -n1` | grep ^dim2  | awk '{print $2}')
		DIM3=$(fslinfo `find ${DIR_PROJECT}/apps/fmriprep | grep space-${TEMPLATE_LABEL}_desc-preproc_bold.nii.gz | head -n1` | grep ^dim3  | awk '{print $2}')
		module load mrtrix/3.0_RC3
		for NIFTI in `ls $DIR_TOOLBOX/bids_apps/atlases/tpl-${TEMPLATE_LABEL}*T1w.nii.gz` ; do
			mrresize -size ${DIM1},${DIM2},${DIM3} ${NIFTI} ${NIFTI} -force
		done
		if [[ ! -f $TEMPLATE_SPACE ]] ; then
			echo ""
			echo "###################################################################"
			echo "Template Not Found in TemplateFlow Repo -- Skipping Job Submission "
			echo "###################################################################"
			break
		fi
	fi
	PIPE_LABELS=`echo $DESIGN_FILES | tr ' ' '@'`
	for TASK_LABEL in $TASK_LABELS ; do
		for SUBJECT in `find ${DIR_PROJECT}/apps/fmriprep -iname *${TASK_LABEL}*tsv | rev | cut -d '/' -f1 | rev | cut -d '_' -f1 | sed s@sub-@@g | uniq` ; do		
			JOBNAME=`echo ${TASK_LABEL}${SUBJECT} | cut -c1-10`
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
				qsub -N $JOBNAME $SCRIPT_XCP_FCON $DIR_TOOLBOX $DIR_PROJECT $TEMPLATE_SPACE "${PIPE_LABELS}" $SUBJECT $TASK_LABEL
			fi
		done
	done
fi

####################################################################################
### Create QA Figures of Residual Correlations and Distance Dependance Artifacts ###
####################################################################################

SCRIPT_CONFOUNDS=$DIR_TOOLBOX/bids_apps/xcp-rest/visualize_confounds2_mod.sh
ATLAS_LABEL="power264"

if [[ -f $SCRIPT_CONFOUNDS || -z $ATLAS_LABEL ]] ; then
	echo ""
	echo "#########################################################################"
	echo "Curating QA Data and Generating Figures Primarily From Confounds2 Module "
	echo "#########################################################################"
	qsub -hold_jid ${JOBNAME} -N QAFIGS $SCRIPT_RESID_COR_FCON $DIR_LOCAL_SCRIPTS $DIR_LOCAL_APPS $DIR_LOCAL_DATA ${ATLAS_LABEL}
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
