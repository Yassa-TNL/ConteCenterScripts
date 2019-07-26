#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This is the final script to audit the Dicoms and Par/Rec files across all databases where they were stored
in order to create a standardized and central location for them to be uploaded onto Flywheel

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

philips_dir=/Volumes/yassadata/ConteCenter/RawData/Philips
keators_dir=/Volumes/yassadata/ConteCenter/RawData/DICOM2
flywheel_dir=/Volumes/yassadata/ConteCenter/RawData/Flywheel

#####################################################################
### Create Variables Containing the Subjects within Each Database ###
#####################################################################

#Philip Scanner Database

philips_type1_subs=`ls ${philips_dir} | grep _0 | sed s@'_0'@'_'@g` #10
philips_type2_subs=`ls ${philips_dir} | grep MRI | grep -v C7 | sed s@'MRI'@''@g` #295
philips_other_subs=`ls ${philips_dir} | grep -v MRI | grep -v _0 | grep -v 7037_2_1` #21
philips_subs=`echo $philips_type1_subs $philips_type2_subs` #305

#Keator's Database

keators_subs=`ls ${keators_dir} | grep MRI | grep -v C7_MRI2 | grep -v _DTI | sed s@'MRI'@''@g` #301

#Flywheel Database

flywheel_subs=`ls ${flywheel_dir} | cut -d '_' -f2,3,4 | sed s@'_0'@'_'@g` #14

##################################################################
### Copy and Standardize DICOMs from Philips Scanner Database  ###
##################################################################

