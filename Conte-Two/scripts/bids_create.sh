#!/bin/bash
###########

PATH=$PATH:~/Settings ; source MyAPIs.sh
fw login $FLYWHEEL_API_TOKEN
TODAY=`date +"%Y%m%d"`

DIR_PROJECT=/dfs9/yassalab/CONTE2
FILE_MODIFY=/dfs9/yassalab/rjirsara/ConteCenterScripts/study-CONTE2/bids_modify.py
FILE_CONFIG=/dfs9/yassalab/rjirsara/ConteCenterScripts/study-CONTE2/bids_config.json 

######
### Define Data to be Downloaded
######

for PROJECT in `echo Conte-Two-UCI Conte-Two-UCSD Conte-Two-P2` ; do
	LABEL=`basename $PROJECT`
	DIR_FLYWHEEL=`echo yassalab/$LABEL`
	fw ls ${DIR_FLYWHEEL} | grep -v files | awk '{print $2}' > ${LABEL}.txt
	for EXCLUDE in `echo training test final analyses` ; do
		cat ${LABEL}.txt | grep -iv ${EXCLUDE} > ${LABEL}.TEMP
		mv ${LABEL}.TEMP ${LABEL}.txt
	done
	sed "s|$|,$DIR_FLYWHEEL|" ${LABEL}.txt > ${LABEL}.TEMP ; mv ${LABEL}.TEMP ${LABEL}.txt
done ; cat *.txt | sed s@'yassalab/Conte-Two-'@@g | sort > $DIR_PROJECT/downloads/download_${TODAY}.csv ; rm *.txt 

#####
### Download and Unpack Flywheel Data
#####

