#!/bin/bash
#$ -N FSUBxSES
#$ -q yassalab,pub*
#$ -pe openmp 8-64
#$ -R y
#$ -ckpt restart
#####################################
### Define Input and Output Paths ###
#####################################

scripts_path=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fmriprep/Conte-One
bids_root_path=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One
output_inter_dir=/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Spooling/One
log_dir=`echo $output_inter_dir/fmriprep/logs`
mkdir -p $log_dir

#############################################################
### Execute Fmriprep Pipeline using Singularity Container ###
#############################################################

singularity run --cleanenv CONTAINER ${bids_root_path} ${output_inter_dir} participant --participant_label SUB --fs-license-file \
${scripts_path}/fs_license.txt --fs-no-reconall --longitudinal --force-bbr --use-aroma --fd-spike-threshold 0.2 --use-syn-sdc \
--write-graph --low-mem > ${log_dir}/SUBxSES_stdout.txt 2>&1

######################################################
### Move Output to Final Subject-level Directories ###
######################################################

if [ -f ${output_inter_dir}/fmriprep/sub-SUB*.html ] ; then

  chmod -r 775 ${output_inter_dir}/fmriprep/sub-SUB*
  cp -rf ${output_inter_dir}/fmriprep/sub-SUB* /dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One/ 
  cp -rf ${log_dir}/SUBxSES_stdout.txt /dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One/logs/

else

  echo ''
  echo "${SUB}x${SES} did not complete processing through the fmriprep pipeline - Check ogs"
  echo ''

fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
#<<SKIP
#fmriprep $bids_dir/ $other_dir/prepout participant -w $other_dir/prepwork --mem_mb 20000 --nthreads 8 --output-space fsaverage fsaverage5 fsnative template --fd-spike-threshold 0.5 --use-aroma --template MNI152NLin2009cAsym --participant-label P01
#--fd-spike-threshold 0.2
#SKIP

