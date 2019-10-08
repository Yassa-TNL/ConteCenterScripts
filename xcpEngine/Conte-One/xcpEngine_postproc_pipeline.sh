#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 4
#$ -R y
#$ -ckpt restart
#####################################
### Load Software & Define Inputs ###
#####################################

module purge 2>/dev/null 
module load singularity/3.0.0 2>/dev/null 

sub=$1
ses=$2
scan=$3
xcpEngine_container=$4
seq=`echo $scan | cut -d '_' -f3`

#############################
### Define Tracking Files ###
#############################

commandfile=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/logs/sub-${sub}_${ses}_${seq}_command.sh
cohortfile=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/logs/sub-${sub}_${ses}_${seq}_cohort.csv
logfile=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/logs/sub-${sub}_${ses}_${seq}_stdERR+stdOUT.txt

mkdir -p ${xcp_outputdir} ${xcp_workdir} ${fmri_inputdir} 
rm ${sub}"${seq:5:1}"${ses}.e* ${sub}"${seq:5:1}"${ses}.o* 

##########################
### Create Cohort File ###
##########################

echo "id0,img" > $cohortfile

for scan in $scans ; do 
  echo "sub-${sub},${scan}" >> $cohortfile
done

##################################
### Execute xcpEngine Pipeline ###
##################################

designs_file=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/Conte-One/fc-24p.dsn

for design in ${designs_file} ; do

  option=`basename $designs_file | cut -d '.' -f1`
  xcp_outputdir=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/${seq}/sub-${sub}/ses-${ses}/${option}

  echo singularity run --cleanenv ${xcpEngine_container} \
    -c ${cohortfile} \
    -d ${design} \
    -o ${xcp_outputdir} \
    -t 3 > ${commandfile}

  chmod -R 775 ${commandfile}

  ${commandfile} > ${logfile} 2>&1

  chmod -R 775 ${xcp_outputdir}

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
