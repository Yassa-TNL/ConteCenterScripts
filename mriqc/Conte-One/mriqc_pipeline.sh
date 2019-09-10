#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 8-64
#$ -R y
#$ -ckpt restart
#####################
### Define Inputs ###
#####################

sub=`echo $1`
ses=`echo $2`
mriqc_container=`echo $3`
bids_directory=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One

######################
### Define Outputs ###
######################

output_dir=/dfs2/yassalab/rjirsara/ConteCenter/mriqc/Conte-One/sub-${sub}
working_dir=${output_dir}/sub-${sub}_ses-${ses}_intermediates
commandfile=`echo ${output_dir}/logs/sub-${sub}_ses-${ses}_command.txt`
logfile=`echo ${output_dir}/logs/sub-${sub}_ses-${ses}_stdout.txt`
mkdir -p ${working_dir} `dirname ${logfile}` 
rm QC${sub}x${ses}.e* QC${sub}x${ses}.o* 

#############################################################
### Execute Fmriprep Pipeline using Singularity Container ###
#############################################################

module purge 2>/dev/null 
module load singularity/3.0.0 2>/dev/null 

echo "singularity run --cleanenv ${mriqc_container} ${bids_directory} ${output_dir} participant --participant-label ${sub} --session-id ${ses} --work-dir ${working_dir}" > ${commandfile}

singularity run --cleanenv ${mriqc_container} ${bids_directory} ${output_dir} participant --participant-label ${sub} --session-id ${ses} --work-dir ${working_dir} > ${logfile} 2>&1

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
