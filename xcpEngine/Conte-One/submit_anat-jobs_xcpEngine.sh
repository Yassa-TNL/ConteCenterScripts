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

########################################################
##### Build xcpEngine Singularity Image if Missing #####
########################################################

xcpEngine_rootdir='/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine'
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

anatRaw=`ls -1d /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-*/ses-*/anat/sub-*_ses-*_T1w.nii.gz | head -n6`

for anatInput in ${anatRaw} ; do

	sub=`echo $anatInput | cut -d '/' -f8 | cut -d '-' -f2`
	ses=`echo $anatInput | cut -d '/' -f9 | cut -d '-' -f2`
	xcpOutput=`echo /dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/pipe-anat-*/task-${TASK}/sub-${sub}/ses-${ses}/sub-${sub}_ses-${ses}.nii.gz | cut -d ' ' -f1`

	if [ -f ${xcpOutput} ] ; then

		echo ''
		echo "##################################################"
		echo "#sub-${sub} ses-${ses} already processed T1w Scan "
		echo "##################################################"
		echo ''

	else

		JobName=`echo an${sub}X${ses}`
		JobStatus=`qstat -u $USER | grep ${JobName} | awk {'print $5'}`
		if [ ! -z "$JobStatus" ] ; then

			echo ''
			echo "#####################################################"
			echo "#sub-${sub} ses-${ses} currently processing T1w Scan "
			echo "#####################################################"
			echo ''

		else

			echo ''
			echo "###################################################"
			echo "#Submitting Job For sub-${sub} ses-${ses} T1w Scan "
			echo "###################################################"
			echo ''

			Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/Conte-One/xcpEngine_postproc_pipeline.sh
			qsub -N ${JobName} ${Pipeline} ${sub} ${ses} ${anatInput} ${xcpEngine_container}

		fi
	fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
