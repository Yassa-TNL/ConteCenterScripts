#!/bin/bash
#$ -q yassalab,free*,pub*
#$ -pe openmp 8-16
#$ -R y
#$ -ckpt restart
################

module load singularity/3.0.0 2>/dev/null 

DIR_LOCAL_SCRIPTS=$1
DIR_LOCAL_BIDS=$2
DIR_LOCAL_APPS=$3
OUTPUT_SPACES="${4}"
SUBJECT=$5
OPT_ICA_AROMA=$6
OPT_STOP_FIRST_ERROR=$7

#########################################################################################
### Include Project-Specific Parameters Depending On BIDs Structure & Input Arguments ###
#########################################################################################

if [[ $OPT_ICA_AROMA == TRUE ]] ; then
	ICA=`echo --use-aroma`
fi

if [[ $OPT_STOP_FIRST_ERROR == TRUE ]] ; then
	STOP=`echo --stop-on-first-crash`
fi

if [[ `find $DIR_LOCAL_BIDS -type d -printf '%f\n' | grep ses | sort | uniq | wc -l` > 2 ]] ; then
	LONGITUDINAL=`echo --longitudinal`
fi

if [[ ! -f `find $DIR_LOCAL_BIDS -name *epi.nii.gz` ]] ; then
	SYN_CORRECTION=`echo --use-syn-sdc`
fi 

###############################################
### Define Log Files and Output Directories ###
###############################################

rm FP${SUBJECT}.*
TODAY=`date "+%Y%m%d"`
VERSION=`singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_fmriprep.simg --version | cut -d ' ' -f2`
COMMAND_FILE=`echo $DIR_LOCAL_APPS/fmriprep/logs/${TODAY}/${SUBJECT}_Command_${VERSION}.sh`
LOG_FILE=`echo $DIR_LOCAL_APPS/fmriprep/logs/${TODAY}/${SUBJECT}_Log_${VERSION}.txt`
DIR_LOCAL_WORKFLOW=$DIR_LOCAL_APPS/fmriprep/workflows
mkdir -p `dirname ${LOG_FILE}` ${DIR_LOCAL_WORKFLOW}

#########################################################################
### Execute FMRIPREP Using Singularity Container For A Single Subject ###
#########################################################################

echo "singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_fmriprep.simg \
	$DIR_LOCAL_BIDS \
	$DIR_LOCAL_APPS \
	participant --participant_label $SUBJECT \
	--work-dir $DIR_LOCAL_WORKFLOW \
	--fs-license-file $DIR_LOCAL_SCRIPTS/license_freesurfer.txt \
	--output-spaces "${OUTPUT_SPACES}" \
	--skip-bids-validation \
	--bold2t1w-dof 6 \
	--fs-no-reconall \
	--n_cpus 16 \
	--low-mem" ${ICA} ${STOP} ${LONGITUDINAL} ${SYN_CORRECTION} | tr '\t' '#' | sed s@'#'@''@g  > ${COMMAND_FILE}

chmod ug+wrx  ${COMMAND_FILE}

${COMMAND_FILE} > ${LOG_FILE} 2>&1

############################################################################
### Quality of Life Check To Ensure Output Was Computed Without Failures ###
############################################################################

QA=`find ${DIR_LOCAL_APPS}/fmriprep/sub-${SUBJECT} | grep "desc-confounds_regressors.tsv" | head -n1`
PREPROC=`find ${DIR_LOCAL_APPS}/fmriprep/sub-${SUBJECT} | grep "desc-brain_mask.nii.gz" | head -n1`
HTML=`find ${DIR_LOCAL_APPS}/fmriprep -maxdepth 1 | grep "${SUBJECT}*.html" | head -n1`
DIR_ROOT_PROBLEM=${DIR_LOCAL_WORKFLOW}/problematic_wf_${TODAY}

if [ -d "${DIR_LOCAL_APPS}/fmriprep/sub-${SUBJECT}/log" ] ; then

	echo "" >> ${LOG_FILE} 2>&1
	echo "⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡" >> ${LOG_FILE} 2>&1
	echo "ERROR: Problematic Log Was Created For sub-${SUBJECT}" >> ${LOG_FILE} 2>&1
	echo "⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡" >> ${LOG_FILE} 2>&1
	mkdir -p ${DIR_ROOT_PROBLEM}
	mv $HTML ${DIR_ROOT_PROBLEM}/
	mv `echo $HTML | sed s@'.html'@''@g` ${DIR_ROOT_PROBLEM}/
	mv ${LOG_FILE} `echo ${LOG_FILE} | sed s@'Log'@'Log-ERROR'@g`

elif [ ! -f ${QA} ] || [ ! -f ${PREPROC} ] || [ ! -f ${HTML} ] ; then

	echo "" >> ${LOG_FILE} 2>&1
	echo "⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ " >> ${LOG_FILE} 2>&1
	echo "ERROR: OUTPUT Was Not Computed To Competion For sub-${SUBJECT}" >> ${LOG_FILE} 2>&1
	echo "⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ " >> ${LOG_FILE} 2>&1
	mkdir -p ${DIR_ROOT_PROBLEM}
	mv $HTML ${DIR_ROOT_PROBLEM}/
	mv `echo $HTML | sed s@'.html'@''@g` ${DIR_ROOT_PROBLEM}/
	mv ${LOG_FILE} `echo ${LOG_FILE} | sed s@'Log'@'Log-INCOM'@g`

else

	echo "" >> ${LOG_FILE} 2>&1
	echo "⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ " >> ${LOG_FILE} 2>&1
	echo "SUCCESS: Fmriprep Ran To Compeltion For sub-${SUBJECT}  " >> ${LOG_FILE} 2>&1
	echo "⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ " >> ${LOG_FILE} 2>&1
	rm -rf ${DIR_LOCAL_WORKFLOW}/fmriprep_wf/single_subject_${SUBJECT}_wf
	chmod -R ug+wrx ${DIR_LOCAL_APPS}/fmriprep/sub-${SUBJECT}*

fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
