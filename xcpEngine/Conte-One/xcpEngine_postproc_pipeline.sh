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

sub=105
xcp_container=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/xcpEngine-latest.simg
designs_file=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/Conte-One/designs/fc-36p.dsn
xcp_outputdir=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One

#############################
### Define Tracking Files ###
#############################

commandfile=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/logs/sub-${sub}_command.sh
cohortfile=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/logs/sub-${sub}_cohort.csv
logfile=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/logs/sub-${sub}_stdERR+stdOUT.txt

mkdir -p ${xcp_outputdir} ${xcp_workdir} ${fmri_inputdir} 
rm XCP${sub}.e* XCP${sub}.o* 

##########################
### Create Cohort File ###
##########################

scans=`echo /dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One/fmriprep/sub-${sub}/ses-*/func/sub-${sub}_ses-*_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz`
echo "id0,img" > $cohortfile

for scan in $scans ; do 
  echo "sub-${sub},${scan}" >> $cohortfile
done

##################################
### Execute xcpEngine Pipeline ###
##################################

echo singularity run --cleanenv ${xcp_container} \
  -c ${cohort_file} \
  -d ${designs_file} \
  -o ${xcp_outputdir} \
  -t 3 > ${commandfile}

chmod -R 775 ${commandfile}

${commandfile} > ${logfile} 2>&1

chmod -R 775 ${xcp_outputdir}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
