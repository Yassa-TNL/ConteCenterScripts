#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

############################################################################
### Read in Subjects that exist on the Zion Database and Define Log File ###
############################################################################

zion_one=`cat /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/DICOMS1_Zion.txt | grep _MRI | grep -v C7_MRI2`
zion_two=`cat /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/DICOMS2_Zion.txt | sed s@'823_1_MRI_1'@'823_1_MRI1'@g | grep MRI | grep -v C7_MRI2`
zion_combined=`echo $zion_one $zion_two`

logs_file=`echo /dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/logs/New_Dicoms_Zion.csv`
echo SUBID,MRI_VISIT > $logs_file 

############################################################
### Look for New Subjects in the first Directory on Zion ###
############################################################

for sub in $zion_combined ; do 

  SUBID=`echo $sub | cut -d '/' -f8 | cut -d '_' -f1`
  MRI_VISIT=`echo $sub | cut -d '/' -f8 | cut -d '_' -f3 | sed s@'MRI'@''@g`
  DIRECTORY=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/sub-${SUBID}/ses-${MRI_VISIT}`

    if [ -d "$DIRECTORY" ]; then

    echo ''
    echo $SUBID' Already Has Dicoms Reconstructued For Session Number '$MRI_VISIT
    echo ''

    else

    echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    echo 'NEW DICOMS FOUND FOR '$SUBID' SESSION NUMBER '$MRI_VISIT
    echo $SUBID,$MRI_VISIT >> $logs_file
    echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    
    fi
done

chmod ug+wrx $logs_file

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
