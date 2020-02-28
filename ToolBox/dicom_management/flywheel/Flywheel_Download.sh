#!/bin/bash
###########

DIR_FLYWHEEL=$1
DIR_LOCAL_DICOMS=$2 
DIR_LOCAL_BIDS=$3
FLYWHEEL_API_TOKEN=$4 
OPT_SUB_EXCLUDE=$5

fw login ${FLYWHEEL_API_TOKEN}

##################################################
### Define Data Stored Locally and on Flywheel ###
##################################################

ls ${DIR_LOCAL_BIDS} | sed s@'sub-'@''@g | grep -v dataset > SUBS_LOCAL.txt
fw ls ${DIR_FLYWHEEL} | sed s@'rw '@''@g | sed s@'admin '@''@g | sed s@'r '@''@g  > SUBS_FLYWHEEL.txt

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
	if [ ! -d ${DIR_LOCAL_DICOMS}/${DOUBLECHECK}/Dicoms ] ; then
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

for SUBID in ${NEWSUBJECTS[@]} ; do
	echo ""
	echo "Downloading Dicoms for $SUBID"
	mkdir -p ${DIR_LOCAL_DICOMS}/${SUBID}
	fw download ${DIR_FLYWHEEL}/${SUBID} --force \
		--output ${DIR_LOCAL_DICOMS}/${SUBID}/${SUBID}_fw_download.tar 
	tar -xvf ${DIR_LOCAL_DICOMS}/${SUBID}/${SUBID}_fw_download.tar -C ${DIR_LOCAL_DICOMS}/${SUBID}
	rm ${DIR_LOCAL_DICOMS}/${SUBID}/${SUBID}_fw_download.tar

	BehavFiles=`find ${DIR_LOCAL_DICOMS}/${SUBID} -name '*.txt' -o -name '*.csv' -o -name '*.tsv'`
	if [ ! -z $BehavFiles ] ; then 
		mkdir $DIR_LOCAL_DICOMS/${SUBID}/Events
		for FILE in $BehavFiles ; do
			mv $FILE $DIR_LOCAL_DICOMS/${SUBID}/Events
		done
	fi

	CompressedDicoms=`find ${DIR_LOCAL_DICOMS}/${SUBID} -name '*.dicom.zip'`
	for UNZIP in $CompressedDicoms ; do
		Sequence=`echo $UNZIP | rev | cut -d '/' -f2 | rev`
		DIR_OUTPUT=${DIR_LOCAL_DICOMS}/${SUBID}/Dicoms/${Sequence}
		mkdir -p ${DIR_OUTPUT}
		unzip $UNZIP -d	${DIR_OUTPUT}
		mv ${DIR_OUTPUT}/*/*.dcm ${DIR_OUTPUT}/
	done

	rmdir `find ${DIR_LOCAL_DICOMS}/${SUBID}/Dicoms -type d -empty`
	rm -rf `ls -d ${DIR_LOCAL_DICOMS}/${SUBID}/* | grep -v Dicoms | grep -v Events`

#########################################################
### Transfer Event Files to Subject-Level Directories ###
#########################################################

	if [ -f `echo ${DIR_LOCAL_DICOMS}/Events/*${SUBID}* | cut -d ' ' -f1` ] ; then	
		echo ""
		echo "Transfering Event Files for $SUBID"
		mkdir -p ${DIR_LOCAL_DICOMS}/${SUBID}/Events
		mv ${DIR_LOCAL_DICOMS}/Events/${SUBID}_* ${DIR_LOCAL_DICOMS}/${SUBID}/Events

		if [ -z "$(ls -A ${DIR_LOCAL_DICOMS}/Events)" ] ; then
			rmdir ${DIR_LOCAL_DICOMS}/Events	
		fi
		if [ -z "$(ls -A ${DIR_LOCAL_DICOMS}/${SUBID}/Events)" ] ; then
			rmdir ${DIR_LOCAL_DICOMS}/${SUBID}/Events	
		fi
	fi
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
