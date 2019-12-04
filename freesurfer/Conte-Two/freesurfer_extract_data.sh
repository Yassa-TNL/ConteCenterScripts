#!/bin/bash
###################################################################################################
##########################                 Conte-One                     ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This scripts aggregates the Freesurfer Data into Processed Spreadsheets that are ready for analysis.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load freesurfer/6.0

###################################################################
##### Define the Subjects-Level Directories & the Output Path #####
###################################################################

inputdir=/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-Two
outdir=/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-Two/T1w

#######################################################
##### Extract the Volume from Subcortical Regions #####
#######################################################

subjects=`echo ${inputdir}/*/stats/aseg.stats`
subjects=`echo $subjects | sed s@'/stats/aseg.stats'@''@g`
mkdir -p $outdir/FreeVol $outdir/FreeCT $outdir/FreeArea
rm ${outdir}/n*Aseg*.csv &> /dev/null

asegstats2table --subjects `echo $subjects` \
--common-segs \
--delimiter 'comma' \
--skip --meas volume \
--tablefile TEMP1_volume_ASEG.txt

TODAY=`date "+%Y%m%d"`
dim=`cat TEMP1_volume_ASEG.txt | wc -l`
((count = dim - 1))

cat TEMP1_volume_ASEG.txt | sed s@"Measure:volume"@"sub,ses"@g | sed s@"${inputdir}/"@""@g | sed s@"_tp"@","@g > ${outdir}/FreeVol/n${count}_Aseg_volume_${TODAY}.csv

chmod 775 ${outdir}/FreeVol/n${count}_Aseg_volume_${TODAY}.csv
rm TEMP1_volume_ASEG.txt

##############################################################
##### Extract Multiple Properities from Cortical Regions #####
##############################################################

extractions='volume thickness area'
for property in ${extractions} ; do

	hemispheres='lh rh'
	for hemi in $hemispheres ; do

		aparcstats2table --subjects `echo $subjects` \
			--skip --common-parcs \
			--delimiter 'comma' \
			--hemi ${hemi} \
			--parc aparc.a2009s \
			--meas ${property} \
			--tablefile raw1_Aparc-Destrieux_${hemi}_${property}.txt
			cat raw1_Aparc-Destrieux_${hemi}_${property}.txt | sed s@"${hemi}.aparc.a2009s.${property}"@"sub,ses"@g | \
			sed s@"${inputdir}/"@""@g | sed s@"_tp"@","@g > raw2_Aparc-Destrieux_${hemi}_${property}.txt

	done

######################################
##### Save the Final Output File #####
######################################

	TODAY=`date "+%Y%m%d"`
	dim=`cat raw2_Aparc-Destrieux_lh_${property}.txt | wc -l`
	((count = dim - 1))
	cut -d ',' -f1-2 --complement raw2_Aparc-Destrieux_lh_${property}.txt > raw2_Aparc-Destrieux_lh_${property}_REDUCED.txt
	paste --delimiters=',' raw2_Aparc-Destrieux_rh_${property}.txt raw2_Aparc-Destrieux_lh_${property}_REDUCED.txt > raw${count}_Aparc-Destrieux_${property}_${TODAY}.csv

