#!/bin/bash
###########

PATH=$PATH:~/Settings ; source MyAPIs.sh
fw login $FLYWHEEL_API_TOKEN
TODAY=`date +"%Y%m%d"`

DIR_PROJECT=/dfs8/yassalab/ABCDS
FILE_MODIFY=/dfs8/yassalab/rjirsara/ConteCenterScripts/study-ABCDS/bids_modify.py
FILE_CONFIG=/dfs8/yassalab/rjirsara/ConteCenterScripts/study-ABCDS/bids_config.json

#####
### Download and Unpack Flywheel Data
#####

mkdir -p $DIR_PROJECT/downloads
fw ls yassalab/ABC-DS | grep -v files | awk '{print $2}' > $DIR_PROJECT/downloads/download_${TODAY}.csv
for SUBID in `cat $DIR_PROJECT/downloads/download_${TODAY}.csv`; do
	if [[ ! -d $DIR_PROJECT/downloads/${SUBID} ]] ; then 
		echo "Downloading Dicoms for ${SUBID}"
		fw download yassalab/ABC-DS/${SUBID} --output ${DIR_PROJECT}/downloads/${SUBID}/fw_download.tar -y
		tar -xvf ${DIR_PROJECT}/downloads/${SUBID}/fw_download.tar -C ${DIR_PROJECT}/downloads/${SUBID}
		rm ${DIR_PROJECT}/downloads/${SUBID}/fw_download.tar
		if [[ ! -z `find ${DIR_PROJECT}/downloads/${SUBID} -name '*.zip' | head -n1 | cut -d ' ' -f1` ]] ; then
			IFS=$'\n' ; OIFS="$IFS"
			for UNZIP in `find ${DIR_PROJECT}/downloads/${SUBID} -name '*.zip'` ; do
				SEQ=`echo $UNZIP | rev | cut -d '/' -f2 | rev`
				DIR_OUTPUT=${DIR_PROJECT}/downloads/${SUBID}/${SEQ}
				mkdir -p ${DIR_OUTPUT} ; unzip $UNZIP -d ${DIR_OUTPUT}
			done 
			rm -rf ${DIR_PROJECT}/downloads/${SUBID}/scitran
		fi
	fi
done

#####
### Convert Dicoms to BIDs Data & Modify MetaData
#####

for SUBID in `cat $DIR_PROJECT/downloads/download_${TODAY}.csv`; do
	if [[ ! -z `find ${DIR_PROJECT}/downloads/${SUBID} -name '*.dcm' | head -n1 | cut -d ' ' -f1` ]] ; then
		echo "Converting Dicoms to BIDs for `echo ${SUBID}`"
		chmod -R u+wrx ${DIR_PROJECT}/downloads/${SUBID}
		SUB=`echo $SUBID | sed s@'BDS'@''@g`
			-d ${DIR_PROJECT}/downloads/${SUBID} \
		dcm2bids \
			-p ${SUB} \
			-c ${FILE_CONFIG} \
			-o ${DIR_PROJECT}/bids \
			--force_dcm2bids \
			--clobber 
	fi
done 

rm -rf ${DIR_PROJECT}/bids/tmp_dcm2bids ${DIR_PROJECT}/bids/logs
python3 $FILE_MODIFY $DIR_PROJECT/bids

#####
### Account for Idiocracies
#####

#Remove Sessions Exclusively of PET Scans
for SUB in `echo $DIR_PROJECT/bids/sub-*` ; do
	if [[ ! -d `echo $SUB/anat` ]] ; then
		echo $SUB ; ls $SUB ; rm -rf $SUB
	fi
done

#Select the Last Run of the T1w Scans
for SUB in `echo $DIR_PROJECT/bids/sub-*` ; do
	for TYPE in `echo FLAIR T1w T2w` ; do
		if [[  `echo $SUB/anat/*run-*${TYPE}.nii.gz | wc -w` != 1 ]] ; then
			for LAST in `ls $SUB/anat/*${TYPE}* | tail -n2` ; do
				mv $LAST `echo $LAST | cut -d '_' -f1,3`
			done
			rm -rf ls $SUB/anat/sub-*_run-*${TYPE}*
		fi
	done
done

#Adjust MetaData Phase Directory for Consistency
for JSON in `find $DIR_PROJECT/bids | grep bold.json` ; do
	if [[ `cat $JSON | grep 'PhaseEncodingAxis' | wc -w ` > 0 ]] ; then
		echo "Editing Phase Direction for: `basename $JSON`"
		cat $JSON | sed s@'PhaseEncodingAxis'@'PhaseEncodingDirection'@g > ${JSON}_TEMP
		mv ${JSON}_TEMP $JSON
	fi
done

########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######