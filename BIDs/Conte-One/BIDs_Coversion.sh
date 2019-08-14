#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This scripts coverts the raw Conte Center 1.0 data into BIDs Format.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module purge
module load anaconda/2.7-4.3.1
module load flywheel/8.5.0
export PATH=$PATH:/dfs3/som/rao_col/bin
export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

###################################################
### Define Newly Found Subjects to be Converted ###
###################################################

subjects=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/*/DICOMS | tr ' ' '\n' | cut -d '/' -f8 | head -n1`

for subid in $subjects ; do

  echo 'Converting Dicoms to BIDs for '$subid
  sub=`echo $subid | cut -d '_' -f1`
  ses=`echo $subid | cut -d '_' -f3`
  Dicoms=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}/DICOMS
  Residual=/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/Spooling/${subid}
  mkdir -p $Residual

  dcm2bids -d $Dicoms -p ${sub} -s ${ses} -c \
  /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/config_Conte-One.json \
  -o ${Residual} --forceDcm2niix --clobber

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
