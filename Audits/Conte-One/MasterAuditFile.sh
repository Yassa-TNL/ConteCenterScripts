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
google docs for all researchers to access.

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
rm ${dir_temp}/TEMP_MRI*
dos2unix ${FINAL_OUTPUT}
chmod ug+wrx $FINAL_OUTPUT

#######################################################################
### Add Columns Indicating if DICOMS/NIFTIS and PAR/REC Files Exist ###
#######################################################################

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},Dicoms/Niftis,PARREC`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

###DICOMS

rows=`cat ${FINAL_OUTPUT} | grep -v 'subid' | tr '\n' ' '`
for row in $rows ; do
  subid=`echo $row | cut -d ',' -f1`
  session=`echo $row | cut -d ',' -f2`

  dir_dicom=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${session}/DICOMS`
  dir_nifti=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${session}/NIFTIS`
  if [ -d "${dir_dicom}" ] || [ -d "${dir_nifti}" ] ; then
    echo 'Dicoms Detected For Subject '${subid}' and Session '${session}
    newrow=`echo ${row},1`
    cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
    mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
  else
    echo 'Dicoms Missing For Subject '${subid}' and Session '${session}
    newrow=`echo $row,0`
    cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
    mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
  fi
done

###PAR/REC 

rows=`cat ${FINAL_OUTPUT} | grep -v 'subid' | tr '\n' ' '`
for row in $rows ; do
  subid=`echo $row | cut -d ',' -f1`
  session=`echo $row | cut -d ',' -f2`

  dir_parrec=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${session}/PARREC`
  if [ -d "${dir_parrec}" ]; then
    echo 'PARREC Files Detected For Subject '${subid}' and Session '${session}
    newrow=`echo ${row},1`
    cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
    mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
  else
    echo 'PARREC Files Missing For Subject '${subid}' and Session '${session}
    newrow=`echo $row,0`
    cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g> ${FINAL_OUTPUT}_NEW
    mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
  fi
done
chmod ug+wrx ${FINAL_OUTPUT}

############################################################################
### Add Column of Scan Date Based on Dicom Headers to Varify Source File ###
############################################################################

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},FileDate`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

rows=`cat ${FINAL_OUTPUT} | grep -v 'subid' | tr '\n' ' '`
for row in $rows ; do
  subid=`echo $row | cut -d ',' -f1`
  session=`echo $row | cut -d ',' -f2`

  dir_dicom=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${session}/DICOMS`
  if [ -d "${dir_dicom}" ]; then
  	dcm=`ls /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${session}/DICOMS/*.dcm | head -n1`
  	header=`dicom_hdr ${dcm} | grep 'ID Study Date'`
    date=`echo ${header: -8}`
    newrow=`echo ${row},${date}`
    cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
    mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
    echo 'Scan Completed On '${date}' of Session '${session}' For Subject '${subid}
  else
    newrow=`echo $row,NA`
    cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
    mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
    echo 'DICOMS Missing For Subject '${subid}' and Session '${session}
  fi
done 

###########################################################
### Add column Auditing Nifti Files in BIDs Directories ###
###########################################################

AuditBIDsData(){
header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},${2}`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

rows=`cat ${FINAL_OUTPUT} | grep -v 'subid' | tr '\n' ' '`
for row in $rows ; do
  subid=`echo $row | cut -d ',' -f1`
  session=`echo $row | cut -d ',' -f2`
  file=`echo /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-${subid}/ses-${session}/${1}/*${2}*.nii.gz`
  file=`echo $file | cut -d ' ' -f1`

  if [ -f ${file} ] ; then
    newrow=`echo ${row},1`
    cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
    mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
    echo "${1}-${2} NIFTI Detected for Subject ${subid} Session ${session}"
  else
    val_dicom=`echo $row | cut -d ',' -f4`
    val_parrec=`echo $row | cut -d ',' -f5`
    val_ses=`echo $row | cut -d ',' -f2`
    if [[ $val_dicom -eq 0 ]] && [[ $val_parrec -eq 0 ]] || [[ $val_ses -eq 0 ]] ; then
      newrow=`echo ${row},NA`
      cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
      mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
      echo "${1}-${2} not expected for Subject ${subid} Session ${session}"
    else
      newrow=`echo ${row},0`
      cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
      mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
      echo "${1}-${2} missing for Subject ${subid} Session ${session}"
    fi
  fi
done
}

sequences='anat_T1w dwi_dwi func_REST func_HIPP func_AMG'
for seq in $sequences ; do
  folder=`echo $seq | cut -d '_' -f1`
  name=`echo $seq | cut -d '_' -f2`
  AuditBIDsData $folder $name
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################