#!/bin/bash
#$ -q yassalab,free*,pub*
#$ -pe openmp 16-24
#$ -R y
#$ -ckpt restart
################

module load singularity/3.0.0 2>/dev/null 

DIR_LOCAL_SCRIPTS=$1
DIR_LOCAL_BIDS=$2
DIR_LOCAL_APPS=$3
SUBJECT=$4
OPT_STOP_FIRST_ERROR=$5

#########################################################################################
### Include Project-Specific Parameters Depending On BIDs Structure & Input Arguments ###
#########################################################################################

SCANS=`find $DIR_LOCAL_BIDS/sub-${SUBJECT} -type f -printf "%f\n" | grep dwi.nii.gz | tr '\n' '_'`
if [[ $SCANS == *'_run-'* ]] ; then
	COMBINE=`echo --denoise-before-combining --combine_all_dwis`
fi

SCANS=`find $DIR_LOCAL_BIDS/sub-${SUBJECT} -type f | grep fmap | grep dwi.nii.gz | tr '\n' '_'`
if [[ ! -z $SCANS ]] ; then
	SYN_CORRECTION=`echo --use-syn-sdc`
fi

if [[ $OPT_STOP_FIRST_ERROR == TRUE ]] ; then
	STOP=`echo --stop-on-first-crash`
fi

if [[ `find $DIR_LOCAL_BIDS -type d -printf '%f\n' | grep ses | sort | uniq | wc -l` > 2 ]] ; then
	LONGITUDINAL=`echo --longitudinal`
fi

###############################################
### Define Log Files and Output Directories ###
###############################################

rm QP${SUBJECT}.*
TODAY=`date "+%Y%m%d"`
VERSION=`singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_qsiprep.simg --version | cut -d ' ' -f2`
COMMAND_FILE=`echo $DIR_LOCAL_APPS/qsiprep/logs/${TODAY}/${SUBJECT}_Command_${VERSION}.sh`
LOG_FILE=`echo $DIR_LOCAL_APPS/qsiprep/logs/${TODAY}/${SUBJECT}_Log_${VERSION}.txt`
DIR_LOCAL_WORKFLOW=$DIR_LOCAL_APPS/qsiprep/workflows
mkdir -p `dirname ${LOG_FILE}` ${DIR_LOCAL_WORKFLOW}

#########################################################################
### Execute qsiprep Using Singularity Container For A Single Subject ###
#########################################################################

singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_qsiprep.simg \
	$DIR_LOCAL_BIDS \
	$DIR_LOCAL_APPS/qsirecon \
	participant --participant_label $SUBJECT \
	-w $DIR_LOCAL_APPS/qsirecon/workflows \
	--fs-license-file $DIR_LOCAL_SCRIPTS/license_freesurfer.txt \
    	--recon_spec $DIR_LOCAL_SCRIPTS/designs/mrtrix_singleshell_ss3t_noACT.json \
	--recon-only \
	--force-spatial-normalization \
	--template MNI152NLin2009cAsym \
	--output-resolution 2 \
	--output-space T1w \
	--skip_bids_validation \
	--write-graph \
	--low-mem \
	--sloppy 

	--recon-input $DIR_LOCAL_APPS/qsiprep/sub-${SUBJECT} \
    	--recon_spec gqi_scalar_export.json \



singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_qsiprep.simg \
	$DIR_LOCAL_BIDS \
	$DIR_LOCAL_APPS/qsirecon \
	participant --participant_label $SUBJECT \
	--fs-license-file $DIR_LOCAL_SCRIPTS/license_freesurfer.txt \
	-w ${DIR_LOCAL_APPS}/workflow \
	--recon-input $DIR_LOCAL_APPS/qsiprep \
	--recon-spec mrtrix_multishell_msmt_noACT \
	--recon-only \
	--sloppy 




  qsiprep -w ${WORKDIR}/DSDTI/work \
       ${WORKDIR}/data/DSDTI \
      --recon-input ${WORKDIR}/DSDTI/derivatives/qsiprep \
       ${WORKDIR}/DSDTI/derivatives \
       participant \
      --recon-spec ${HOME}/projects/qsiprep/.circleci/mrtrix_msmt_csd_test.json \
      --recon-only \
      --mem_mb 4096 \
      --output-resolution 5 \
      --fs-license-file $FREESURFER_HOME/license.txt \
      --nthreads 2 -vv




singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_qsiprep.simg \
$DIR_LOCAL_BIDS \
$DIR_LOCAL_APPS/qsirecon \
participant --participant_label ${SUBJECT} \
-w $DIR_LOCAL_APPS/qsirecon/workflows \
--fs-license-file $DIR_LOCAL_SCRIPTS/license_freesurfer.txt \
--b0-motion-corr-to iterative \
--impute-slice-threshold 0 \
--force-spatial-normalization \
--template MNI152NLin2009cAsym \
--force-spatial-normalization \
--output-resolution 2 \
--output-space T1w \
--skip_bids_validation \
--write-graph \
--low-mem \
--recon_only \
--recon-spec $DIR_LOCAL_SCRIPTS/designs/mrtrix_multishell_msmt.json \
--recon-input $DIR_LOCAL_APPS/qsiprep 



singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_qsiprep.simg \
$DIR_LOCAL_BIDS \
$DIR_LOCAL_APPS/qsirecon \
participant --participant_label ${SUBJECT} \
-w $DIR_LOCAL_APPS/qsirecon/workflows \
--fs-license-file $DIR_LOCAL_SCRIPTS/license_freesurfer.txt \
--b0-motion-corr-to iterative \
--impute-slice-threshold 0 \
--force-spatial-normalization \
--template MNI152NLin2009cAsym \
--force-spatial-normalization \
--output-resolution 2 \
--output-space T1w \
--skip_bids_validation \
--write-graph \
--low-mem \
--recon-spec $DIR_LOCAL_SCRIPTS/designs/mrtrix_multishell_msmt.json \
--recon-input $DIR_LOCAL_APPS/qsiprep 




--recon-spec mrtrix_multishell_msmt



[--recon-only]
               [--recon-spec RECON_SPEC] [--recon-input RECON_INPUT]

echo ""

singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_qsiprep.simg \
	$DIR_LOCAL_BIDS \
	$DIR_LOCAL_APPS \
	participant --participant_label ${SUBJECT} \
	-w $DIR_LOCAL_APPS/qsiprep/workflows \
	--fs-license-file $DIR_LOCAL_SCRIPTS/license_freesurfer.txt \
	--b0-motion-corr-to iterative \
	--impute-slice-threshold 0 \
	--force-spatial-normalization \
	--template MNI152NLin2009cAsym \
	--force-spatial-normalization \
	--output-resolution 2 \
	--output-space T1w \
	--skip_bids_validation \
	--write-graph \
	--low-mem


singularity run -e -B /project:/project -B /scratch:/scratch -B /localscratch:/localscratch /dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox/bids_apps/qsiprep/container_qsiprep.simg --bids-dir  --output-dir test_out --analysis-level participant --fs-license-file /project/6007967/akhanf/opt/freesurfer/.license


qsiprep-singularity --image /project/6007967/akhanf/singularity/bids-apps/pennbbl_qsiprep_0.6.4.sif






singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_qsiprep.simg \
	$DIR_LOCAL_BIDS \
	$DIR_LOCAL_APPS/qsirecon \
	participant --participant_label ${SUBJECT} \
	-w $DIR_LOCAL_APPS/qsirecon/workflows \
	--fs-license-file $DIR_LOCAL_SCRIPTS/license_freesurfer.txt \
    	--recon_spec mrtrix_multishell_msmt \
	--recon-only \
	--output-resolution 2 \
	--low-mem 


	#--recon-input $DIR_LOCAL_APPS/qsiprep \
	--b0-motion-corr-to iterative \
	--impute-slice-threshold 0 \
	--force-spatial-normalization \
	--template MNI152NLin2009cAsym \
	--force-spatial-normalization \
	--output-resolution 2 \
	--output-space T1w \
	--skip_bids_validation \
	--write-graph \
	--low-mem" ${COMBINE} ${STOP} ${LONGITUDINAL} ${SYN_CORRECTION} | tr '\t' '#' | sed s@'#'@''@g  > ${COMMAND_FILE}

chmod ug+wrx  ${COMMAND_FILE}

${COMMAND_FILE} > ${LOG_FILE} 2>&1

############################################################################
### Quality of Life Check To Ensure Output Was Computed Without Failures ###
############################################################################

QA=`find ${DIR_LOCAL_APPS}/qsiprep/sub-${SUBJECT} | grep "_confounds.tsv" | head -n1`
PREPROC=`find ${DIR_LOCAL_APPS}/qsiprep/sub-${SUBJECT} | grep "desc-preproc_dwi.nii.gz" | head -n1`
HTML=`find ${DIR_LOCAL_APPS}/qsiprep -maxdepth 1 | grep "${SUBJECT}*.html" | head -n1`
DIR_ROOT_PROBLEM=${DIR_LOCAL_WORKFLOW}/problematic_wf_${TODAY}

if [ -d "${DIR_LOCAL_APPS}/qsiprep/sub-${SUBJECT}/log" ] ; then

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
	rm -rf ${DIR_LOCAL_WORKFLOW}/qsiprep_wf/single_subject_${SUBJECT}_wf
	chmod -R ug+wrx ${DIR_LOCAL_APPS}/qsiprep/sub-${SUBJECT}*

fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
