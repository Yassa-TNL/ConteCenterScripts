#!/bin/bash
###################################################################################################
##########################              CONTE Center 2.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script automatically downloads the raw Conte Center 2.0 data from Flywheel and converts the images
to BIDs format where they will be processed further through various pipelines.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

#################################################
### Set Paths and Find Newly Scanned Subjects ###
#################################################

sites='UCI UCSD'

for site in $sites ; do

	dir_dicom=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-${site}
	fw ls "yassalab/Conte-Two-${site}" | sed s@'none '@''@g | grep T > ${dir_dicom}/SUBS_fw.txt
	ls -d /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/*/ses-${site} | sed s@'sub-'@''@g | cut -d '/' -f8 > ${dir_dicom}/SUBS_hpc.txt
	NewSubs=`diff ${dir_dicom}/SUBS_fw.txt ${dir_dicom}/SUBS_hpc.txt | sed -n '1!p' | grep '<' | sed s@'< '@''@g`
	rm ${dir_dicom}/SUBS_hpc.txt ${dir_dicom}/SUBS_fw.txt

	if [ -z "$NewSubs" ]; then

		echo ""
		echo "⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # "
		echo "Everything is up-to-date for ${site}"
		echo "⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # "
		echo ""

	else	

		echo ""
		echo "⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # "
		echo "${site} Has Newly Scanned Subjects:" `echo ${NewSubs} | tr '\n' ' '`
		echo "⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # ⚡ # "
		echo ""

###############################################
### Submit Jobs for Newly Detected Subjects ###
###############################################

		for subid in $NewSubs ; do

			JobName=`echo ${site}${subid}`
			JobStatus=`qstat -u $USER | grep ${JobName} | awk {'print $5'} | tr '\n' ' ' | cut -d ' ' -f1`

			if [ ! -z "$JobStatus" ] ; then

				echo ''
				echo "#####################################################"
				echo "# ${site} - ${subid} is currently being processed..."
				echo "#####################################################"
				echo ''

			else

				echo ''
				echo "################################################"
				echo "# Submitting JOB TO DOWNLOAD ${site} - ${subid} "
				echo "################################################"
				echo ''

				JobNameA=`echo ${site}${subid}A`
				Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/BIDs_Download.sh
				qsub -N ${JobNameA} ${Pipeline} ${subid} ${site} ${dir_dicom}
<<SKIP
				if [ ${site} == "UCI" ] ; then

					Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/PullPsychoPyData.exp
					${Pipeline} ${FIBRE_PASSWORD} ${subid} ${dir_dicom}/BIDs_Events 1>/dev/null

 				elif [ ${site} == "UCSD" ] ; then

					Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/PullPsychoPyData.exp
					${Pipeline} ${FIBRE_PASSWORD} ${subid} ${dir_dicom}/BIDs_Events 1>/dev/null

				fi

				JobNameB=`echo ${site}${subid}B`
				Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/PushPsychPyData.sh
				qsub -hold_jid ${JobNameA} -N ${JobNameB} ${Pipeline} ${subid} ${site}

				JobNameC=`echo ${site}${subid}C`
				Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/BIDs_MetaData.py
				echo "python ${Pipeline} ${subid} ${site}" | qsub -hold_jid ${JobNameB} -N ${JobNameC} -q yassalab -pe openmp 
SKIP

			fi
		done
	fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
