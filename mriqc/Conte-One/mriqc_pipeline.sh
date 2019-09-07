#!/bin/bash
#$ -N qc105
#$ -q yassalab
#$ -pe openmp 64
#$ -R y
#$ -ckpt restart
#####################################
### Define Input and Output Paths ###
#####################################

bids_root_path=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One
output_inter_dir=/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Spooling/One
#log_dir=`echo $output_inter_dir/fmriprep/logs`
#mkdir -p $log_dir

#############################################################
### Execute Fmriprep Pipeline using Singularity Container ###
#############################################################

module purge
module load singularity/3.0.0

singularity run --cleanenv /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/mriqc/mriqc-latest.simg /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One /dfs2/yassalab/rjirsara/ConteCenter/mriqc/Conte-One participant --participant-label 105



<<SKIP
CONTAINER ${bids_root_path} ${output_inter_dir} participant --participant_label SUB --fs-license-file \
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
  echo "${SUB}x${SES} did not complete processing through the fmriprep pipeline - Check logs"
  echo ''

fi
SKIP
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
