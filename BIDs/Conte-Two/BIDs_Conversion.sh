#!/bin/bash
###################################################################################################
##########################              CONTE Center 2.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script automatically downloads the raw Conte Center 2.0 data from Flywheel and converts the images
to BIDs format where they will be processed further through various pipelines.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
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

  fw ls "yassalab/Conte-Two-${site}" | sed s@'rw '@''@g | grep -v test | grep -v Conte-Two-${site} | grep T > ${dir_dicom}/SUBS_fw.txt
  ls /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/ | sed s@'sub-'@''@g > ${dir_dicom}/SUBS_hpc.txt
  NewSubs=`diff ${dir_dicom}/SUBS_fw.txt ${dir_dicom}/SUBS_hpc.txt | sed -n '1!p' | grep '<' | sed s@'< '@''@g`
  rm ${dir_dicom}/SUBS_hpc.txt ${dir_dicom}/SUBS_fw.txt

  if [ -z "$NewSubs" ]; then

    echo ""
    echo "⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  "
    echo "Everything is up-to-date for ${site}"
    echo "⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  "

  else  

    echo ""
    echo "⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡ "
    echo "${site} Has Newly Scanned Subjects: $NewSubs" 
    echo "⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡ "

###############################################
### Submit Jobs for Newly Detected Subjects ###
###############################################

    for subid in $NewSubs ; do

      JobName=`echo ${site}${subid}`
      job=`qstat -u $USER | grep ${JobName} | awk {'print $5'}`

      if [ "$job" == "r" ] || [ "$job" == "Rr" ] || [ "$job" == "Rq" ] || [ "$job" == "qw" ] ; then

        echo ''
        echo "############################################"
        echo "# ${JobName} is currently being processed..."
        echo "############################################"
        echo ''

      else

        echo ''
        echo "###############################################"
        echo "# ${JobName} IS BEING SUBMITTED FOR DOWNLOAD..."
        echo "###############################################"
        echo ''

        Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-Two/BIDs_Download.sh

        qsub -N ${JobName} ${Pipeline} ${subid} ${site} ${dir_dicom}
       fi
    done
  fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
