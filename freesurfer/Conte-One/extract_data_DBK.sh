#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load freesurfer/6.0

###################################################################
##### Define the Subjects-Level Directories & the Output Path #####
###################################################################

inputdir=/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-One-DBK
outdir=/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One

#######################################
##### Extract the Cortical Values #####
#######################################

extractions='volume thickness area'
for property in ${extractions} ; do

  subjects=`echo ${inputdir}/*`
  rm ${outdir}/n*Aparc-Destrieux_*.csv &> /dev/null

  aparcstats2table --subjects `echo $subjects` --skip --common-parcs --delimiter 'comma' --hemi rh --parc aparc.a2009s --meas ${property} \
  --tablefile raw1_Aparc-Destrieux_rh_${property}.txt

  aparcstats2table --subjects `echo $subjects` --skip --common-parcs --delimiter 'comma' --hemi lh --parc aparc.a2009s --meas ${property} \
  --tablefile raw1_Aparc-Destrieux_lh_${property}.txt

##################################################
##### Prepare the Output File to be Analyzed #####
##################################################

  cat raw1_Aparc-Destrieux_rh_${property}.txt | sed s@"rh.aparc.a2009s.${property}"@"sub,ses"@g | sed s@"${inputdir}/"@""@g | \
  sed s@"_tp"@","@g > raw2_Aparc-Destrieux_rh_${property}.txt

  cat raw1_Aparc-Destrieux_lh_${property}.txt | sed s@"lh.aparc.a2009s.${property}"@"sub,ses"@g | sed s@"${inputdir}/"@""@g | \
  sed s@"_tp"@","@g > raw2_Aparc-Destrieux_lh_${property}.txt

######################################
##### Save the Final Output File #####
######################################

  TODAY=`date "+%Y%m%d"`
  dim=`cat raw2_Aparc-Destrieux_lh_${property}.txt | wc -l`
  ((count = dim - 1))

  paste --delimiters='' raw2_Aparc-Destrieux_rh_${property}.txt raw2_Aparc-Destrieux_lh_${property}.txt > raw${count}_Aparc-Destrieux_${property}_${TODAY}.csv
  
#########################################################
##### Remove Extra Columns and Write out Speadsheet #####
#########################################################

  if [ $property = "volume" ]; then
    cut -d ',' -f55,56,57,116,117 --complement raw${count}_Aparc-Destrieux_${property}_${TODAY}.csv > ${outdir}/n${count}_Aparc-Destrieux_${property}_${TODAY}.csv
  fi

  if [ $property = "thickness" ]; then
    cut -d ',' -f56-57,58,118,119 --complement raw${count}_Aparc-Destrieux_${property}_${TODAY}.csv > ${outdir}/n${count}_Aparc-Destrieux_${property}_${TODAY}.csv
  fi

  if [ $property = "area" ]; then
    cut -d ',' -f56-57,58 --complement raw${count}_Aparc-Destrieux_${property}_${TODAY}.csv > ${outdir}/n${count}_Aparc-Destrieux_${property}_${TODAY}.csv
  fi

  chmod 775 ${outdir}/n${count}_Aparc-Destrieux_${property}_${TODAY}.csv
  rm raw*

done

#########################################################
#####  #####
#########################################################

subjects=`echo ${inputdir}/*`
rm ${outdir}/n*Aseg*.csv &> /dev/null

asegstats2table --subjects `echo $subjects` --common-segs --delimiter 'comma' --skip --meas volume --tablefile TEMP_volume_ASEG.txt


############################################################
##### Merge Spreadsheets of Cortical Brain Properities #####
############################################################

subs_volume=`cut -d ',' -f3-500 --complement  ${outdir}/n${count}_Aparc-Destrieux_volume_${TODAY}.csv`
subs_thickness=`cut -d ',' -f3-500 --complement  ${outdir}/n${count}_Aparc-Destrieux_thickness_${TODAY}.csv`
subs_area=`cut -d ',' -f3-500 --complement  ${outdir}/n${count}_Aparc-Destrieux_area_${TODAY}.csv`

if [ "$subs_volume" = "$subs_thickness" ] && [ "$subs_thickness" = "$subs_area" ]; then

  echo 'Files will be Merge to Master Freesurfer Spreadsheet of Cortical Values' 
  
  cut -d ',' -f1-2 --complement  ${outdir}/n${count}_Aparc-Destrieux_thickness_${TODAY}.csv > ${outdir}/TEMP_THICKNESS
  cut -d ',' -f1-2 --complement  ${outdir}/n${count}_Aparc-Destrieux_area_${TODAY}.csv > ${outdir}/TEMP_AREA

  paste --delimiters=',' ${outdir}/n${count}_Aparc-Destrieux_volume_${TODAY}.csv ${outdir}/TEMP_THICKNESS > ${outdir}/TEMP_CORTICAL 
  paste --delimiters=',' ${outdir}/TEMP_CORTICAL  ${outdir}/TEMP_AREA > ${outdir}/n${count}_Aparc-Destrieux_cortex_${TODAY}.csv

  chmod 775 ${outdir}/n${count}_Aparc-Destrieux_cortex_${TODAY}.csv
  rm ${outdir}/TEMP_*

else

  echo 'Uneven number of Subjects Across Structural Properties - Will Not Merge' 

fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
