#!/bin/bash
###########

DIR_XNAT=$1
DIR_LOCAL_DICOMS=$2 
DIR_LOCAL_BIDS=$3
XNAT_API_TOKEN=$4 
OPT_SUB_EXCLUDE=$5

##############################################
### Define Data Stored Locally and on Xnat ###
##############################################

ls ${DIR_LOCAL_BIDS} | sed s@'sub-'@''@g | grep -v dataset > SUBS_LOCAL.txt
cat subjects | sed 's@","@\n@g' | grep label > SUBS_XNAT.txt
rm subjects

if [ ! -z `echo ${OPT_SUB_EXCLUDE} | cut -d ' ' -f1` ] ; then
	for EXCLUDE in $OPT_SUB_EXCLUDE ; do
		cat SUBS_XNAT.txt | grep -iv ${EXCLUDE} > SUBS_XNAT.txt_TEMP
		mv SUBS_XNAT.txt_TEMP SUBS_XNAT.txt
	done
fi

sort -t _ -k 1 -g SUBS_XNAT.txt > SUBS_XNAT.txt_TEMP
mv SUBS_XNAT.txt_TEMP SUBS_XNAT.txt

####################################################################
### Calculate Which Subjects Need To Be Downloaded From Flywheel ###
####################################################################

NEWSUBS=`diff SUBS_XNAT.txt SUBS_LOCAL.txt | grep '< ' | sed s@'< '@' '@g`
rm  SUBS_XNAT.txt SUBS_LOCAL.txt

if [ -z "$NEWSUBS" ]; then
	echo ""
	echo "No Newly Scanned Subjects Detected: BID Directory is Up-To-Date"
	echo ""
	exit 1
else
	echo ""
	echo 'Newly Scanned Subjects Detected: '$NEWSUBS | tr '\n' ' ' 
	echo ""
fi

###################################################
### Download the New Subjects' Dicoms from Xnat ###
###################################################

for SUBID in $NEWSUBS ; do

SubjectID=`echo $SUBID | cut -d 'x' -f1`

wget ${DIR_XNAT}/3440_${SubjectID}_${ValidateID}/experiments/${SubjectID}/*/*/*/*/files?format=zip \-O ${DIR_LOCAL_DICOMS}/${SUBID}/${SubjectID}.zip

unzip ${DIR_LOCAL_DICOMS}/${SUBID}/${SubjectID}.zip -d ${DIR_LOCAL_DICOMS}/${SUBID}/Dicoms

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