for ROW in `cat $DIR_PROJECT/downloads/download_${TODAY}.csv`; do
SUBID=`echo $ROW | cut -d ',' -f1`
PROJID=`echo $ROW | cut -d ',' -f2`
DIR_FLYWHEEL=`echo yassalab/Conte-Two-$PROJID`
if [[ ! -d $DIR_PROJECT/downloads/${SUBID}x${PROJID} ]] ; then 
echo "Downloading Dicoms for ${SUBID}x${PROJID}"
		fw download ${DIR_FLYWHEEL}/${SUBID} --output ${DIR_PROJECT}/downloads/${SUBID}x${PROJID}/fw_download.tar -y
		tar -xvf ${DIR_PROJECT}/downloads/${SUBID}x${PROJID}/fw_download.tar -C ${DIR_PROJECT}/downloads/${SUBID}x${PROJID}
		rm ${DIR_PROJECT}/downloads/${SUBID}x${PROJID}/fw_download.tar
		if [[ ! -z `find ${DIR_PROJECT}/downloads/${SUBID}x${PROJID} -name '*.zip' | head -n1 | cut -d ' ' -f1` ]] ; then
			IFS=$'\n' ; OIFS="$IFS"
			for UNZIP in `find ${DIR_PROJECT}/downloads/${SUBID}x${PROJID} -name '*.zip'` ; do
				SEQ=`echo $UNZIP | rev | cut -d '/' -f2 | rev`
				DIR_OUTPUT=${DIR_PROJECT}/downloads/${SUBID}x${PROJID}/${SEQ}
				mkdir -p ${DIR_OUTPUT} ; unzip $UNZIP -d ${DIR_OUTPUT}
				mv `find ${DIR_OUTPUT} | grep '.dcm'` ${DIR_OUTPUT}/
			done 
			rm -rf ${DIR_PROJECT}/downloads/${SUBID}x${PROJID}/scitran
			rm -rf ${DIR_PROJECT}/downloads/${SUBID}x${PROJID}/*ignore*
			rm -rf ${DIR_PROJECT}/downloads/${SUBID}x${PROJID}/*Localizer*
		fi
	fi
done ; find ${DIR_PROJECT} -type d -empty -delete

#####
### Define New Batch of Scans To Download
#####

for ROW in `cat $DIR_PROJECT/downloads/download_${TODAY}.csv` ; do
	SUBID=`echo $ROW | cut -d ',' -f1 | sed s@sub-@@g`
	PROJID=`echo $ROW | cut -d ',' -f2`
	LABEL=`echo sub-${SUBID}x${PROJID}`
	if [[ ! -d $DIR_PROJECT/bids/$LABEL ]] ; then
		echo $ROW >> $DIR_PROJECT/downloads/download_batch_${TODAY}.csv
	fi
done

#####
### Convert Dicoms to BIDs Data
#####

###Bidsify UCI Sessions
for ROW in `cat $DIR_PROJECT/downloads/download_batch_${TODAY}.csv | grep -v UCSD`; do
	SUBID=`echo $ROW | cut -d ',' -f1` ; PROJID=`echo $ROW | cut -d ',' -f2`
	if [[ ! -z `find ${DIR_PROJECT}/downloads/${SUBID}x${PROJID} -name '*.dcm' | head -n1 | cut -d ' ' -f1` ]] ; then
		echo "Downloading Dicoms to BIDs for `echo ${SUBID}x${PROJID}`"
		chmod -R u+wrx ${DIR_PROJECT}/downloads/${SUBID}x${PROJID}
		mkdir -p ${DIR_PROJECT}/downloads/bids
		dcm2bids \
			-d ${DIR_PROJECT}/downloads/${SUBID}x${PROJID} \
			-p ${SUBID}x${PROJID} \
			-c ${FILE_CONFIG} \
			-o ${DIR_PROJECT}/downloads/bids \
			--force_dcm2bids \
			--clobber 
	fi
done

###Bidsify UCSD Sessions
for ROW in `cat $DIR_PROJECT/downloads/download_batch_${TODAY}.csv | grep UCSD`; do
	SUBID=`echo $ROW | cut -d ',' -f1` ; PROJID=`echo $ROW | cut -d ',' -f2`
	ROOTDIR=`echo /dfs9/yassalab/CONTE2/downloads/bids/${SUBID}x${PROJID}`
	if [ ! -d  ${ROOTDIR} ] ; then 
		echo "Bidsifying ${SUBID}x${PROJID}"
		EVENT=`find /dfs9/yassalab/CONTE2/downloads/${SUBID}x${PROJID} | grep .txt`
		rm `find /dfs9/yassalab/CONTE2/downloads/${SUBID}x${PROJID} | grep .mat`
		if [ ! -z $EVENT ] ; then
			mkdir -p $ROOTDIR/func
			mv $EVENT $ROOTDIR/func/${SUBID}_task-bandit_events.tsv
		fi
		for FILE in `find /dfs9/yassalab/CONTE2/downloads/${SUBID}x${PROJID} -type f` ; do
			LABEL=`echo $FILE  | rev | cut -d '/' -f1,2 | rev | sed s@'_ses-UCSD_'@'xUCSD_'@g`
			LABEL=`echo $LABEL | sed s@'Bandit'@'bandit'@g | sed s@'REST'@'rest'@g`
			LABEL=`echo $LABEL | sed s@'_DTI_'@'_acq-'@g`
			mkdir -p `dirname $ROOTDIR/$LABEL` 
			cp $FILE $ROOTDIR/$LABEL
		done
	fi
done

###Reformat Multi-Session Labels
for DUPLICATE in `echo $DIR_PROJECT/downloads/bids/*-1x*` ; do
	FIRST=`echo $DUPLICATE | sed s@'-1x'@'x'@g`
	for F in `find $FIRST -type f` ; do
		NEW=`echo $F | sed s@xUCSD@AxUCSD@g`
		mkdir -p `dirname $NEW`
		mv $F $NEW
	done 
	for F in `find $DUPLICATE -type f` ; do
		NEW=`echo $F | sed s@'-1x'@'Bx'@g`
		mkdir -p `dirname $NEW`
		mv $F $NEW
	done 
done ; find $DIR_PROJECT/downloads/bids -empty -delete

###Remove Sessions with Missing T1-weighted Scans
for SUB in `echo sub-1021xP2 sub-1076xP2 sub-1120xP2 sub-1133xP2 sub-1162xP2 sub-1201xP2 sub-1276xUCSD sub-1092xP2 sub-1120xP2` ; do
	rm -rf /dfs9/yassalab/CONTE2/downloads/bids/$SUB
done

###Edit: MetaData & Standardize Dataset
python3 $FILE_MODIFY $DIR_PROJECT/downloads/bids TRUE TRUE FALSE
for SUB in `echo $DIR_PROJECT/downloads/bids/sub-*` ; do
	for FILE in `find $SUB | grep fmap | grep dwi` ; do
		NEW=`echo $FILE | sed s@'/fmap/'@'/dwi/'@g`
		mv $FILE $NEW
	done
done ; find . -empty -delete

###Edit: Expand SliceTiming Information for UCSD
for SUBDIR in `echo $DIR_PROJECT/downloads/bids/*UCSD | tr ' ' '\n'` ; do
	for FUNC in `find $SUBDIR  | grep func | grep .json` ; do
		VALUES=`jq '.SliceTiming' $FUNC`
		TIMES=`echo $VALUES | tr ' ' '\n' | grep -E '[0-9]'`
		SLTIMES=`echo [ $TIMES, $TIMES, $TIMES, $TIMES, $TIMES, $TIMES, $TIMES, $TIMES ]`
		jq ".SliceTiming |= $SLTIMES" $FUNC > ${FUNC}_TEMP
		mv ${FUNC}_TEMP ${FUNC}
	done 
done

###Edit: Ensure UCSD NIFTIs are Compressed
for NIFTI in `find . | grep .nii.gz` ; do
TYPE=`file $NIFTI  | tr ' ' '\n' | grep "compressed"`
if [[ $TYPE != "compressed" ]] ; then
rNIFTI=`echo $NIFTI | sed s@'.nii.gz'@'.nii'@g` 
mv $NIFTI $rNIFTI
gzip $rNIFTI
echo $NIFTI
fi
done

###Edit: Relabel UCSD Sessions named REDO
for FILE in `find $DIR_PROJECT/downloads/bids/* | grep -i "REDO"` ; do
	NEW_FILE=`echo $FILE | sed s@'_REDO_'@'_'@g`
	if [ ! -z `basename $FILE | grep '_dir-' | grep json` ] ; then
		cat $FILE | sed s@'_REDO_'@'_'@g > $NEW_FILE ; rm $FILE
	else
		mv $FILE $NEW_FILE
	fi
done

###Remove Extra T1-weighted Scans
for SUBDIR in `find $DIR_PROJECT/downloads/bids -maxdepth 1 | grep 'sub-'` ; do
	if [ `find $SUBDIR | grep T1w.nii.gz | wc -l` != 1 ] ; then
		SCAN=`find $SUBDIR | grep T1w.nii.gz | tail -n1`
		JSON=`find $SUBDIR | grep T1w.json | tail -n1`
		SUBID=`basename $SUBDIR`
		mv $JSON $SUBDIR/anat/${SUBID}_T1w.json
		mv $SCAN $SUBDIR/anat/${SUBID}_T1w.nii.gz
		rm -rf `find $SUBDIR/anat | grep run`
	fi
done

###Move BIDs Directory
mkdir -p /dfs9/yassalab/CONTE2/bids
mv $DIR_PROJECT/downloads/bids/sub* /dfs9/yassalab/CONTE2/bids

#Create Event Files
EVENTDIR=$DIR_PROJECT/downloads/taskevents_preproc
for SCAN in `find $DIR_PROJECT/bids | grep task-bandit | grep bold.nii.gz` ; do
	SUBID=`basename $SCAN | cut -d '_' -f1`
	RUNNUM=`basename $SCAN | cut -d '_' -f3`
	#Refine SUBID To Locate Raw Event File
	if [[ $SUBID != *sub-1213* ]]; then
		SUB=`echo $SUBID | cut -d 'x' -f1`
	else
		SUB=`echo $SUBID`
	fi
	#Check if Event Missing
	if [[ ! -f $EVENTDIR/$SUB.tsv ]] ; then
		echo $SUBID >> $EVENTDIR/sub_missing.txt 
		continue
	fi
	#Check Whether Event is Long Enough
	EVENT=`echo $SCAN | sed s@'bold.nii.gz'@'events.tsv'@g`
	cat $EVENTDIR/${SUB}.tsv | head -n1 > $EVENT
	if [[ $RUNNUM == 'run-1' ]]; then
		cat $EVENTDIR/${SUB}.tsv | sed -n '2,51p' >> $EVENT
	elif [[ $RUNNUM == 'run-2' ]]; then
		cat $EVENTDIR/${SUB}.tsv | sed -n '51,100p' >> $EVENT
	elif [[ $RUNNUM == 'run-3' ]]; then
		cat $EVENTDIR/${SUB}.tsv | sed -n '101,150p' >> $EVENT
	elif [[ $RUNNUM == 'run-4' ]]; then
		cat $EVENTDIR/${SUB}.tsv | sed -n '151,200p' >> $EVENT
	fi
done

#Check For Missing Event Files
for f in `find /dfs9/yassalab/CONTE2/bids | grep task-bandit | grep .json` ; do
	TSV=`echo $f | sed s@'bold.json'@'events.tsv'@g`
	if [[ `cat $TSV | wc -l` < 50 ]]; then
		echo $TSV `cat $TSV | wc -l`
	fi
done

#Create Event Files - Batch2
EVENTDIR=$DIR_PROJECT/downloads/taskevents_batch2
for SCAN in `find $DIR_PROJECT/bids | grep task-bandit | grep bold.nii.gz` ; do
	SUBID=`basename $SCAN | cut -d '_' -f1`
	RUNNUM=`basename $SCAN | cut -d '_' -f3`
	IDNUM=`echo $SUBID | cut -d 'x' -f1 | sed s@'sub-'@@g`
	#Check if Event Missing
	FOUND=`echo $EVENTDIR/*_${IDNUM}.txt | cut -d ' ' -f1`
	if [[ ! -f $FOUND ]] ; then
		echo $SUBID >> $EVENTDIR/sub_missing.txt 
		continue
	fi
	#Check Whether Event is Long Enough
	EVENT=`echo $SCAN | sed s@'bold.nii.gz'@'events.tsv'@g`
	cat $FOUND | head -n1 > $EVENT
	if [[ $RUNNUM == 'run-1' ]]; then
		cat $FOUND | sed -n '2,51p' >> $EVENT
	elif [[ $RUNNUM == 'run-2' ]]; then
		cat $FOUND | sed -n '51,100p' >> $EVENT
	elif [[ $RUNNUM == 'run-3' ]]; then
		cat $FOUND | sed -n '101,150p' >> $EVENT
	elif [[ $RUNNUM == 'run-4' ]]; then
		cat $FOUND | sed -n '151,200p' >> $EVENT
	fi
done

#Merge Event Files - FEAT3
for MODEL in `echo 1TD 2Sampler 3Hybrid 4TD2LR 5Sampler2LR 6Hybrid2LR` ; do
	DIR_PROJECT=/dfs9/yassalab/CONTE2
	OUTDIR=${DIR_PROJECT}/pipelines/xcpfeat/pipe-feat3_${MODEL}; mkdir -p $OUTDIR/logs
	FILES=`ls $DIR_PROJECT/pipelines/xcpfeat/STORE/pipe-feat3_${MODEL}_run-*/logs/sub-*.txt`
	for F in $FILES ; do
		LABEL=`basename $F`
		cat $F >> $OUTDIR/logs/$LABEL
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################