#########################################################
##### Remove Extra Columns and Write out Speadsheet #####
#########################################################

	if [ $property = "volume" ]; then
		cut -d ',' -f55,56,57,116,117 --complement raw${count}_Aparc-Destrieux_${property}_${TODAY}.csv > ${outdir}/FreeVol/n${count}_Aparc-Destrieux_${property}_${TODAY}.csv
	fi

	if [ $property = "thickness" ]; then
		cut -d ',' -f56-57,58,118,119 --complement raw${count}_Aparc-Destrieux_${property}_${TODAY}.csv > ${outdir}/FreeCT/n${count}_Aparc-Destrieux_${property}_${TODAY}.csv
	fi

	if [ $property = "area" ]; then
		cut -d ',' -f56-57,58 --complement raw${count}_Aparc-Destrieux_${property}_${TODAY}.csv > ${outdir}/FreeArea/n${count}_Aparc-Destrieux_${property}_${TODAY}.csv
	fi

	chmod 775 ${outdir}/*/n${count}_Aparc-Destrieux_${property}_${TODAY}.csv
	rm raw*

done

############################################################
##### Merge Spreadsheets of Cortical Brain Properities #####
############################################################

subs_thickness=`cut -d ',' -f3-500 --complement ${outdir}/FreeCT/n${count}_Aparc-Destrieux_thickness_${TODAY}.csv`
subs_volume=`cut -d ',' -f3-500 --complement ${outdir}/FreeVol/n${count}_Aparc-Destrieux_volume_${TODAY}.csv`
subs_area=`cut -d ',' -f3-500 --complement ${outdir}/FreeArea/n${count}_Aparc-Destrieux_area_${TODAY}.csv`
subs_aseg=`cut -d ',' -f3-500 --complement ${outdir}/FreeVol/n${count}_Aseg_volume_${TODAY}.csv`

if [ "$subs_volume" = "$subs_thickness" ] && [ "$subs_thickness" = "$subs_area" ] && [ "$subs_area" = "$subs_aseg" ]; then

	echo 'All Cortical Files will be Merged Into Master Freesurfer Spreadsheets'

	awk -F"," 'BEGIN { OFS = "," } {$3="SubCortVol"; print}' ${outdir}/FreeVol/n${count}_Aseg_volume_${TODAY}.csv > ${outdir}/TEMP_SUBCORT_VOLUME_FINAL

	cut -d ',' -f1-2 --complement ${outdir}/FreeVol/n${count}_Aparc-Destrieux_volume_${TODAY}.csv > ${outdir}/TEMP_VOLUME
	awk -F"," 'BEGIN { OFS = "," } {$1="CortVol"; print}' ${outdir}/TEMP_VOLUME > ${outdir}/TEMP_VOLUME_FINAL

	cut -d ',' -f1-2 --complement ${outdir}/FreeArea/n${count}_Aparc-Destrieux_area_${TODAY}.csv > ${outdir}/TEMP_AREA
	awk -F"," 'BEGIN { OFS = "," } {$1="CortArea"; print}' ${outdir}/TEMP_AREA > ${outdir}/TEMP_AREA_FINAL

	cut -d ',' -f1-2 --complement ${outdir}/FreeCT/n${count}_Aparc-Destrieux_thickness_${TODAY}.csv > ${outdir}/TEMP_THICKNESS
	awk -F"," 'BEGIN { OFS = "," } {$1="CortCT"; print}' ${outdir}/TEMP_THICKNESS > ${outdir}/TEMP_THICKNESS_FINAL

	paste --delimiters=',' ${outdir}/FreeVol/n${count}_Aseg_volume_${TODAY}.csv ${outdir}/TEMP_VOLUME > ${outdir}/n${count}_APARC+ASEG_Volume_${TODAY}.csv
	paste --delimiters=',' ${outdir}/TEMP_SUBCORT_VOLUME_FINAL ${outdir}/TEMP_VOLUME_FINAL > ${outdir}/TEMP_CORTICAL1
	paste --delimiters=',' ${outdir}/TEMP_CORTICAL1 ${outdir}/TEMP_THICKNESS_FINAL > ${outdir}/TEMP_CORTICAL2 
	paste --delimiters=',' ${outdir}/TEMP_CORTICAL2 ${outdir}/TEMP_AREA_FINAL > ${outdir}/n${count}_APARC+ASEG_Master_${TODAY}.csv

	chmod 775 ${outdir}/n${count}_APARC+ASEG_Master_${TODAY}.csv
	chmod 775 ${outdir}/n${count}_APARC+ASEG_Volume_${TODAY}.csv
	rm ${outdir}/TEMP_*

else

	echo 'Uneven Number of Subjects Across Structural Properties - Will Not Merge' 

fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
