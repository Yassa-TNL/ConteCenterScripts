#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

Audits MRI scans that did not successful pass through the MRIQC problem due to problems with the raw
acquistion files (PAR/REC & DICOMs).

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load fsl/6.0.1

#########################################################
##### Identified Scans That Failed MRIQC Processing #####
#########################################################

AllScans=`ls -d1 /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-*/ses-*/*/* | grep -v dwi | grep .nii.gz | cut -d '/' -f11`

i=0
for scan in $AllScans ; do
 
  sub=`echo $scan | cut -d '-' -f2 | cut -d '_' -f1`
  ses=`echo $scan | cut -d '-' -f3 | cut -d '_' -f1`
  mriqc_name=`echo $scan | sed s@".nii.gz"@".html"@g`
  mriqc_fullpath=/dfs2/yassalab/rjirsara/ConteCenter/mriqc/Conte-One/sub-${sub}/${mriqc_name}
  
  if [ -f ${mriqc_fullpath} ] ; then
    
    echo ""
    echo "################################"
    echo "QC Report Existing for MRI scan:" $scan             
    echo "################################"
    echo ""

  else

    echo ""
    echo "#####################"
    echo "Manual QC Needed For:" $scan
    echo "#####################"
    echo ""

    troubleshoot[i]=$(echo $scan)

    (( i++ ))

  fi
done

###########################################
##### Create Log File of Failed Scans #####
###########################################

outfile=/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/logs/MRIQC_Troubleshoot_Failures.csv
echo "RawFile,Decision" >> $outfile

for failed in ${troubleshoot[@]} ; do
      
	echo "*********"$failed"*********"

fslview_deprecated /dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/sub-*/ses-*/*/${failed}
	echo "Enter Rating Options: 1-Missing, 2-Problematic, 3-Good,"
	select rating in \
          "Missing" \
	  "Problematic" \
          "Good" 
          do
            case "${REPLY}" in
	      1) rating=1
                 break
                 ;;
              2) rating=2
                 break
                 ;;
              3) rating=3
                 break
                 ;;
              *) echo "Invalid option"
                 ;;
            esac
        done
	echo ${failed},$rating >> $outfile
        echo 'Saving your rating for '${failed}
done

chmod ug+wrx $outfile

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
