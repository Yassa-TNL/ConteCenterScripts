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

sub=$1
ses=$2
InputFile=$3
xcpEngine_container=$4

###########################################################
### Determine Which Modules will be Run From Input File ###
###########################################################

if [[ $InputFile == *"_bold.nii.gz" ]] ; then

	designs_options="fc-36p fc-24p_gsr"
	TASK=`echo $InputFile | cut -d '_' -f3 | cut -d '-' -f2`

elif [[ $InputFile == *"_T1w.nii.gz" ]] ; then

	designs_options="anat-antsct anat-complete anat_jlf_complete anat-minimal"
	TASK=`echo $InputFile | cut -d '/' -f10`

fi

#############################################
### Define Cohort, Command, and Log Files ###
#############################################

for DESIGN in ${designs_options} ; do

	dir_root_logs=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/logs/pipe-${DESIGN}/task-${TASK}
	commandfile=${dir_root_logs}/sub-${sub}_ses-${ses}_command.sh
	cohortfile=${dir_root_logs}/sub-${sub}_ses-${ses}_cohort.csv
	logfile=${dir_root_logs}/sub-${sub}_ses-${ses}_output.txt

	rm "${TASK:0:2}"${sub}X${ses}.*
	mkdir -p ${dir_root_logs}

	echo "id0,id1,img" > $cohortfile
	echo "sub-${sub},ses-${ses},${InputFile}" >> $cohortfile

##################################
### Execute xcpEngine Pipeline ###
##################################

	designfile=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/Conte-One/designs/${DESIGN}.dsn
	xcp_outputdir=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/pipe-${DESIGN}/task-${TASK}
	mkdir -p ${xcp_outputdir}

 	echo "singularity run --cleanenv ${xcpEngine_container} \
		-c ${cohortfile} \
		-d ${designfile} \
		-o ${xcp_outputdir} \
		-t 3" > ${commandfile}
	
	chmod -R 775 `dirname ${commandfile}`

	${commandfile} > ${logfile} 2>&1

	chmod -R 775 ${xcp_outputdir}

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
