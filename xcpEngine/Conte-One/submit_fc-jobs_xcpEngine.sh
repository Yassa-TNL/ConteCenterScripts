#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script identifies subjects and processes data from Conte-One who need to be run through the 
xcpEngine preprocessing pipeline via singulatiry image.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module purge 2>/dev/null 
module load singularity/3.0.0 2>/dev/null 

###########################################################################
##### Define Files, Scripts, Preprocessed Files, and Output Directory #####
###########################################################################

Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/Conte-One/xcpEngine_postproc_pipeline.sh
xcpEngine_rootdir=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine
FmriprepDir=/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One
XcpDir=/dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One
TASKS='REST'
#HIPP AMG'

########################################################
##### Build xcpEngine Singularity Image if Missing #####
########################################################

xcpEngine_container=`echo ${xcpEngine_rootdir}/xcpEngine-latest.simg`
if [ -f $xcpEngine_container ] ; then

	echo ''
	echo "Preprocessing will be completed using the latest xcpEngine Singularity Image"
	echo ''

else

	echo ''
	echo "Singularity Image Not Found -- Building New Containter with Latest Version of xcpEngine"
	echo ''
	singularity build ${xcpEngine_container} docker://poldracklab/xcpEngine:latest

fi

##################################################
##### Copy xcpEngine Design Files if Missing #####
##################################################

xcpEngine_designs=`echo ${xcpEngine_rootdir}/Conte-One/designs/*.dsn | cut -d ' ' -f1`
if [ -f $xcpEngine_designs ] ; then

	echo ''
	echo "Design Files Located For xcpEngine Processing"
	echo ''

else

	echo ''
	echo "Design Files Not Found -- Copying New Files From GitHub"
	echo ''
	git clone https://github.com/PennBBL/xcpEngine.git
	mv ./xcpEngine/designs ${xcpEngine_rootdir}/Conte-One
	chmod -R 775 ${xcpEngine_rootdir}/Conte-One/designs
	rm -rf ./xcpEngine 

fi

###############################
##### Define New Subjects ##### 
###############################

for TASK in ${TASKS}; do 

	fmriPreProcs=`ls -1d ${FmriprepDir}/fmriprep/sub-*/ses-*/func/sub-*_ses-*_task-${TASK}_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz`

	designoptions=`cat $Pipeline | grep 'designs_options' | grep fc | cut -d '"' -f2`
	for fmriInput in ${fmriPreProcs} ; do

		sub=`echo $fmriInput | cut -d '/' -f9 | cut -d '-' -f2`
		ses=`echo $fmriInput | cut -d '/' -f10 | cut -d '-' -f2`

		designoptions=`cat $Pipeline | grep 'designs_options' | grep fc | cut -d '"' -f2`
		for design in $designoptions ; do
			SearchForOutput=`echo ${XcpDir}/pipe-${design}/task-${TASK}/sub-${sub}/ses-${ses}/sub-${sub}_ses-${ses}.nii.gz`
			if [ ! -f "${SearchForOutput}" ] ; then
				SUBMITJOB=`echo "Output Missing For $design"`
			fi
		done

		if [ -z "${SUBMITJOB}" ] ; then
	
			echo ''
			echo "#################################################"
			echo "#sub-${sub} ses-${ses} already processed ${TASK} "
			echo "#################################################"
			echo ''
			for design in $designoptions ; do
				ls ${XcpDir}/pipe-${design}/task-${TASK}/sub-${sub}/ses-${ses}/sub-${sub}_ses-${ses}.nii.gz
			done
		
		else

			unset "SUBMITJOB"
			JobName=`echo "${TASK:0:2}"${sub}X${ses}`
			JobStatus=`qstat -u $USER | grep ${JobName} | awk {'print $5'}`
			if [ ! -z "$JobStatus" ] ; then

				echo ''
				echo "####################################################"
				echo "#sub-${sub} ses-${ses} currently processing ${TASK} "
				echo "####################################################"
				echo ''
				echo "Current Job Status: $JobStatus"
			else

				echo ''
				echo "#######################################################"
				echo "#Submitting Job For sub-${sub} ses-${ses} task-${TASK} "
				echo "#######################################################"
				echo ''

				qsub -N ${JobName} ${Pipeline} ${sub} ${ses} ${fmriInput} ${xcpEngine_container}

			fi
		fi
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
