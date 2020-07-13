#!/bin/bash
###########

DIR_PROJECT=$1

#########################################################
### Generate Report and Store Contents As A Text File ###
#########################################################

echo "Generating BIDs Validation Report"
TODAY=`date "+%Y%m%d"`
VERSION=`bids-validator -version`
mkdir -p ${DIR_PROJECT}/audits/bids_validator
bids-validator ${DIR_PROJECT}/bids > ${DIR_PROJECT}/audits/bids_validator/${TODAY}_Report_v${VERSION}.txt
chmod ug+wrx ${DIR_PROJECT}/audits/bids_validator/${TODAY}_Report_v${VERSION}.txt

####################################################################
### If GUID Reference Exists Then Generate Report For NDA Upload ###
####################################################################

if [[ -f `echo ${DIR_PROJECT}/audits/nda_upload/guid_reference.txt` ]] ; then
	echo "Generating NDA Upload Report"
	GUID_REF=`ls -t ${DIR_PROJECT}/audits/nda_upload/guid_reference.txt`
	bids2nda ${DIR_PROJECT}/bids ${GUID_REF} ${DIR_PROJECT}/audits/nda_upload
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
