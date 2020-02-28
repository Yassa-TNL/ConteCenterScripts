#!/bin/bash
###########

DIR_LOCAL_DICOMS=$1
DIR_FLYWHEEL=$2 
DIRNAMExTYPE=$3
FLYWHEEL_API_TOKEN=$4

fw login ${FLYWHEEL_API_TOKEN}

##########################################################
### Upload Newly Found RawFiles to Flywheel for BackUp ###
##########################################################

for SUBID in `ls $DIR_LOCAL_DICOMS` ; do

	echo "Now Working with ${SUBID}"
	for INPUT in $DIRNAMExTYPE ; do

		DIRNAME=`echo $INPUT | cut -d 'x' -f1`
		TYPE=`echo $INPUT | cut -d 'x' -f2`
		UPLOAD=`find ${DIR_LOCAL_DICOMS}/${SUBID} -iname ${DIRNAME}`

		if [[ -z $UPLOAD || -z "$(ls -A $UPLOAD )" ]] ; then			
			break
		elif [[ $TYPE != "dicom" && $TYPE != "parrec" && $TYPE != "folder" ]] ; then
			echo "Skipping Upload For $DIRNAME"
			echo "Type of Data Not Formatted Correctly"
			echo "Possible Data Types: dicom, parrec, or folder"
			break
		fi

		LAB=`echo $DIR_FLYWHEEL | cut -d '/' -f1`
		PROJECT=`echo $DIR_FLYWHEEL | cut -d '/' -f2`

		if [ $TYPE = "dicom" ]; then
			echo "Dicoms Uploading for $SUBID"
			./Upload_dicoms.exp $UPLOAD $LAB $PROJECT $SUBID
		elif [ $TYPE = "parrec" ]; then
			echo "ParRec Upload for $SUBID"
			DATE=`fw ls "$DIR_FLYWHEEL/$SUBID" | head -n1 | awk {'print $5,$6'}`
			./Upload_parrecs.exp $UPLOAD $LAB $PROJECT $SUBID "$DATE"
		elif [ $TYPE = "folder" ]; then
			echo "Folder Upload for $SUBID"
			./Upload_folders.exp $UPLOAD $LAB $PROJECT
		fi

	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
