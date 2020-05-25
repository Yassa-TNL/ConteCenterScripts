#!/bin/bash
###########

DIR_LOCAL_BIDS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/bids
DIR_LOCAL_AUDITS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

########################################################
### ###
########################################################

echo "Relabeling Filenames To Have The Same Deliminter"
for FILE in `echo ${DIR_LOCAL_AUDITS}/rawdata/StimFiles_AMG/*-*-*.*` ; do
	if [ ${FILE: -5} == ".xlsx" ] ; then
		xlsx2csv $FILE | tr ',' '\t' > `echo $FILE | sed s@.xlsx@.xls@g`
		rm $FILE ; FILE=`echo $FILE | sed s@.xlsx@.xls@g`
	fi 
	SUB=`basename $FILE | cut -d '-' -f2`
	SES=`basename $FILE | cut -d '-' -f3 | cut -d '.' -f1 | cut -d '_' -f1`	
	REFORMATTED=$(echo `dirname $FILE`/sub-${SUB}_ses-${SES}_task-AMG_events.tsv)
	TXT_DIR=${DIR_LOCAL_AUDITS}/rawdata/StimFiles_AMG/Xtra_TXT ;  mkdir -p ${TXT_DIR}
	XTRA_DIR=${DIR_LOCAL_AUDITS}/rawdata/StimFiles_AMG/Xtra_UNK ;  mkdir -p ${XTRA_DIR}
	mv $FILE $REFORMATTED
	if [ ${FILE: -4} == ".txt" ] ; then
		mv $REFORMATTED $TXT_DIR 
	elif [ -z $(find ${DIR_LOCAL_BIDS} -iname *task-AMG*.nii.gz | grep /sub-${SUB}/ses-${SES}/func) ] ; then 
		if [ -z $(find ${DIR_LOCAL_BIDS} -iname *task-AMG*.nii.gz | grep sub-50${SUB}_ses-${SES}) ] ; then
			NEW_SUB=`echo 50$SUB`
			mv $REFORMATTED $(echo $REFORMATTED | sed s@${SUB}@${NEW_SUB}@g)
		else
			mv $REFORMATTED $XTRA_DIR
		fi
	fi
done

########################################################
###  ###
########################################################

echo "Transfer Copies To Subject-Level Directories and Restructure Files For Analysis"
for FILE in `echo ${DIR_LOCAL_AUDITS}/rawdata/StimFiles_AMG/sub-*_ses-*_task-AMG_events.tsv` ; do
	SUB=`basename $FILE | cut -d '_' -f1 | cut -d '-' -f2`
	SES=`basename $FILE | cut -d '_' -f2 | cut -d '-' -f2`
	REFORMAT=$(echo $DIR_LOCAL_BIDS/sub-${SUB}/ses-${SES}/func/`basename $FILE`)
	tail -n +2 "$FILE" > $REFORMAT
	ONSET_TIME=`cat $REFORMAT | tr '\t' ',' | csvcut -c fix.OnsetTime | grep -o '[[:digit:]]*'`
	cat $REFORMAT | tr '\t' ',' | csvcut -c face.OnsetTime,face,emotion,face.RESP,face.RT | sed s@'\\'@''@g > ${REFORMAT}_NEW
	cat ${REFORMAT}_NEW | sed s@'facesAF'@''@g | sed s@'.bmp'@''@g | sed s@',,'@',0,'@g | tr ' ' '\n' | grep -v ^,NaN > ${REFORMAT}


	
done









ExperimentName	Subject	Session	Age	Clock.Information	Display.RefreshRate	GoodBye.ACC	GoodBye.CRESP	GoodBye.DurationError	GoodBye.OnsetDelay	GoodBye.OnsetTime	GoodBye.RESP	GoodBye.RT	GoodBye.RTTime	Group	Handedness	Name	RandomSeed	SessionDate	SessionTime	SessionTimeUtc	Sex	Block	MenuItem	ProcedureÆBlocRunList	RunList.Cycle	RunList.Sample	RunningÆBlockÅ	TriggerTime	Trial	BlockList	BlockList.Cycle	BlockList.Sample	ProcedureÆTrialÅ	RunningÆTrialÅ	SubTrial	DummyFix.Duration	DummyFix.DurationError	DummyFix.FinishTime	DummyFix.OffsetDelay	DummyFix.OffsetTime	DummyFix.OnsetDelay	DummyFix.OnsetTime	fix.ACC	fix.CRESP	fix.DurationError	fix.OffsetDelay	fix.OffsetTime	fix.OnsetDelay	fix.OnsetTime	fix.RESP	fix.RT	fix.RTTime	FixList2	FixList2.Cycle	FixList2.Sample	PeriodListNeutFear	PeriodListNeutFear.Cycle	PeriodListNeutFear.Sample	ProcedureÆSubTrialÅ	RunningÆSubTrialÅ	LogLevel5	cresp	emotion	face	face.ACC	face.DurationError	face.OffsetDelay	face.OffsetTime	face.OnsetDelay	face.OnsetTime	face.RESP	face.RT	face.RTTime	Fix3413.ACC	Fix3413.CRESP	Fix3413.DurationError	Fix3413.OffsetDelay	Fix3413.OffsetTime	Fix3413.OnsetDelay	Fix3413.OnsetTime	Fix3413.RESP	Fix3413.RT	Fix3413.RTTime	Fix3981.ACC	Fix3981.CRESP	Fix3981.DurationError	Fix3981.OffsetDelay	Fix3981.OffsetTime	Fix3981.OnsetDelay	Fix3981.OnsetTime	Fix3981.RESP	Fix3981.RT	Fix3981.RTTime	Fix4550.ACC	Fix4550.CRESP	Fix4550.DurationError	Fix4550.OffsetDelay	Fix4550.OffsetTime	Fix4550.OnsetDelay	Fix4550.OnsetTime	Fix4550.RESP	Fix4550.RT	Fix4550.RTTime	Fix5688.ACC	Fix5688.CRESP	Fix5688.DurationError	Fix5688.OffsetDelay	Fix5688.OffsetTime	Fix5688.OnsetDelay	Fix5688.OnsetTime	Fix5688.RESP	Fix5688.RT	Fix5688.RTTime	Fix6825.ACC	Fix6825.CRESP	Fix6825.DurationError	Fix6825.OnsetDelay	Fix6825.OnsetTime	Fix6825.RESP	Fix6825.RT	Fix6825.RTTime	Fix9100.ACC	Fix9100.CRESP	Fix9100.DurationError	Fix9100.OffsetDelay	Fix9100.OffsetTime	Fix9100.OnsetDelay	Fix9100.OnsetTime	Fix9100.RESP	Fix9100.RT	Fix9100.RTTime	ProcedureÆLogLevel5Å	RunningÆLogLevel5Å	TrialListNeutNTFear	TrialListNeutNTFear.Cycle	TrialListNeutNTFear.Sample	TriallistNeutTFear	TriallistNeutTFear.Cycle	TriallistNeutTFear.Sample


