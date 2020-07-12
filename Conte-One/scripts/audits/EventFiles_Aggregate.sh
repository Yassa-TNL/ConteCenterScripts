#!/bin/bash
###########

DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

module purge ; module load anaconda/2.7-4 F.3.1 singularity/3.3.0 R/3.5.3
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

##################################################
### Reorganize Raw File Labels For Consistency ###
##################################################

echo "Relabeling Filenames To Have The Same Deliminter"
for FILE in `echo $DIR_PROJECT/audits/eventfiles_AMG/*-*-*.* | tr ' ' '\n' | grep -v tsv` ; do
	if [ ${FILE: -5} == ".xlsx" ] ; then
		xlsx2csv $FILE | tr ',' '\t' > `echo $FILE | sed s@.xlsx@.xls@g`
		rm $FILE ; FILE=`echo $FILE | sed s@.xlsx@.xls@g`
	fi 
	SUB=`basename $FILE | cut -d '-' -f2`
	SES=`basename $FILE | cut -d '-' -f3 | cut -d '.' -f1 | cut -d '_' -f1`
	REFORMATTED=$(echo `dirname $FILE`/sub-${SUB}_ses-${SES}_task-AMG_events.tsv)
	TXT_DIR=$DIR_PROJECT/audits/eventfiles_AMG/Xtra_TXT ; mkdir -p ${TXT_DIR}
	XTRA_DIR=$DIR_PROJECT/audits/eventfiles_AMG/Xtra_UNK ; mkdir -p ${XTRA_DIR}
	mv $FILE $REFORMATTED
	if [ ${FILE: -4} == ".txt" ] ; then
		mv $REFORMATTED $TXT_DIR 
	elif [ -z $(find $DIR_PROJECT/bids -iname *task-AMG*.nii.gz | grep /sub-${SUB}/ses-${SES}/func) ] ; then 
		if [ ! -z $(find $DIR_PROJECT/bids -iname *task-AMG*.nii.gz | grep sub-50${SUB}_ses-${SES}) ] ; then
			NEW_SUB=`echo 50$SUB`
			mv $REFORMATTED $(echo $REFORMATTED | sed s@${SUB}@${NEW_SUB}@g)
		else
			mv $REFORMATTED $XTRA_DIR
		fi
	fi
done

############################################
### Restructure Excel Files For Analysis ###
############################################

echo "Transfer Copies To Subject-Level Directories and Restructure Files For Analysis"
for FILE in `echo $DIR_PROJECT/audits/eventfiles_AMG/sub-*_ses-*_task-AMG_events.tsv` ; do
	SUB=`basename $FILE | cut -d '_' -f1 | cut -d '-' -f2`
	SES=`basename $FILE | cut -d '_' -f2 | cut -d '-' -f2`
	echo "Reformatting $SUB x $SES" ; unset REFORMAT
	REFORMAT=$(echo $DIR_PROJECT/bids/sub-${SUB}/ses-${SES}/func/`basename $FILE`)
	tail -n +2 "$FILE" | tr -d '\000' > $REFORMAT
	ONSET_TIME=`cat $REFORMAT | tr '\t' ',' | csvcut -c fix.OnsetTime | grep -o '[[:digit:]]*'`
	cat $REFORMAT | tr '\t' ',' | csvcut -c face.OnsetTime,face,emotion,face.RESP,face.RT | sed s@'\\'@''@g > ${REFORMAT}_TEMP
	cat ${REFORMAT}_TEMP | sed s@'facesAF'@''@g | sed s@'.bmp'@''@g | sed s@',,'@',0,'@g | tr ' ' '\n' | grep -v ^,0 > ${REFORMAT}
	tail -n +2 ${REFORMAT} | sed s@,@' '@g | awk -v s=$(echo $ONSET_TIME) '{print ($1 - s)}' | awk '{for(i=1;i<=NF;i++)$i/=1000}1' > ${REFORMAT}_ONSET
	awk '{$1=0.35} {print}' ${REFORMAT}_ONSET > ${REFORMAT}_DURATION
	tail -n +2 ${REFORMAT} | sed s@','@' '@g | awk '{print $2}' | cut -c3-5 > ${REFORMAT}_EMOTIONS
	tail -n +2 ${REFORMAT} | sed s@','@' '@g | awk '{print $2}' | cut -c1-2 > ${REFORMAT}_FACES
	tail -n +2 ${REFORMAT} | tr ',' ' ' | awk '{print $3,$4,$5}' > ${REFORMAT}_RESPONCES
	paste -d '\t' ${REFORMAT}_ONSET ${REFORMAT}_DURATION ${REFORMAT}_EMOTIONS ${REFORMAT}_FACES ${REFORMAT}_RESPONCES | tr ' ' '\t' > ${REFORMAT}_TEMP
	sed -i '1 i\onset,duration,emotion,face,trail_type,responce,responce_type' ${REFORMAT}_TEMP
	cat ${REFORMAT}_TEMP | tr ',' '\t' | awk '{for(i=7;i<=NF;i++)$i/=1000}1' | sed s@"responce 0"@"responce"@g > ${REFORMAT} ; rm ${REFORMAT}_*
