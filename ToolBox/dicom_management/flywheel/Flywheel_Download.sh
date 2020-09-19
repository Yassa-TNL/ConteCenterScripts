#!/bin/bash
###########

DIR_FLYWHEEL=$1
DIR_PROJECT=$2
FLYWHEEL_API_TOKEN=$3 
OPT_SUB_EXCLUDE=$4

fw login ${FLYWHEEL_API_TOKEN}

##################################################
### Define Data Stored Locally and on Flywheel ###
##################################################

ls -l ${DIR_PROJECT}/bids | grep '^d' | awk '{print $9}' | sed s@'sub-'@@g > SUBS_LOCAL.txt
for UPLOAD in `fw ls ${DIR_FLYWHEEL} | awk {'print $2'}  | grep -v files` ; do
	fw ls ${DIR_FLYWHEEL}/${UPLOAD} | tr ' ' ',' | grep -v files > temp.txt
	if [ -s temp.txt ] ; then
		echo $UPLOAD >> SUBS_FLYWHEEL.txt
	fi
	rm temp.txt
done

if [ ! -z `echo ${OPT_SUB_EXCLUDE} | cut -d ' ' -f1` ] ; then
	for EXCLUDE in $OPT_SUB_EXCLUDE ; do
	cat SUBS_FLYWHEEL.txt | grep -iv ${EXCLUDE} > SUBS_FLYWHEEL.txt_TEMP
		mv SUBS_FLYWHEEL.txt_TEMP SUBS_FLYWHEEL.txt
	done
fi

NEWSUBS=`diff SUBS_FLYWHEEL.txt SUBS_LOCAL.txt | grep '< ' | sed s@'< '@' '@g`
rm  SUBS_FLYWHEEL.txt SUBS_LOCAL.txt

n=0
for DOUBLECHECK in $NEWSUBS ; do
	if [ ! -d ${DIR_PROJECT}/dicoms/${DOUBLECHECK}/dicoms ] ; then
		NEWSUBJECTS[n]=$DOUBLECHECK
		(( n++ ))
	fi
done

####################################################################
### Calculate Which Subjects Need To Be Downloaded From Flywheel ###
####################################################################

if [ -z `echo "${NEWSUBJECTS[@]}" | cut -d ' ' -f1` ]; then
	echo ""
	echo "No Newly Scanned Subjects Detected: BID Directory is Up-To-Date"
	echo ""
	exit 1
else
	echo ""
	echo 'Newly Scanned Subjects Detected: '${NEWSUBJECTS[@]} | tr '\n' ' ' 
	echo ""
fi

#############################################################
### Download and Unpack Data For Each Newly Found Subject ###
#############################################################

INDEX=0
for SUBID in `echo ${NEWSUBJECTS[@]} | sed s@'sub-'@''@g`; do
	echo ""
	echo "Downloading Dicoms for $SUBID"
	INDEX=$(($INDEX+1)) ; FWID=`echo ${NEWSUBJECTS[@]} | cut -d ' ' -f${INDEX}`
	mkdir -p ${DIR_PROJECT}/sub-${SUBID}
	fw download ${DIR_FLYWHEEL}/${FWID} --output ${DIR_PROJECT}/sub-${SUBID}/${SUBID}_fw_download.tar -y
	tar -xvf ${DIR_PROJECT}/sub-${SUBID}/${SUBID}_fw_download.tar -C ${DIR_PROJECT}/sub-${SUBID} 
	rm ${DIR_PROJECT}/sub-${SUBID}/${SUBID}_fw_download.tar

	BEHAVEFILES=`find ${DIR_PROJECT}/sub-${SUBID} -name '*.txt' -o -name '*.csv' -o -name '*.tsv' -name '*.xls*'`
	if [ ! -z `echo $BEHAVEFILES | cut -d ' ' -f1` ] ; then 
		mkdir ${DIR_PROJECT}/sub-${SUBID}/events
		for FILE in $BEHAVEFILES ; do
			mv $FILE ${DIR_PROJECT}/sub-${SUBID}/Events
		done
	fi

	if [[  ! -z `find ${DIR_PROJECT}/sub-${SUBID} -name '*.zip' | head -n1 | cut -d ' ' -f1` ]] ; then
		IFS=$'\n' ; OIFS="$IFS"
		for UNZIP in `find ${DIR_PROJECT}/sub-${SUBID} -name '*.zip'` ; do
			SEQ=`echo $UNZIP | rev | cut -d '/' -f2 | rev`
			DIR_OUTPUT=${DIR_PROJECT}/sub-${SUBID}/dicoms/${SEQ}
			mkdir -p ${DIR_OUTPUT} ; unzip $UNZIP -d ${DIR_OUTPUT}
			mv ${DIR_OUTPUT}/*/*.dcm ${DIR_OUTPUT}/
		done
		rm -rf `ls -d ${DIR_PROJECT}/sub-${SUBID}/* | tr ' ' '\n' | grep -v dicoms$ | grep -v events$`
	else
		for FILE in `find ${DIR_PROJECT}/sub-${SUBID}` ; do
			RESTRUCT=`echo $FILE | sed s@"${DIR_FLYWHEEL}/"@","@g | cut -d ',' -f2`
			mv $FILE $DIR_PROJECT/sub-${SUBID}/$RESTRUCT > /dev/null 2>&1
		done
	fi
	rmdir `find ${DIR_PROJECT} -type d -empty`

#########################################################
### Transfer Event Files to Subject-Level Directories ###
#########################################################

	if [ -f `echo ${DIR_PROJECT}/events/*${SUBID}* | cut -d ' ' -f1` ] ; then	
		echo ""
		echo "Transfering Event Files for $SUBID"
		mkdir -p ${DIR_PROJECT}/sub-${SUBID}/events
		mv ${DIR_PROJECT}/events/${SUBID}_* ${DIR_PROJECT}/sub-${SUBID}/events
		if [ -z "$(ls -A ${DIR_PROJECT}/dicoms/events)" ] ; then
			rmdir ${DIR_PROJECT}/dicoms/events	
		fi
		if [ -z "$(ls -A ${DIR_PROJECT}/sub-${SUBID}/events)" ] ; then
			rmdir ${DIR_PROJECT}/sub-${SUBID}/events	
		fi
	fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
