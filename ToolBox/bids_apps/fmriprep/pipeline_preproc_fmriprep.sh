#!/bin/bash
#$ -q yassalab,free*,pub*
#$ -pe openmp 8-16
#$ -R y
#$ -ckpt restart
################

module load singularity/3.0.0 fsl/6.0.1 2>/dev/null 

DIR_TOOLBOX=$1
DIR_PROJECT=$2
TEMPLATE_SPACES="${3}"
SUBJECT=$4
OPT_ICA_AROMA=$5
OPT_STOP_FIRST_ERROR=$6

#########################################################################################
### Include Project-Specific Parameters Depending On BIDs Structure & Input Arguments ###
#########################################################################################

if [[ $OPT_ICA_AROMA == TRUE ]] ; then
	ICA=`echo --use-aroma`
	TEMPLATE_SPACES=$(echo "${TEMPLATE_SPACES}#MNI152NLin6Asym" | tr '#' '\n' | sort | uniq)
fi

if [[ $OPT_STOP_FIRST_ERROR == TRUE ]] ; then
	STOP=`echo --stop-on-first-crash`
fi

if [[ `find $DIR_PROJECT/bids -type d -printf '%f\n' | grep ses | sort | uniq | wc -l` > 2 ]] ; then
	LONGITUDINAL=`echo --longitudinal`
fi

if [[ ! -f `find $DIR_PROJECT/bids -name *epi.nii.gz` ]] ; then
	SYN_CORRECTION=`echo --use-syn-sdc`
fi 

###############################################
### Define Log Files and Output Directories ###
###############################################

rm FP${SUBJECT}.*
TODAY=`date "+%Y%m%d"`
TEMPLATE_SPACES=$(echo $TEMPLATE_SPACES | sed s@'#'@' '@g)
SINGULARITY_CONTAINER=$(ls -t $DIR_TOOLBOX/bids_apps/dependencies/fmriprep_v*.simg | head -n1)
VERSION=$(singularity run --cleanenv $SINGULARITY_CONTAINER --version | cut -d ' ' -f2)
COMMAND_FILE=`echo $DIR_PROJECT/apps/fmriprep/logs/${TODAY}/${SUBJECT}_Command_${VERSION}.sh`
LOG_FILE=`echo $DIR_PROJECT/apps/fmriprep/logs/${TODAY}/${SUBJECT}_Log_${VERSION}.txt`
DIR_WORKFLOW=$DIR_PROJECT/apps/fmriprep/workflows
mkdir -p `dirname ${LOG_FILE}` ${DIR_WORKFLOW}

#########################################################################
### Execute FMRIPREP Using Singularity Container For A Single Subject ###
#########################################################################

echo "singularity run --cleanenv $SINGULARITY_CONTAINER \
	$DIR_PROJECT/bids \
	$DIR_PROJECT/apps \
	participant --participant_label $SUBJECT \
	--work-dir $DIR_WORKFLOW \
	--fs-license-file $DIR_TOOLBOX/bids_apps/dependencies/freesurfer_license.txt \
	--output-spaces "${TEMPLATE_SPACES}" \
	--skip-bids-validation \
	--bold2t1w-dof 6 \
	--fs-no-reconall \
	--n_cpus 16 \
	--low-mem" ${ICA} ${STOP} ${LONGITUDINAL} ${SYN_CORRECTION} | tr '\t' '#' | sed s@'#'@''@g  > ${COMMAND_FILE}

chmod ug+wrx ${COMMAND_FILE}

${COMMAND_FILE} > ${LOG_FILE} 2>&1

############################################################################
### Quality of Life Check To Ensure Output Was Computed Without Failures ###
############################################################################

QA=`find $DIR_PROJECT/apps/fmriprep/sub-${SUBJECT} | grep "desc-confounds_regressors.tsv" | head -n1`
PREPROC=`find $DIR_PROJECT/apps/fmriprep/sub-${SUBJECT} | grep "desc-brain_mask.nii.gz" | head -n1`
HTML=`find $DIR_PROJECT/apps/fmriprep -maxdepth 1 | grep "${SUBJECT}*.html" | head -n1`
DIR_ROOT_PROBLEM=$DIR_PROJECT/apps/fmriprep/workflows/problematic_wf_${TODAY}

if [ -z `cat ${LOG_FILE} | grep 'fMRIPrep finished successfully!' | awk {'print $3'}` ] ; then
	mkdir -p ${DIR_ROOT_PROBLEM}
	mv $HTML ${DIR_ROOT_PROBLEM}/
	mv `echo $HTML | sed s@'.html'@''@g` ${DIR_ROOT_PROBLEM}/
	mv ${LOG_FILE} `echo ${LOG_FILE} | sed s@'Log'@'Log-ERROR'@g`
elif [ ! -f ${QA} ] || [ ! -f ${PREPROC} ] || [ ! -f ${HTML} ] ; then
	mkdir -p ${DIR_ROOT_PROBLEM}
	mv $HTML ${DIR_ROOT_PROBLEM}/
	mv `echo $HTML | sed s@'.html'@''@g` ${DIR_ROOT_PROBLEM}/
	mv ${LOG_FILE} `echo ${LOG_FILE} | sed s@'Log'@'Log-INCOM'@g`
else
	for NIFTI in `find $DIR_PROJECT/apps/fmriprep/sub-${SUBJECT} -iname '*_desc-preproc_bold.nii.gz'` ; do
		REF=`ls $NIFTI | sed s@'desc-preproc_bold'@'boldref'@g`
		MASK=`ls $NIFTI | sed s@'preproc_bold'@'brain_mask'@g`
		fslmaths $NIFTI -mul $MASK $NIFTI
		fslmaths $REF -mul $MASK $REF
	done
	rm -rf $DIR_WORKFLOW/fmriprep_wf/single_subject_${SUBJECT}_wf
	chmod -R ug+wrx $DIR_PROJECT/apps/fmriprep/sub-${SUBJECT}.html
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
