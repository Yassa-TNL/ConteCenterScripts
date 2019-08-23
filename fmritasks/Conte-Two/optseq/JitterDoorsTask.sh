#!/bin/bash
###################################################################################################
##########################              CONTE Center 2.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script uses software from optseq2 to create a rapid-presentation event rate for trails of the 
Doors Guessing Task. The aim is to define the optimal timing of events that will allow for varying
amounts of overlap between each trail to better track the hemodynamic responce function.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load afni/v19.0.01
output_dir=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fMRItasks/Conte-Two/optseq

#################################
### Caluclate Optimal Jitters ###
#################################

${output_dir}/optseq2 --ntp 150 --tr 1.5 --psdwin 0 20 0.5 --ev WIN 6 13 --ev LOSS 6 13 --tprescan -6 \
--evc 1 -1 --nkeep 6 --o ${output_dir}/Doors --tnullmin 1.5 --tnullmax 3.5 --nsearch 250000

######################################
### Rearrange Output to CSV Format ###
######################################

for file in ${output_dir}/Doors*.par ; do

  final_dir=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fmritasks/Conte-Two/PsychoPy/JitterOutput
  echo 'Now Converting '${file}' to CSV Format'
  csv=`echo $file | sed s@'.par'@'.csv'@g`
  echo 'TimeofTask,Duration,Condition,Contrast' > ${final_dir}/${csv}
  cat $file | awk '{print $1,$3,$5,$2}' | sed s@' '@','@g >> ${final_dir}/${csv}
  chmod ug+wrx ${final_dir}/${csv}

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
