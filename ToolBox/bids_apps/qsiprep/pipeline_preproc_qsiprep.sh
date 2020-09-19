#!/bin/bash
#$ -q yassalab,free*,pub*
#$ -pe openmp 64
#$ -R y
#$ -ckpt restart
################

module load singularity/3.0.0 2>/dev/null 

DIR_TOOLBOX=$1
DIR_PROJECT=$2
SUBJECT=$3
OPT_STOP_FIRST_ERROR=$4

#########################################################################################
### Include Project-Specific Parameters Depending On BIDs Structure & Input Arguments ###
#########################################################################################

SCANS=`find $DIR_PROJECT/bids/sub-${SUBJECT} -type f -printf "%f\n" | grep dwi.nii.gz | tr '\n' '_'`
if [[ $SCANS == *'_run-'* ]] ; then
	COMBINE=`echo --denoise-before-combining --combine_all_dwis`
fi

SCANS=`find $DIR_PROJECT/bids/sub-${SUBJECT} -type f | grep fmap | grep dwi.nii.gz | tr '\n' '_'`
if [[ ! -z $SCANS ]] ; then
	SYN_CORRECTION=`echo --use-syn-sdc`
fi 

if [[ $OPT_STOP_FIRST_ERROR == TRUE ]] ; then
	STOP=`echo --stop-on-first-crash`
fi

if [[ `find $DIR_PROJECT/bids -type d -printf '%f\n' | grep ses | sort | uniq | wc -l` > 2 ]] ; then
	LONGITUDINAL=`echo --longitudinal`
fi

###############################################
### Define Log Files and Output Directories ###
###############################################

rm QP${SUBJECT}.*
TODAY=`date "+%Y%m%d"`
VERSION=`singularity run --cleanenv ${DIR_TOOLBOX}/bids_apps/qsiprep/container_qsiprep.simg --version | cut -d ' ' -f2`
COMMAND_FILE=`echo $DIR_PROJECT/apps/qsiprep/logs/${TODAY}/${SUBJECT}_Command_${VERSION}.sh`
LOG_FILE=`echo $DIR_PROJECT/apps/qsiprep/logs/${TODAY}/${SUBJECT}_Log_${VERSION}.txt`
DIR_WORKFLOW=$DIR_PROJECT/apps/qsiprep/workflows
mkdir -p `dirname ${LOG_FILE}` ${DIR_WORKFLOW}

#########################################################################
### Execute qsiprep Using Singularity Container For A Single Subject ###
#########################################################################

echo "singularity run --cleanenv $DIR_TOOLBOX/bids_apps/qsiprep/container_qsiprep.simg \
	$DIR_PROJECT/bids \
	$DIR_PROJECT/apps \
	participant --participant_label ${SUBJECT} \
	-w $DIR_PROJECT/apps/qsiprep/workflows \
	--fs-license-file $DIR_TOOLBOX/bids_apps/freesurfer/license_freesurfer.txt \
	--b0-motion-corr-to iterative \
	--impute-slice-threshold 0 \
	--template MNI152NLin2009cAsym \
	--force-spatial-normalization \
	--output-resolution 2 \
	--output-space T1w \
	--skip_bids_validation \
	--write-graph \
	--low-mem" ${COMBINE} ${STOP} ${LONGITUDINAL} ${SYN_CORRECTION} | tr '\t' '#' | sed s@'#'@''@g  > ${COMMAND_FILE}

chmod ug+wrx ${COMMAND_FILE}

${COMMAND_FILE} > ${LOG_FILE} 2>&1

############################################################################
### Quality of Life Check To Ensure Output Was Computed Without Failures ###
############################################################################

QA=`find ${DIR_PROJECT}/apps/qsiprep/sub-${SUBJECT} | grep "_confounds.tsv" | head -n1`
PREPROC=`find ${DIR_PROJECT}/apps/qsiprep/sub-${SUBJECT} | grep "desc-preproc_dwi.nii.gz" | head -n1`
HTML=`find ${DIR_PROJECT}/apps/qsiprep -maxdepth 1 | grep "${SUBJECT}*.html" | head -n1`
DIR_ROOT_PROBLEM=${DIR_WORKFLOW}/problematic_wf_${TODAY}

if [ -d "${DIR_PROJECT}/apps/qsiprep/sub-${SUBJECT}/log" ] ; then

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
	echo "SUCCESS: qsiprep Ran To Compeltion For sub-${SUBJECT}  " >> ${LOG_FILE} 2>&1
	echo "⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ ⚡ " >> ${LOG_FILE} 2>&1
	rm -rf ${DIR_WORKFLOW}/qsiprep_wf/single_subject_${SUBJECT}_wf
	chmod -R ug+wrx ${DIR_PROJECT}/apps/qsiprep/sub-${SUBJECT}*

fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
