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

output_dir=/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One/sub-${sub}
working_dir=${output_dir}/sub-${sub}_intermediates
commandfile=`echo ${output_dir}/logs/sub-${sub}_command.txt`
logfile=`echo ${output_dir}/logs/sub-${sub}_stdout.txt`
mkdir -p ${working_dir} `dirname ${logfile}` 
rm FP${sub}.e* FP${sub}.o* 

echo " singularity run --cleanenv ${fmriprep_container} ${bids_directory} participant --participant_label ${sub} -w ${output_inter_dir} --fs-license-file ${scripts_path}/fs_license.txt --fs-no-reconall --longitudinal --force-bbr --use-aroma --fd-spike-threshold 0.2 --use-syn-sdc --write-graph --low-mem" > ${commandfile}

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
  --use-syn-sdc \
  --write-graph \
  --stop-on-first-crash \
  --low-mem > ${logfile} 2>&1

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
#<<SKIP
#fmriprep $bids_dir/ $other_dir/prepout participant -w $other_dir/prepwork --mem_mb 20000 --nthreads 8 --output-space fsaverage fsaverage5 fsnative template --fd-spike-threshold 0.5 --use-aroma --template MNI152NLin2009cAsym --participant-label P01
#--fd-spike-threshold 0.2
#SKIP

