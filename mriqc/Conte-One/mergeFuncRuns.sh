#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

Merges Those Func Scans with multiple Runs and Calculates the number of volumes per scan.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load fsl/5.0.9

#######################################################
### Show Number of Volumes Per Run that Was Reduced ###
#######################################################

images=`ls /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/*/*/func/*run*.nii.gz`
for i in $images ; do

  volumes=`fslinfo $i | grep ^dim4 | awk '{print $2}'`

  if [ "$volumes" == 150 ] ; then

    echo ''

  else

    echo '#######'
    echo $i
    echo $volumes
    echo '#######'

  fi
done

#################################################
### Merge Resting-State Runs Into Single File ###
#################################################

Rest_Ones=`echo $images | tr ' ' '\n' | grep _task-REST_run-01_bold.nii.gz`
for one in $Rest_Ones ; do

  two=`echo $one | sed s@'REST_run-01_bold'@'REST_run-02_bold'@g`
  output=`echo $one | sed s@'REST_run-01_bold'@'REST_bold'@g`
  fslmerge -t $output $one $two
  echo "Merged Niftis into $output"

  OLD_JSON=`echo $one | sed s@'task-REST_run-01_bold.nii.gz'@'task-REST_run-01_bold.json'@g`
  OLD_JSON2=`echo $one | sed s@'task-REST_run-01_bold.nii.gz'@'task-REST_run-02_bold.json'@g`
  NEW_JSON=`echo $OLD_JSON | sed s@'task-REST_run-01_bold.json'@'task-REST_bold.json'@g`
  cp $OLD_JSON $NEW_JSON
  echo "Made new Metadata File $NEW_JSON"

  rm $two $one $OLD_JSON $OLD_JSON2
  chmod ug+wrx $NEW_JSON $output
  echo "Removed Old Files and Changed Permissions"

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