done

###########################################
### Restructure Text Files For Analysis ###
###########################################

echo "Transfer Copies To Subject-Level Directories and Restructure Files For Analysis"
for FILE in `echo $DIR_PROJECT/audits/eventfiles_AMG/Xtra_TXT/sub-*_ses-*_task-AMG_events.tsv` ; do
	cat $FILE | tr -d '\000' > ${FILE}_TEMP ; mv ${FILE}_TEMP $FILE
	SUB=`basename $FILE | cut -d '_' -f1 | cut -d '-' -f2`
	SES=`basename $FILE | cut -d '_' -f2 | cut -d '-' -f2`
	RESTRUCT=$(echo $DIR_PROJECT/bids/sub-${SUB}/ses-${SES}/func/`basename $FILE`)
	ONSET_TIME=`cat $FILE | grep Fix.OnsetTime: | awk '{print $2}' | grep -o '[[:digit:]]*'`
	cat ${FILE} | grep "face.OnsetTime:" | awk '{print $2}' | awk -v s=$(echo $ONSET_TIME) '{print ($1 - s)}' | awk '{for(i=1;i<=NF;i++)$i/=1000}1' > ${RESTRUCT}_ONSET
	awk '{$1=0.35} {print}' ${RESTRUCT}_ONSET > ${RESTRUCT}_DURATION
	cat ${FILE} | grep .bmp | awk '{print $2}' | cut -c11-13 > ${RESTRUCT}_EMOTIONS
	cat ${FILE} | grep .bmp | awk '{print $2}' | cut -c9-10 > ${RESTRUCT}_FACES
	cat ${FILE} | grep emotion | awk {'print $2'} > ${RESTRUCT}_CONDITION
	cat ${FILE} | grep "face.RESP" | sed s@'face.RESP: '@'face.RESP: 0'@g | awk '{print $2}' | sed s@01@1@g > ${RESTRUCT}_RESPONCE
	cat ${FILE} | grep face.RT: | awk '{print $2}' | awk '{for(i=1;i<=NF;i++)$i/=1000}1' > ${RESTRUCT}_TIME
	paste -d ',' ${RESTRUCT}_ONSET ${RESTRUCT}_DURATION ${RESTRUCT}_EMOTIONS ${RESTRUCT}_FACES ${RESTRUCT}_CONDITION ${RESTRUCT}_RESPONCE ${RESTRUCT}_TIME > ${RESTRUCT}_TEMP
	sed -i '1 i\onset,duration,emotion,face,trail_type,responce,responce_type' ${RESTRUCT}_TEMP
	mv ${RESTRUCT}_TEMP ${RESTRUCT}
done

