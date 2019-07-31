#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script created a Master Spreadsheet to track the data from Conte-One. Additional Columns will be 
added as processed data is generated. A copy of the master spreadsheet will be regularily updated on 
google docs for all researchers to access

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load afni/v19.0.01

##############################################################
### Tranform the Source File So Each Row is an MRI Session ###
##############################################################

source=/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/ConteMRI_All_Timepoints_Original.csv
dir_temp=/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/logs

awk -F "\"*,\"*" '{print $1,$5,$6}' $source > ${dir_temp}/TEMP_MRI0
awk -F "\"*,\"*" '{print $1,$7,$8}' $source > ${dir_temp}/TEMP_MRI1
awk -F "\"*,\"*" '{print $1,$9,$10}' $source > ${dir_temp}/TEMP_MRI2
awk -F "\"*,\"*" '{print $1,$11,$12}' $source > ${dir_temp}/TEMP_MRI3

sed -i '1d' ls ${dir_temp}/TEMP_MRI[0.1.2.3]
tempfiles=`ls ${dir_temp}/TEMP_MRI[0.1.2.3]`


for ExpectedSessions in $tempfiles ; do
  cat $ExpectedSessions | grep -v ' 0 ' > ${ExpectedSessions}_Reduced.txt
done

for sesnum in {0..3} ; do
  sed s@" 1 "@",${sesnum},"@g ${dir_temp}/TEMP_MRI${sesnum}_Reduced.txt > ${dir_temp}/TEMP_MRI${sesnum}_Reduced_Relabeled.txt
done

cat ${dir_temp}/TEMP_MRI{0..3}_Reduced_Relabeled.txt > ${dir_temp}/TEMP_MRI_Master_Audit.txt

FINAL_OUTPUT=/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/Audit_Master_ConteMRI.csv

echo 'subid,Session,ScanDate' > ${FINAL_OUTPUT}
cat ${dir_temp}/TEMP_MRI_Master_Audit.txt >> ${FINAL_OUTPUT}
echo '564,3,NA' >> ${FINAL_OUTPUT}
sort -k1 -t ',' -g ${FINAL_OUTPUT} -o  ${FINAL_OUTPUT}
chmod ug+wrx $FINAL_OUTPUT

rm ${dir_temp}/TEMP_MRI*

##############################################################
### Tranform the Source File So Each Row is an MRI Session ###
##############################################################

cat 













