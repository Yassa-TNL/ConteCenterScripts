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

fmriprep_rootdir='/dfs2/yassalab/rjirsara/ConteCenter/fmriprep/Conte-One'
All=`ls -1d1 ${fmriprep_rootdir}/fmriprep/sub-*/ses-*/func/sub-*_ses-*_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz | cut -d '/' -f9,10 | sed s@'sub-'@@g | sed s@'/ses-'@'_'@g | uniq`

for part in ${All} ; do

  sub=`echo $part | cut -d '_' -f1`
  ses=`echo $part | cut -d '_' -f2`
 /dfs2/yassalab/rjirsara/ConteCenter/xcpEngine/Conte-One/sub-${sub}


  if [ -f ${qa} ] && [ -f ${preproc} ] && [ -f ${html} ] ; then

    echo ''
    echo "########################################################"
    echo "#sub-${sub} already ran through the xcpEngine pipeline..."
    echo "########################################################"
    echo ''

  else

    job=`qstat -u $USER | grep FP${sub} | awk {'print $5'}`

    if [ "$job" == "r" ] || [ "$job" == "Rr" ] || [ "$job" == "Rq" ] || [ "$job" == "qw" ] ; then

       echo ''
       echo "###########################################"
       echo "#sub-${sub} is currently being processed..."
       echo "###########################################"
       echo ''

    else

       echo ''
       echo "##############################################"
       echo "#xcpEngine Job Being Submitted for sub-${sub}  "
       echo "##############################################"
       echo ''

       JobName=`echo FP${sub}`
       Pipeline=/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/xcpEngine/Conte-One/xcpEngine_preproc_pipeline.sh
       
       qsub -N ${JobName} ${Pipeline} ${sub} ${xcpEngine_container}
    fi
  fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
