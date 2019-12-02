#!/bin/bash
#$ -q yassalab,free*,pub*
#$ -pe openmp 16
#$ -R y
#$ -ckpt restart
#####################################
### Load Software & Define Inputs ###
#####################################

module purge 2>/dev/null 
module load singularity/3.0.0 2>/dev/null 

sub=$1
bids_root_dir=$2
output_root_dir=$3
Freesurfer_License=$4
Singularity_Container=$5

################################################
### Prepare Log Files and Output Directories ###
################################################

workflow_root_dir=${output_root_dir}/fmriprep/workflows
commandfile=`echo ${output_root_dir}/logs/sub-${sub}_command.sh`
logfile=`echo ${output_root_dir}/logs/sub-${sub}_output.txt`
mkdir -p `dirname ${logfile}` ${working_dir}
rm FPREP${sub}.*

#########################################################################
### Execute FMRIPREP Using Singularity Container For A Single Subject ###
#########################################################################

echo "singularity run --cleanenv ${Singularity_Container} \
	${bids_root_dir} \
	${output_root_dir} \
	participant --participant_label ${sub} \
	--work-dir ${workflow_root_dir} \
	--fs-license-file ${Freesurfer_License} \
	--skip-bids-validation \
	--fs-no-reconall \
	--longitudinal \
	--n_cpus 16 \
	--use-aroma \
	--use-syn-sdc \
	--write-graph \
	--stop-on-first-crash \
	--low-mem" | tr '\t' ' ' > ${commandfile}

chmod -R 775 `dirname ${commandfile}`

${commandfile} > ${logfile} 2>&1

chmod -R 775 ${output_root_dir}
rm -rf ${workflow_root_dir}/fmriprep_wf/single_subject_${sub}_wf

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
