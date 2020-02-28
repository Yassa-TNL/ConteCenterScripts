#!/bin/bash
#$ -q yassalab,pub*,free*
#$ -pe openmp 8-24
#$ -R y
#$ -ckpt restart
################

module load singularity/3.0.0

DIR_LOCAL_SCRIPTS=$1
DIR_LOCAL_BIDS=$2
DIR_LOCAL_APPS=$3
BYPASS_SINGULARITY_IMAGE=$4
SUBJECT=$5
OPT_REFINESURF_ACQ=$6

###########################################################################
### If Requested Process Subjects Without Using A Singularity Container ###
###########################################################################

if [[ $BYPASS_SINGULARITY_IMAGE == TRUE ]] ; then
	rm FS${SUBJECT}.*
	module load freesurfer/6.0
	for NII in `find $DIR_LOCAL_BIDS | grep sub-${SUBJECT} | grep T1w.nii.gz` ; do
		OUT_SUBDIR=`basename $NII | sed s@'_T1w.nii.gz'@''@g`
		MGZ=`echo $NII | sed s@"$DIR_LOCAL_BIDS"@"$DIR_LOCAL_APPS/freesurfer/mgz"@g | sed s@'.nii.gz'@'.mgz'@g`
		LOG_FILE=`echo $NII | sed s@"$DIR_LOCAL_BIDS"@"$DIR_LOCAL_APPS/freesurfer/logs"@g | sed s@'.nii.gz'@'_LOG.txt'@g`
		echo "#####################################################################" > ${LOG_FILE}
		echo "#    Freesurfer will be run on HPC Software Package: 6.0 version    #" >> ${LOG_FILE}
		echo "#####################################################################" >> ${LOG_FILE}
		if [ ! -f ${MGZ} ] ; then
			mkdir -p $DIR_LOCAL_APPS/freesurfer/mgz $DIR_LOCAL_APPS/freesurfer/logs
			mri_convert $NII ${MGZ} >> ${LOG_FILE}
  			chmod 775 ${MGZ}
		fi
		mkdir -p $DIR_LOCAL_APPS/freesurfer/$OUT_SUBDIR
		export SUBJECTS_DIR=$DIR_LOCAL_APPS/freesurfer/$OUT_SUBDIR
		recon-all -i ${MGZ} -s ${OUT_SUBDIR} -no-isrunning -all -hippocampal-subfields-T1 -brainstem-structures -qcache >> ${LOG_FILE}
		OUTLOG=`echo ${DIR_LOCAL_APPS}/freesurfer/${OUT_SUBDIR}/scripts/recon-all-status.log` > /dev/null/ 2>&1
		if [[ ! -z `cat $OUTLOG | grep 'finished without error' | sed s@' '@'_'@g` ]] ; then
			TODAY=`date "+%Y%m%d"`
			mkdir -p $DIR_LOCAL_APPS/freesurfer/problematic_wf_${TODAY} 
			mv ${DIR_LOCAL_APPS}/freesurfer/${OUT_SUBDIR} $DIR_LOCAL_APPS/freesurfer/problematic_wf_${TODAY} 
		else
			chmod -R 775 $DIR_LOCAL_APPS/freesurfer/$OUT_SUBDIR
		fi
	done
	exit 0
fi

################################################################
### Define Log File, Command Scripts, and Output Directories ###
################################################################

rm FS${SUBJECT}.*
TODAY=`date "+%Y%m%d"`
VERSION=`singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_freesurfer.simg --version | cut -d ' ' -f4`
COMMAND_FILE=`echo $DIR_LOCAL_APPS/freesurfer/logs/${TODAY}/${SUBJECT}_Command_${VERSION}.sh`
LOG_FILE=`echo $DIR_LOCAL_APPS/freesurfer/freesurfer_logs/${TODAY}/${SUBJECT}_Log_${VERSION}.txt`
mkdir -p `dirname ${LOG_FILE}`

#############################################################################
### Enable Options To Refine Pia Surface With Differently Weighted Images ###
#############################################################################

T2w_FILES=`find $DIR_LOCAL_BIDS/sub-${SUBJECT} -type f | grep T2w.nii.gz`

if [[ -z $T2w_FILES ]] ; then

	REFINE_PIA=`echo --refine_pial T1only`

elif [[ `echo $T2w_FILES | wc -l` == 1 ]] ; then

	REFINE_PIA=`echo --refine_pial T2`
	
elif [[ -f `echo $T2w_FILES | grep ${OPT_REFINESURF_ACQ}` && `echo $T2w_FILES | grep ${OPT_REFINESURF_ACQ} | wc -l` == 1 ]] ; then 

	REFINE_PIA=$(echo --refine_pial `${OPT_REFINESURF_ACQ} | cut -d '_' -f1 | cut -d '-' -f2`)
	REFINE_PIA_ACQ=$(echo --refine_pial_acquisition_label `${OPT_REFINESURF_ACQ} | cut -d '_' -f2 | sed  s@'.nii.gz'@''@g`)
fi

###########################################################################
### Execute FREESURFER Using Singularity Container For A Single Subject ###
###########################################################################

echo "singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_freesurfer.simg \
	$DIR_LOCAL_BIDS \
	$DIR_LOCAL_APPS/freesurfer \
	participant --participant_label PARTICIPANT_LABEL $SUBJECT \
	--license_file $DIR_LOCAL_SCRIPTS/license_freesurfer.txt \
	--skip_bids_validator \
	--n_cpus 24 \
	--3T true" ${REFINE_PIA} ${REFINE_PIA_ACQ} |  tr '\t' '#' | sed s@'#'@''@g > ${COMMAND_FILE}

chmod ug+wrx  ${COMMAND_FILE}

${COMMAND_FILE} > ${LOG_FILE}

chmod -r ug+wrx $DIR_LOCAL_APPS/freesurfer/sub-${SUBJECT}*

#############################################################################
### If This Subject Is Last To Be Processed Then Run Group-Level Analyses ###
#############################################################################

if [[ `qstat -u $USER | awk {'print $3'} |grep 'FS' | wc -l` == 1 ]] ; then
	for ANALYSIS in `echo group1 group2` ; do
		GROUP_LOG_FILE=`echo $LOG_FILE | sed s@"${SUBJECT}"@"${ANALYSIS}"@g`
		GROUP_COMMAND_FILE=`echo $COMMAND_FILE | sed s@"${SUBJECT}"@"${ANALYSIS}"@g`
		echo "singularity run --cleanenv $DIR_LOCAL_SCRIPTS/container_freesurfer.simg \
			$DIR_LOCAL_BIDS \
			$DIR_LOCAL_APPS/freesurfer \
			${ANALYSIS} \
			--license_file $DIR_LOCAL_SCRIPTS/license_freesurfer.txt \
			--skip_bids_validator \
			--n_cpus 24" ${ICA} ${STOP} ${LONGITUDINAL} ${SYN_CORRECTION} |  tr '\t' '#' | sed s@'#'@''@g > ${GROUP_COMMAND_FILE}

			chmod ug+wrx  ${GROUP_COMMAND_FILE}

			${GROUP_COMMAND_FILE} > ${GROUP_LOG_FILE} 2>&1
	done
	chmod -r ug+wrx $DIR_LOCAL_APPS/freesurfer/group*
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
