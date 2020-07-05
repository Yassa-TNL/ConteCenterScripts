#!/bin/bash
###########

DIR_TOOLBOX=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3 fsl/6.0.1
mkdir -p $DIR_PROJECT/apps/xcp-feat $DIR_PROJECT/datasets
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

########################################################
### If Missing Build the XCPEngine Singularity Image ###
########################################################

SINGULARITY_CONTAINER=`echo $DIR_TOOLBOX/bids_apps/dependencies/xcpengine_v*.simg`
if [[ ! -f `echo $SINGULARITY_CONTAINER | cut -d ' ' -f1` && ! -z $DIR_TOOLBOX ]] ; then
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

XCPENGINE_DESIGNS=`echo $DIR_TOOLBOX/bids_apps/dependencies/designs_xcp/task.dsn`
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

#####################################################
### Submit XCP-FEAT Jobs For All Level-1 Analyses ###
#####################################################

SCRIPT_XCP_FEAT=$DIR_TOOLBOX/bids_apps/xcp-feat/pipeline_feat_xcpengine.sh
DESIGN_CONFIG=$DIR_TOOLBOX/bids_apps/dependencies/designs_fsf/lvl-1_evs-2.fsf
TEMPLATE_SPACE=$DIR_TOOLBOX/bids_apps/dependencies/atlases/tpl-MNI152NLin6Asym_res-02_desc-brain_mask.nii.gz
DENOISE_PIPELINE="fc-aroma.dsn"
CONTRAST_HEADER="emotion"
TASK_LABEL="AMG"
OPT_THRESH_TYPE="cluster"
OPT_THRESH_MASK=""

if [[ -f $SCRIPT_XCP_FEAT && ! -z $TASK_LABEL && ! -z $DENOISE_PIPELINE && -f $DESIGN_CONFIG && -d $DIR_PROJECT/apps/fmriprep ]] ; then
	for PIPE in $DENOISE_PIPELINE ; do
		if [ ! -f $DIR_TOOLBOX/bids_apps/dependencies/designs_xcp/${PIPE} ] ; then
			echo ""
			echo "###################################################################"
			echo "Design File Not Found For Pipe: ${PIPE} -- Skipping Job Submission "
			echo "###################################################################"
			break
		elif [[ $PIPE != *36p.* && $PIPE != *24p.* && $PIPE != *acompcor* && $PIPE != *tcompcor.* && $PIPE != *aroma.* ]] ; then
			echo ""
			echo "###################################################################"
			echo "Cannot Run FSL Feat using Pipe: ${PIPE} -- Skipping Job Submission "
			echo "###################################################################"
			break
		fi
	done
	if [[ ! -f $TEMPLATE_SPACE && $TEMPLATE_LABEL != 'fsnative' && $TEMPLATE_LABEL != 'anat' ]] ; then
		TEMPLATE_LABEL=$(basename $TEMPLATE_SPACE | cut -d '_' -f1 | cut -d '-' -f2)
		mkdir -p $DIR_TOOLBOX/bids_apps/dependencies/atlases
		python -m pip install templateflow
		python -c "from templateflow import api; api.get('${TEMPLATE_LABEL}')"
		cp -r $HOME/.cache/templateflow/tpl-${TEMPLATE_LABEL}/*.nii.gz $DIR_TOOLBOX/bids_apps/dependencies/atlases
		DIM1=$(fslinfo `find ${DIR_PROJECT}/apps/fmriprep | grep ${TASK_LABEL} | head -n1` | grep ^dim1  | awk '{print $2}')
		DIM2=$(fslinfo `find ${DIR_PROJECT}/apps/fmriprep | grep ${TASK_LABEL} | head -n1` | grep ^dim2  | awk '{print $2}')
		DIM3=$(fslinfo `find ${DIR_PROJECT}/apps/fmriprep | grep ${TASK_LABEL} | head -n1` | grep ^dim3  | awk '{print $2}')
		module load mrtrix/3.0_RC3
		for NIFTI in `ls $DIR_TOOLBOX/bids_apps/dependencies/atlases/tpl-${TEMPLATE_LABEL}*T1w.nii.gz` ; do
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
	for SUBJECT in `find ${DIR_PROJECT}/apps/fmriprep -iname *${TASK_LABEL}*tsv | rev | cut -d '/' -f1 | rev | cut -d '_' -f1 | sed s@sub-@@g | uniq` ; do
		PIPE_LABEL=`echo $DENOISE_PIPELINE | sed s@.dsn@@g | sed s@fc-@@g`
		JOBNAME=`echo ${TASK_LABEL}${SUBJECT} | cut -c1-10`
		JOBSTATUS=`qstat -u $USER | grep "${JOBNAME}\b" | awk {'print $5'}`
		if [[ ! -z "$JOBSTATUS" ]] ; then 
			echo ""
			echo "#######################################################"
			echo "#${JOBNAME} Is Currently Being Processed: ${JOBSTATUS} "
			echo "#######################################################"
		elif [[ -d $DIR_PROJECT/apps/xcp-feat/pipe-${PIPE_LABEL}X${OPT_THRESH_TYPE}_task-${TASK_LABEL}_${CONTRAST_HEADER}/sub-${SUBJECT} ]] ; then
			echo ""
			echo "#######################################"
			echo "#${SUBJECT} Was Processed Successfully "
			echo "#######################################"
		else
			echo ""
			echo "########################################################"
			echo "Submitting XCPEngine Job ${JOBNAME} For Post-Processing "
			echo "########################################################"
			qsub -N $JOBNAME $SCRIPT_XCP_FEAT $DIR_TOOLBOX $DIR_PROJECT $DESIGN_CONFIG $TEMPLATE_SPACE "${DENOISE_PIPELINE}" "${CONTRAST_HEADER}" $TASK_LABEL $SUBJECT $OPT_THRESH_TYPE $OPT_THRESH_MASK
		fi
	done
fi

##########################################################
### Submit XCP-FEAT Job For All Level-3 Group Analyses ###
##########################################################

SCRIPT_XCP_FEAT=$DIR_TOOLBOX/bids_apps/xcp-feat/pipeline_feat_xcpengine.sh
DESIGN_CONFIG=$DIR_TOOLBOX/bids_apps/dependencies/designs_fsf/lvl-1_evs-2.fsf
TEMPLATE_SPACE=$DIR_TOOLBOX/bids_apps/dependencies/atlases/tpl-MNI152NLin6Asym_res-02_desc-brain_mask.nii.gz
DENOISE_PIPELINE="fc-aroma.dsn"
CONTRAST_HEADER="emotion"
TASK_LABEL="AMG"
OPT_THRESH_TYPE="cluster"
OPT_THRESH_MASK=""





###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
