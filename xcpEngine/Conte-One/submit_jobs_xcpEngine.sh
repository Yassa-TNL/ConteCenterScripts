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

SEQ='task-REST task-HIPP task-AMG'

for seq in ${SEQ}; do 

  IMAGES=`ls -1d /dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One/fmriprep/sub-*/ses-*/func/sub-*_ses-*_${seq}_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz | head -n7`

  for scan in ${IMAGES} ; do

    sub=`echo $scan | cut -d '/' -f9 | cut -d '-' -f2`
    ses=`echo $scan | cut -d '/' -f10 | cut -d '-' -f2`
    xcpOutput=`echo /dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/${seq}/sub-${sub}/ses-${ses}/*/*.nii.gz`

    if [ -f ${xcpOutput} ] ; then

      echo ''
      echo "###########################################################################"
      echo "#sub-${sub} ses-${ses} already processed ${seq}                            "
      echo "###########################################################################"
      echo ''

    else

      job=`qstat -u $USER | grep `echo ${sub}"${seq:5:1}"${ses}` | awk {'print $5'}`

      if [ "$job" == "r" ] || [ "$job" == "Rr" ] || [ "$job" == "Rq" ] || [ "$job" == "qw" ] ; then

         echo ''
         echo "###########################################################################"
         echo "#sub-${sub} ses-${ses} currently processing ${seq}                         "
         echo "###########################################################################"
         echo ''

      else

         echo ''
         echo "###########################################################################"
         echo "# Submitting Job For sub-${sub} ses-${ses} seq-${seq}                      "
         echo "###########################################################################"
         echo ''

         JobName=`echo ${sub}"${seq:5:1}"${ses}`
         Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/Conte-One/xcpEngine_postproc_pipeline.sh
       
       qsub -N ${JobName} ${Pipeline} ${sub} ${ses} ${scan} ${xcpEngine_container}
      fi
    fi
  done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