for sub in ${philips_subs}; do

  SUBID=`echo ${sub} | cut -d '_' -f1`
  SES_ALL=`echo ${sub} | cut -d '_' -f2`
  SES_MRI=`echo ${sub} | cut -d '_' -f3`

  if [ -d ${philips_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/[dD][iI][cC][oO][mM] ]; then

    echo ''
    echo 'Existing Dicoms Found for' ${SUBID}_${SES_ALL}_${SES_MRI}
    input_files=`find ${philips_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/[dD][iI][cC][oO][mM] -name '*.dcm'`
    output_dir=`echo /Volumes/yassadata/ConteCenter/RawData/Conte-One/${SUBID}_${SES_ALL}_${SES_MRI}/DICOMS`
    mkdir -p $output_dir

    for file in $input_files ; do
       cp -n $file $output_dir
    done

  else

    echo ''
    echo 'Dicoms NOT FOUND for' ${SUBID}_${SES_ALL}_${SES_MRI}
  
  fi
done

#Fix Subjects with Improper Dicom Labels

PROBLEMATIC_PHILIPS=`find /Volumes/yassadata/ConteCenter/RawData/Conte-One -empty | cut -d '/' -f7`
echo 'These subjects do not have properly labeled dicoms:' $PROBLEMATIC_PHILIPS

for sub in $PROBLEMATIC_PHILIPS; do

  SUBID=`echo ${sub} | cut -d '_' -f1`
  SES_ALL=`echo ${sub} | cut -d '_' -f2`
  SES_MRI=`echo ${sub} | cut -d '_' -f3`

  DICOMS_NEED_RELABEL=`ls ${philips_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/DICOM/*`
  echo ${SUBID}_${SES_ALL}_${SES_MRI}' needs their dicoms relabeled'

  for file in ${DICOMS_NEED_RELABEL} ; do    
    RENAMED=`echo ${file}'.dcm'`
    echo $file
    echo $RENAMED
    mv $file $RENAMED
  done
  
  input_files=`find ${philips_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/[dD][iI][cC][oO][mM] -name '*.dcm'`
  output_dir=`echo /Volumes/yassadata/ConteCenter/RawData/Conte-One/${SUBID}_${SES_ALL}_${SES_MRI}/DICOMS`
  for file in $input_files ; do
    cp -n $file $output_dir
  done
done

#########################################################################
### Copy and Standardize PAR/REC files from Philips Scanner Database  ###
#########################################################################

for sub in ${philips_subs}; do

  SUBID=`echo ${sub} | cut -d '_' -f1`
  SES_ALL=`echo ${sub} | cut -d '_' -f2`
  SES_MRI=`echo ${sub} | cut -d '_' -f3`

  if [ -d ${philips_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/[pP][aA][rR][rR][eE][cC] ]; then

    echo ''
    echo 'Existing PAR/REC Files Found for' ${SUBID}_${SES_ALL}_${SES_MRI}
    input_PAR_files=`find ${philips_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/[pP][aA][rR][rR][eE][cC] -name '*.PAR'`
    input_REC_files=`find ${philips_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/[pP][aA][rR][rR][eE][cC] -name '*.REC'`
    output_dir=`echo /Volumes/yassadata/ConteCenter/RawData/Conte-One/${SUBID}_${SES_ALL}_${SES_MRI}/PARREC`
    mkdir -p $output_dir

        for file in $input_PAR_files ; do
          cp -n $file $output_dir
        done

        for file in $input_REC_files ; do
          cp -n $file $output_dir
        done

  else

    echo ''
    echo 'Dicoms NOT FOUND for' ${SUBID}_${SES_ALL}_${SES_MRI}
  
  fi
done

#####################################################
### Copy and Standardize DICOMs from Keator's NAS ###
#####################################################

for sub in ${keators_subs}; do

  SUBID=`echo ${sub} | cut -d '_' -f1`
  SES_ALL=`echo ${sub} | cut -d '_' -f2`
  SES_MRI=`echo ${sub} | cut -d '_' -f3`
  directories=`echo SCANS DICOM`

 for dir in $directories ; do 

  if [ -e ${keators_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/${dir} ]; then

    echo ''
    echo 'Existing Dicoms Found for' ${SUBID}_${SES_ALL}_${SES_MRI}
    input_files=`find ${keators_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI} -name '*.dcm'`
    output_dir=`echo /Volumes/yassadata/ConteCenter/RawData/Conte-One/${SUBID}_${SES_ALL}_${SES_MRI}/DICOMS`
    mkdir -p $output_dir

        for file in $input_files ; do
          cp -n $file $output_dir
	  echo $file
	  echo $output_dir
        done

  else

    echo ''
    echo 'Dicoms NOT FOUND for' ${SUBID}_${SES_ALL}_${SES_MRI}_${dir}
  
  fi
 done
done

############################################################
### Copy and Standardize PAR/REC Files from Keator's NAS ###
############################################################

for sub in ${keators_subs}; do

  SUBID=`echo ${sub} | cut -d '_' -f1`
  SES_ALL=`echo ${sub} | cut -d '_' -f2`
  SES_MRI=`echo ${sub} | cut -d '_' -f3`

  if [ -e ${keators_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/PARREC ]; then

    echo ''
    echo 'Existing Dicoms Found for' ${SUBID}_${SES_ALL}_${SES_MRI}
    input_PAR_files=`find ${keators_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/PARREC -name '*.PAR'`
    input_REC_files=`find ${keators_dir}/${SUBID}_*${SES_ALL}_*${SES_MRI}/PARREC -name '*.REC'`
    output_dir=`echo /Volumes/yassadata/ConteCenter/RawData/Conte-One/${SUBID}_${SES_ALL}_${SES_MRI}/PARREC`
    mkdir -p $output_dir

        for file in $input_PAR_files ; do
          cp -n $file $output_dir
        done

        for file in $input_REC_files ; do
          cp -n $file $output_dir
        done

  else

    echo ''
    echo 'PARREC Files NOT FOUND for' ${SUBID}_${SES_ALL}_${SES_MRI}
  
  fi
done

#####################################################################
### Copy and Standardize PAR/REC Files from the Flywheel Database ###
#####################################################################

for sub in ${flywheel_subs}; do

  SUBID=`echo ${sub} | cut -d '_' -f1`
  SES_ALL=`echo ${sub} | cut -d '_' -f2`
  SES_MRI=`echo ${sub} | cut -d '_' -f3`

  output_dir=`echo /Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI}/COMPRESSED`
  mkdir -p $output_dir

  find /Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI} -name '*' | grep .zip | sed s@^@"'"@g | sed s@.zip@".zip'"@g > /Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI}/file.txt

  echo ''
  echo 'Now Moving Zip Files to Standard Location for Conte_'${SUBID}_0${SES_ALL}_0${SES_MRI}
  echo '' 

  cat /Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI}/file.txt | while read -r line ; do
    OLD=`printf '%s\n' "$line"`
    NEW=`echo $OLD | cut -d '/' -f10 | sed s@" "@"_"@g | sed s@"'"@""@g`
    echo $NEW
    command=`echo 'cp '$OLD ${output_dir}/$NEW`
    echo $command > /Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI}/commands.sh
    /Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI}/commands.sh
    echo ''
  done
  
  echo ''
  echo 'Now Extracting Zip Files for Conte_'${SUBID}_0${SES_ALL}_0${SES_MRI}
  echo '' 

  COMPRESSED_FILES=/Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI}/COMPRESSED/* 
  for comp in $COMPRESSED_FILES ; do
    tar -zxvf $comp -C /Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI}/COMPRESSED/
    rm -rf /Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI}/COMPRESSED/DEFAULT*
  done

  echo ''
  echo 'Now Moving Dicoms to Correct Directory_'${SUBID}_0${SES_ALL}_0${SES_MRI}
  echo '' 

  DICOMS=`find /Volumes/yassadata/ConteCenter/RawData/Flywheel/Conte_${SUBID}_0${SES_ALL}_0${SES_MRI}/COMPRESSED/ -type f | grep -v .zip`
  for dicom in $DICOMS ; do
    NEW=$(echo $dicom | cut -d '/' -f11).dcm
    OUTPUT=/Volumes/yassadata/ConteCenter/RawData/Conte-One/${SUBID}_${SES_ALL}_${SES_MRI}/DICOMS
    echo $dicom
    echo $NEW
    echo $OUTPUT
    echo ''
    mkdir -p $OUTPUT

    mv $dicom ${OUTPUT}/${NEW}
  done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