###########################################
### Clean Final Files Prior to Analysis ###
###########################################

rm `find $DIR_PROJECT/bids -iname *tsv_*`
for FILE in `find $DIR_PROJECT/bids -iname *tsv` ; do
	cat ${FILE} | tr ',' '\t' | tr ' ' '\t' > ${FILE}_TEMP
	mv ${FILE}_TEMP $FILE ; chmod 740 ${FILE}
done

############################################
### Aggregate Hippocampal Stimulus Files ###
############################################

echo "Transfer Copies To Subject-Level Directories and Restructure Files For Analysis"
for FILE in $DIR_PROJECT/audits/eventfiles_HIPP/*\ *; do 
	mv "$FIL" "${FILE// /_}"
done
for FILE in `echo $DIR_PROJECT/audits/eventfiles_HIPP/ASL_Baseline_s*_log*.txt` ; do
	SUBID=`basename $FILE | cut -d '_' -f3 | sed s@'s'@''@g`
	DAY=`head -n1 $FILE | cut -d ' ' -f1 | cut -d '-' -f1 | sed s@^0@""@g`
	YEAR=`head -n1 $FILE | cut -d ' ' -f1 | cut -d '-' -f3 | sed s@'20'@''@g`
	DATE=`cat $DIR_PROJECT/datasets/aggregate_df.csv | grep ^${SUBID} | cut -d ',' -f3 | tr '\n' '@'`
	if [[ ! -d $DIR_PROJECT/bids/sub-${SUBID} && -d $DIR_PROJECT/bids/sub-50${SUBID} ]] ; then
		mv $FILE `echo $FILE | sed s@"_s${SUBID}_"@"_s50${SUBID}_"@g`
		SUBID=`echo 50${SUBID}`
	fi
	if [[ ! -d $DIR_PROJECT/bids/sub-${SUBID} ]] ; then
		mkdir -p ${DIR_PROJECT}/audits/eventfiles_HIPP/Xtra_UNK_SUB
		mv $FILE ${DIR_PROJECT}/audits/eventfiles_HIPP/Xtra_UNK_SUB
	elif [[ ${DATE} != *"/${DAY}/${YEAR}@"* ]] ; then
		mkdir -p ${DIR_PROJECT}/audits/eventfiles_HIPP/Xtra_UNK_DATE
		mv $FILE ${DIR_PROJECT}/audits/eventfiles_HIPP/Xtra_UNK_DATE
	else
		SESID=`cat $DIR_PROJECT/datasets/aggregate_df.csv | grep ^${SUBID} | grep /$DAY/$YEAR | cut -d ',' -f2`
		mv $FILE $DIR_PROJECT/audits/eventfiles_HIPP/sub-${SUBID}_ses-${SESID}_task-HIPP_events.tsv
	fi
done

for FILE in `echo $DIR_PROJECT/audits/eventfiles_HIPP/*.tsv` ; do
	if [[ `cat $FILE | tail -n13 | head -n1 | tr '\t' '@'` != "Block@Type@S_Time" ]] ; then
		mkdir -p ${DIR_PROJECT}/audits/eventfiles_HIPP/Xtra_UNK_INCOM
		mv $FILE ${DIR_PROJECT}/audits/eventfiles_HIPP/Xtra_UNK_INCOM
	else
		SUB=`basename $FILE | cut -d '_' -f1 | cut -d '-' -f2`
		SES=`basename $FILE | cut -d '_' -f2 | cut -d '-' -f2`
		BIDS_EVENT=$DIR_PROJECT/bids/sub-${SUB}/ses-${SES}/func/sub-${SUB}_ses-${SES}_task-HIPP_events.tsv
		cat $FILE | tail -n13 | awk '{print $3,0.30,$2}' | sed s@"S_Time 0.3 Type"@"onset duration trail_type"@g | tr ' ' '\t' > $BIDS_EVENT
		chmod ug+wrx $BIDS_EVENT
	fi
done


###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
