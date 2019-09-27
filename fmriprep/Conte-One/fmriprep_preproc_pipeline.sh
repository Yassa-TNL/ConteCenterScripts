#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 16
#$ -R y
#$ -ckpt restart
#####################################
### Load Software & Define Inputs ###
#####################################

module purge 2>/dev/null 
module load singularity/3.0.0 2>/dev/null 

sub=`echo $1`
fmriprep_container=`echo $2`
bids_directory=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One
fslicense=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fmriprep/Conte-One/fs_license.txt

##############################################################################
### Execute Subject-Level Analysis of FMRIPREP Using Singularity Container ###
##############################################################################

output_dir=/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One
working_dir=${output_dir}/sub-${sub}_intermediates
commandfile=`echo ${output_dir}/commands/sub-${sub}_command.sh`
logfile=`echo ${output_dir}/commands/sub-${sub}_stdERR+stdOUT.txt`
mkdir -p ${working_dir} `dirname ${logfile}` 
rm FP${sub}.e* FP${sub}.o* 

echo "singularity run --cleanenv ${fmriprep_container} ${bids_directory} ${output_dir} participant --participant_label ${sub} --work-dir ${working_dir} --fs-license-file ${fslicense} --skip-bids-validation --fs-no-reconall --longitudinal --nthreads 16 --use-aroma --fd-spike-threshold 0.2 --use-syn-sdc --write-graph --stop-on-first-crash --low-mem " > ${commandfile}

singularity run --cleanenv ${fmriprep_container} \
  ${bids_directory} \
  ${output_dir} \
  participant --participant_label ${sub} \
  --work-dir ${working_dir} \
  --fs-license-file ${fslicense} \
  --skip-bids-validation \
  --fs-no-reconall \
  --longitudinal \
  --nthreads 16 \
  --use-aroma \
  --fd-spike-threshold 0.2 \
  --output-space fsaverage fsaverage5 fsnative template \
  --template MNI152NLin2009cAsym \
  --use-syn-sdc \
  --write-graph \
  --stop-on-first-crash \
  --low-mem > ${logfile} 2>&1

chmod -R 775 ${output_dir}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
