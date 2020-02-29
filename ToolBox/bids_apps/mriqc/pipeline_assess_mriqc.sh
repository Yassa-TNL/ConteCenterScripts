#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 8
#$ -R y
#$ -ckpt restart
#####################################
### Load Software & Define Inputs ###
#####################################

module purge 2>/dev/null 
module load singularity/3.0.0 2>/dev/null 

sub=`echo $1`
ses=`echo $2`
mriqc_container=`echo $3`
bids_directory=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One

###########################################################################
### Execute Subject-Level Analysis of MRIQC using Singularity Container ###
###########################################################################

if [ ! ${sub} == "GROUP" ]; then

  output_dir=/dfs2/yassalab/rjirsara/ConteCenter/mriqc/Conte-One
  working_dir=${output_dir}/sub-${sub}_ses-${ses}_intermediates
  commandfile=`echo ${output_dir}/logs/sub-${sub}_ses-${ses}_command.sh`
  logfile=`echo ${output_dir}/logs/sub-${sub}_ses-${ses}_stdout.txt`
  mkdir -p ${working_dir} `dirname ${logfile}` 
  rm QC${sub}x${ses}.e* QC${sub}x${ses}.o* 

  echo "singularity run --cleanenv ${mriqc_container} ${bids_directory} ${output_dir} participant --participant-label ${sub} --session-id ${ses} --work-dir ${working_dir} --n_procs 8 --ants-nthreads 8 --fft-spikes-detector --fd_thres 0.2" > ${commandfile}

  singularity run --cleanenv ${mriqc_container} \
    ${bids_directory} \
    ${output_dir} \
    participant --participant-label ${sub} \
    --session-id ${ses} \
    --work-dir ${working_dir} \
    --n_procs 8 \
    --ants-nthreads 8 \
    --fft-spikes-detector \
    --fd_thres 0.2 > ${logfile} 2>&1

  chmod -R 775 ${output_dir}
fi

##########################################################
### Execute MRIQC Pipeline using Singularity Container ###
##########################################################

if [ ${sub} == "GROUP" ]; then

  bids_directory=`echo /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One`
  output_dir=`echo /dfs2/yassalab/rjirsara/ConteCenter/mriqc/Conte-One`
  commandfile=`echo ${output_dir}/logs/group_command.sh`
  logfile=`echo ${output_dir}/logs/group_stdout.txt`
  mkdir -p ${working_dir} `dirname ${logfile}` 
  rm QC_GROUP.e* QC_GROUP.o* 

  echo "singularity run --cleanenv ${mriqc_container} ${bids_directory} ${output_dir} group --n_procs 8 --ants-nthreads 8" > ${commandfile}

  singularity run --cleanenv ${mriqc_container} \
    ${bids_directory} \
    ${output_dir} \
    group \
    --n_procs 8 \
    --ants-nthreads 8 > ${logfile} 2>&1

  chmod -R 775 ${output_dir}
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
