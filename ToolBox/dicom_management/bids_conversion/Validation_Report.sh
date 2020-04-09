#!/bin/bash
###########

DIR_LOCAL_BIDS=$1
DIR_LOCAL_AUDITS=$2
OPT_GUID_REPORT=$3

#########################################################
### Generate Report and Store Contents As A Text File ###
#########################################################

echo "Generating BIDs Validation Report"

TODAY=`date "+%Y%m%d"`
VERSION=`bids-validator -version`
mkdir -p ${DIR_LOCAL_AUDITS}/validation

bids-validator ${DIR_LOCAL_BIDS} > ${DIR_LOCAL_AUDITS}/validation/${TODAY}_Report_v${VERSION}.txt

chmod ug+wrx ${DIR_LOCAL_AUDITS}/validation/${TODAY}_Report_v${VERSION}.txt

#########################################################
### Generate Report and Store Contents As A Text File ###
#########################################################

if [[ $OPT_GUID_REPORT == TRUE && -f `echo ${DIR_LOCAL_AUDITS}/validation/guid_reference.txt` ]] ; then
	
	echo "Generating NDA Upload Report"
	GUID_REF=`ls -t ${DIR_LOCAL_AUDITS}/validation/guid_reference.txt`
	bids2nda ${DIR_LOCAL_BIDS} ${GUID_REF} ${DIR_LOCAL_AUDITS}/nda/
	
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
