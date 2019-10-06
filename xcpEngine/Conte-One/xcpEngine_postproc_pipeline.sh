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
fmri_inputdir=/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One/fmriprep
xcp_container=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/xcpEngine-latest.simg
designs_file=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/Conte-One/fc-36p.dsn
xcp_workdir=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/sub-${sub}_intermediates
xcp_outputdir=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/fc-36p
cohort_file=`echo ${xcp_workdir}/cohort.csv`

#############################
### Define Tracking Files ###
#############################

commandfile=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/commands/sub-${sub}_command.sh
logfile=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/commands/sub-${sub}_stdERR+stdOUT.txt

mkdir -p ${xcp_outputdir} ${xcp_workdir} ${fmri_inputdir} 
rm XCP{sub}.e* XCP${sub}.o* 

##########################
### Create Cohort File ###
##########################

scans=`echo ${fmri_inputdir}/sub-${sub}/ses-*/func/sub-${sub}_ses-*_task-REST_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz | sed s@"${fmri_inputdir}/"@""@g`
echo "id0,img" > $cohort_file

for scan in $scans ; do 
  echo "sub-${sub},${scan}" >> $cohort_file
done

##################################
### Execute xcpEngine Pipeline ###
##################################

echo "singularity run --cleanenv ${xcp_container} -r ${fmri_inputdir} -c ${cohort_file} -d ${designs_file} -i ${xcp_workdir} -o ${xcp_outputdir}" > ${commandfile}

singularity run --cleanenv ${xcp_container} \
  -r ${fmri_inputdir} \
  -c ${cohort_file} \
  -d ${designs_file} \
  -i ${xcp_workdir} \
  -o ${xcp_outputdir} > ${logfile} 2>&1

chmod -R 775 ${xcp_outputdir}

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
