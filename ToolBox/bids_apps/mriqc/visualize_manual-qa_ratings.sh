#!/bin/bash
###########

FILE_INPUT_EXTENSION=T1w.nii.gz
DIR_INPUT_PATH=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/bids
FILE_OUTPUT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/apps/mriqc/ratings/n420_ManualQA_20120120.csv

module load fsl/6.0.1

#########################################################
##### Identified Scans That Failed MRIQC Processing #####
#########################################################

SCANS=`find ${DIR_INPUT_PATH} -iname *${FILE_INPUT_EXTENSION} -type f -printf "%f\n"`
if [ -f ${FILE_OUTPUT} ] ; then

	i=0
	for SCAN in $SCANS ; do
  		RATING=`cat ${FILE_OUTPUT} | grep ${SCAN} | cut -d ',' -f2`
		if [ -z ${RATING} ] ; then

			echo ""
			echo "########################################"
			echo "Manual QC Rating Needed For Scan: $SCAN "
			echo "########################################"
			MISSING[i]=$(echo $SCAN)
			(( i++ ))

		else

			echo ""
			echo "###################################################"
			echo "QC Report Existing For Scan: $SCAN Rating: $RATING "            
			echo "###################################################"
		fi
	done

else

	i=0
	echo ""
	echo "######################################################"
	echo "QC Report Does Not Exist Rating Will Start From Scatch"
	echo "######################################################"
	MISSING[i]=$(echo $SCANS)
	(( i++ ))
fi

echo "Starting Manual QA Process On These Scans: ${MISSING[@]}"

####################################################################
##### Compute Screenshots of Each Image That Needs a QA Rating #####
####################################################################

TODAY=`date "+%Y%m%d"`
echo "sub,ses,QARating,InputFile,TIMESTAMP:${TODAY}" >> $FILE_OUTPUT

for RATE in ${MISSING[@]} ; do
	OUTPUT=`dirname ${FILE_OUTPUT}`/`echo ${RATE} | sed s@".nii.gz"@".gif"@g`
	if [ ! -f $OUTPUT ] ; then

	echo "#######################################"
	echo "Computing Screenshots For Image: $RATE "
	echo "#######################################"
	slices `find ${DIR_INPUT_PATH} -name ${RATE}` -u -o ${OUTPUT}

	fi4
done

################################################
##### Create Log File to Track All Ratings #####
################################################

for RATE in ${MISSING[@]} ; do

	SUBID=`echo ${RATE} | cut -d '_' -f1 | cut -d '-' -f2`
	SES=`echo ${RATE} | cut -d '_' -f2 | cut -d '-' -f2`
	OUTPUT=`dirname ${FILE_OUTPUT}`/`echo ${RATE} | sed s@".nii.gz"@".gif"@g`
	display ${OUTPUT}
	echo "*********"$RATE"*********"
	echo "Enter Rating Options: 1-Exclude, 2-Poor, 3-Decent, 4-Great"
	select QUALITY in \
          "Exclude" \
	  "Poor" \
          "Decent" \
          "Great" 
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
              4) rating=4
                 break
                 ;;
              *) echo "Invalid option"
                 ;;
            esac
        done
	echo ${SUBID},${SES},${QUALITY},${RATE} >> $FILE_OUTPUT
        echo "Saving Your QA Rating for ${RATE} As ${QUALITY}"

done
chmod ug+wrx $FILE_OUTPUT

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
