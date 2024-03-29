#!/bin/bash
###########

DIR_PROJECT=$1
OPT_GUID_FILE=$2

#########################################################
### Generate Report and Store Contents As A Text File ###
#########################################################

echo "Generating BIDs Validation Report"
TODAY=`date "+%Y%m%d"` ; VERSION=`bids-validator -version`
OUTPUT_DIR=$DIR_PROJECT/audits ; mkdir -p ${OUTPUT_DIR}
bids-validator ${DIR_PROJECT}/bids > ${OUTPUT_DIR}/${TODAY}_Report_v${VERSION}.txt
chmod ug+wrx ${OUTPUT_DIR}/${TODAY}_Report_v${VERSION}.txt

####################################################################
### If GUID Reference Exists Then Generate Report For NDA Upload ###
####################################################################

if [[ ! -f ${DIR_PROJECT}/bids/participants.tsv ]] ; then
	echo participant_id,age,sex | tr ',' '\t' > ${DIR_PROJECT}/bids/participants.tsv
	for DIR in `ls ${DIR_PROJECT}/bids | grep sub-` ; do
		echo $DIR,99,M | tr ',' '\t' >> ${DIR_PROJECT}/bids/participants.tsv
	done
fi

for DIR in `echo ${DIR_PROJECT}/bids/* | tr ' ' '\n' | grep sub-` ; do
	if [[ ! -f `find $DIR -name *_scans.tsv` ]] ; then
		SUB=$(basename `find $DIR | tail -n1` | cut -d '_' -f1 | cut -d '-' -f2)
		SES=$(basename `find $DIR | tail -n1` | cut -d '_' -f2 | cut -d '-' -f2)
		OUT=$(echo $DIR_PROJECT/bids/sub-${SUB}/ses-${SES}/sub-${SUB}_ses-${SES}_scans.tsv)
		echo filename,acq_time,systolic_blood_pressure | tr ',' '\t' > $OUT
		for SCAN in `find $DIR -iname *.nii.gz | sed s@"${DIR_PROJECT}/bids/sub-${SUB}/ses-${SES}"@''@g` ; do
			echo ${SCAN},2009-06-15T13:45:30,NaN | tr ',' '\t' >> ${OUT}
		done
		chmod ug+wrx ${OUT}
	fi
done

if [[ -f ${OPT_GUID_FILE} ]] ; then
	echo "Generating NDA Upload Report"
	bids2nda ${DIR_PROJECT}/bids ${OPT_GUID_FILE} ${OUTPUT_DIR}
	chmod -R ug+rwx ${OUTPUT_DIR}
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
