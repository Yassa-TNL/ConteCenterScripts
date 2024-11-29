#!/usr/bin/env bash
###################

DIR_PROJECT=/dfs9/yassalab/CONTE2
FEAT_DESIGN=`echo $DIR_TOOLBOX/bids_apps/xcp-feat/design.dsn`
DIR_TOOLBOX=/dfs9/yassalab/rjirsara/ConteCenterScripts/ToolBox
SIMG_CONTAINER=$DIR_TOOLBOX/bids_apps/dependencies/xcpEngine.simg
DIR_SCRIPTS=/dfs9/yassalab/rjirsara/ConteCenterScripts/study-CONTE2

#####
### Submit XCP-FEAT Post-Processing Jobs - Level 1
#####

FSF1=`ls $DIR_TOOLBOX/bids_apps/xcp-feat/feat1_proj-CONTE2.fsf`
EVENTS=`find $DIR_PROJECT/pipelines/xcpfeat | grep _task-bandit_evs-1_lab-won.txt`
for EVENT in $EVENTS; do
	DESIGN=`ls $EVENT | sed s@'_task-bandit_evs-1_lab-won.txt'@'_command.sh'@g`
	if [ ! -f $DESIGN ]; then
		echo $EVENT >> temp.txt
	fi
done; EVENTS=`cat temp.txt`; rm temp.txt
for SUBJID in `echo $EVENTS | tr ' ' '\n' | cut -d '/' -f9  | cut -d '_' -f1 | sort | uniq` ; do
	for EVENT in `find $DIR_PROJECT/pipelines/xcpfeat | grep $SUBJID | grep won.txt` ; do
		OUTPUTDIR=$(dirname `dirname $EVENT`)
		RUN=`basename $OUTPUTDIR | cut -d '-' -f4`
		SCAN=`find ${DIR_PROJECT}/pipelines/fmriprep/$SUBJID/func | grep preproc | grep run-${RUN} | grep .nii.gz`
		FEAT_FILE=`echo $SCAN | sed s@'.nii.gz'@@g`
		NPTS=`fslstats $SCAN -V | awk {'print $1'}`
		EVENT_LOSS=`echo $EVENT | sed s@'evs-1_lab-won'@'evs-2_lab-loss'@g`
		DESIGN_FSF=`ls $EVENT | sed s@"evs-1_lab-won.txt"@"design.fsf"@g`
		cat $FSF1 \
			| sed s@"OUTPUTDIR"@"${OUTPUTDIR}"@g \
			| sed s@"FEAT_FILES"@"${FEAT_FILE}"@g \
			| sed s@"NPTS"@"${NPTS}"@g \
			| sed s@"EVENTS_WON"@"${EVENT}"@g \
			| sed s@"EVENTS_LOSS"@"${EVENT_LOSS}"@g > $DESIGN_FSF
		COHORT=`ls $EVENT | sed s@"task-bandit_evs-1_lab-won.txt"@"cohort.csv"@g`
		FPREP=`echo $SCAN | cut -d '/' -f7,8,9`
		echo "id0,img,task_design" > $COHORT
		echo "${SUBJID},${FPREP},${DESIGN_FSF}" >> $COHORT
		COMMAND=`echo $COHORT | sed s@'cohort.csv'@'command.sh'@g`
		echo '#!/bin/sh' > $COMMAND; echo "" >> $COMMAND
		echo "singularity run -B /dfs9/yassalab/ \
			--cleanenv $SIMG_CONTAINER \
			-d $FEAT_DESIGN \
			-c $COHORT \
			-o $OUTPUTDIR \
			-i $OUTPUTDIR/workflows \
			-r $DIR_PROJECT/pipelines/fmriprep \
			-t 2" >> $COMMAND
		chmod -R 775 $COMMAND
		JOBID=`echo $SUBJID | cut -d '-' -f2 | sed s@x@@g`
		echo ""
		echo "###### ⚡⚡⚡⚡ ##### ⚡⚡⚡⚡ ###### ⚡⚡⚡⚡ ### "
		echo "Submitting FSL FEAT Proc for ${SUBJID} "
		sbatch -A myassa_lab --job-name=$JOBID --partition=standard --nodes=1 --ntasks=24 --mem-per-cpu=6G $COMMAND
	done
done

#####
### Submit XCP-FEAT Post-Processing Jobs - Level 2
#####

for FEAT in `echo $DIR_PROJECT/pipelines/xcpfeat/pipe-feat1_task-bandit_run-*/sub-*/task/fsl/sub*.feat` ; do
	SUBID=`basename $FEAT | cut -d '.' -f1`
	FMRIDIR=`echo $DIR_PROJECT/pipelines/fmriprep/$SUBID/func`
	FMRIRUN=`echo $FEAT | sed s@"${DIR_PROJECT}/pipelines/xcpfeat/"@''@g | cut -d '/' -f1 | cut -d '_' -f3`
	MASK=`find $FMRIDIR/ | grep $FMRIRUN | grep mask.nii.gz`
	cp --remove-destination $MASK $FEAT/mask.nii.gz
done

FSF2=`ls $DIR_TOOLBOX/bids_apps/xcp-feat/feat2_proj-CONTE2.fsf`
OUTPUTDIR=$DIR_PROJECT/pipelines/xcpfeat/pipe-feat2_task-bandit
FEATDIRS=`find $DIR_PROJECT/pipelines/xcpfeat/pipe-feat1_task-bandit_run-* -type d | grep '.feat$'`
for SUBID in `echo $FEATDIRS | xargs -n 1 basename | sort | uniq | cut -d '.' -f1` ; do
	INPUT=`echo $FEATDIRS | tr ' ' '\n' | grep $SUBID`; NINPUT=`echo $INPUT | wc -w`
	mkdir -p $OUTPUTDIR/${SUBID}.gfeat; cd $OUTPUTDIR/${SUBID}.gfeat
	cat $FSF2 \
		| sed s@"SUBID"@"${SUBID}"@g \
		| sed s@"NINPUT"@"${NINPUT}"@g > $OUTPUTDIR/logs/${SUBID}.fsf
	INDEX=0
	for FEAT in $INPUT ; do
		INDEX=$(($INDEX + 1))
		echo set feat_files\(${INDEX}\) \"${FEAT}\" >> ./insert1.txt
	done
	sed -i '/# 4D AVW data or FEAT directory (1)/r insert1.txt' $OUTPUTDIR/logs/${SUBID}.fsf
	INDEX=0
	for FEAT in $INPUT ; do
		INDEX=$(($INDEX + 1))
		echo "set fmri(evg${INDEX}.1) 1.0" >> ./insert2.txt
	done
	sed -i "/# Higher-level EV value/r insert2.txt" $OUTPUTDIR/logs/${SUBID}.fsf
	INDEX=0
	for FEAT in $INPUT ; do
		INDEX=$(($INDEX + 1))
		echo "set fmri(groupmem.${INDEX}) 1" >> ./insert3.txt
	done
	sed -i '/# Group membership for input/r insert3.txt' $OUTPUTDIR/logs/${SUBID}.fsf
	COMMAND=`echo $OUTPUTDIR/logs/${SUBID}.fsf | sed s@"fsf$"@"sh"@g`
	JOBID=`echo $SUBID | cut -d '-' -f2 | sed s@x@@g`
	echo '#!/bin/sh' > $COMMAND; echo "" >> $COMMAND
	echo "feat $OUTPUTDIR/logs/${SUBID}.fsf" >> $COMMAND
	echo ""
	echo "###### ⚡⚡⚡⚡ ##### ⚡⚡⚡⚡ ###### ⚡⚡⚡⚡ ### "
	echo "Submitting FSL FEAT Proc for ${SUBJID} "
	cd $OUTPUTDIR/logs; rm -rf $OUTPUTDIR/${SUBID}.gfeat; chmod -R 775 $COMMAND
	sbatch -A myassa_lab --job-name=$JOBID --partition=standard --nodes=1 --ntasks=4 --mem-per-cpu=6G $COMMAND
done

#####
### Extract Regional Data Values
#####

for SUBDIR in `echo $DIR_PROJECT/pipelines/xcpfeat/pipe-feat2_task-bandit/sub-*` ; do
	SUB=`basename $SUBDIR | cut -d '.' -f1 | cut -d '-' -f2`
	for ATL in `echo PVTdilate2mm MelbourneP400S4 MelbourneP200S4` ; do
		SUFFIX=`echo $ATL | sed s@'MelbourneP'@''@g | sed s@'dilate2mm'@@g | sed s@'S4'@@g | sed s@'at-'@@g`
		JOBID=$(echo j`echo $SUB | cut -d 'x' -f1`x$SUFFIX)
		sbatch -A myassa_lab --job-name=$JOBID --partition=standard --nodes=1 --ntasks=4 --mem-per-cpu=6G \
			$DIR_SCRIPTS/extract_xcpfeat.sh $SUB $ATL
	done
done

#####
### Submit XCP-FEAT - Prediction Errors Beta Maps
#####

FSF3=`ls $DIR_TOOLBOX/bids_apps/xcp-feat/feat3_1beta_proj-CONTE2.fsf`
EVENTS=`ls $DIR_PROJECT/pipelines/xcpfeat/pipe-feat3_*/logs/*.txt`
for EVENT in `echo $EVENTS` ; do
	OUTPUTDIR=$(dirname `dirname $EVENT`)
	RUN=`basename $OUTPUTDIR | cut -d '-' -f3`
	SUBJID=`basename $EVENT | cut -d '.' -f1 | cut -d '-' -f2`
	SCAN=`find ${DIR_PROJECT}/pipelines/fmriprep/sub-${SUBJID}/func | grep preproc | grep run-${RUN} | grep .nii.gz`
	NPTS=`fslval $SCAN dim4`
	FEAT_FILE=`echo $SCAN | sed s@'.nii.gz'@@g`
	FULLID=`basename $SCAN | cut -d '_' -f1`
	OUTPUTDIR=`echo $OUTPUTDIR/$SUBJID`
	DESIGN_FSF=`ls $EVENT | sed s@".txt"@"_design.fsf"@g`
	cat $FSF3 \
		| sed s@"OUTPUTDIR"@"${OUTPUTDIR}"@g \
		| sed s@"FEAT_FILES"@"${FEAT_FILE}"@g \
		| sed s@"NPTS"@"${NPTS}"@g \
		| sed s@"EVENTS_WON"@"${EVENT}"@g > $DESIGN_FSF
	COMMAND=`echo $DESIGN_FSF | sed s@'design.fsf'@'command.sh'@g`
	echo '#!/bin/sh' > $COMMAND; echo "" >> $COMMAND
	echo "feat ${DESIGN_FSF}" >> $COMMAND
	chmod -R 775 $COMMAND
	echo ""
	echo "###### ⚡⚡⚡⚡ ##### ⚡⚡⚡⚡ ###### ⚡⚡⚡⚡ ### "
	echo "Submitting FSL FEAT Proc for ${SUBJID} "
	sbatch -A myassa_lab --job-name=X${SUBJID} --partition=standard --nodes=1 --ntasks=4 --mem-per-cpu=6G $COMMAND
done

#####
### Submit XCP-FEAT - Prediction Errors Beta Maps
#####

FSF3=`ls $DIR_TOOLBOX/bids_apps/xcp-feat/feat3_1beta_proj-CONTE2.fsf`
EVENTS=`ls $DIR_PROJECT/pipelines/xcpfeat/pipe-feat3_*/logs/*.txt`
for EVENT in `echo $EVENTS` ; do
	OUTPUTDIR=$(dirname `dirname $EVENT`)
	SUBJID=`basename $EVENT | cut -d '.' -f1 | cut -d '-' -f2`
	SCAN=`find ${DIR_PROJECT}/pipelines/xcpengine/pipe-36despike_task-bandit_runs/sub-${SUBJID} | grep _norm_resid.nii.gz`
	NPTS=`fslval $SCAN dim4`
	FEAT_FILE=`echo $SCAN | sed s@'.nii.gz'@@g`
	FULLID=`basename $SCAN | cut -d '_' -f1`
	OUTPUTDIR=`echo $OUTPUTDIR/$SUBJID`
	DESIGN_FSF=`ls $EVENT | sed s@".txt"@"_design.fsf"@g`
	cat $FSF3 \
		| sed s@"OUTPUTDIR"@"${OUTPUTDIR}"@g \
		| sed s@"FEAT_FILES"@"${FEAT_FILE}"@g \
		| sed s@"NPTS"@"${NPTS}"@g \
		| sed s@"EVENTS_WON"@"${EVENT}"@g > $DESIGN_FSF
	COMMAND=`echo $DESIGN_FSF | sed s@'design.fsf'@'command.sh'@g`
	echo '#!/bin/sh' > $COMMAND; echo "" >> $COMMAND
	echo "feat ${DESIGN_FSF}" >> $COMMAND
	chmod -R 775 $COMMAND
	echo ""
	echo "###### ⚡⚡⚡⚡ ##### ⚡⚡⚡⚡ ###### ⚡⚡⚡⚡ ### "
	echo "Submitting FSL FEAT Proc for ${SUBJID} "
	sbatch -A myassa_lab --job-name=X${SUBJID} --partition=standard --nodes=1 --ntasks=4 --mem-per-cpu=6G $COMMAND
done

#####
### Extract Regional Data Values
#####

for SUBDIR in `echo $DIR_PROJECT/pipelines/xcpfeat/pipe-feat3_*/*.feat` ; do
	SUB=`basename $SUBDIR | cut -d '.' -f1 | cut -d '-' -f2`
	DIRNAME=`dirname $SUBDIR`
	for ATL in `echo MelbourneP400S4 MelbourneP200S4` ; do
		SUFFIX=`echo $ATL | sed s@'MelbourneP'@''@g | sed s@'dilate2mm'@@g | sed s@'S4'@@g | sed s@'at-'@@g`
		JOBID=$(echo j`echo $SUB | cut -d 'x' -f1`x$SUFFIX)
		sbatch -A myassa_lab --job-name=$JOBID --partition=standard --nodes=1 --ntasks=4 --mem-per-cpu=6G \
			$DIR_SCRIPTS/extract_xcpfeat.sh $SUB $ATL $DIRNAME
	done
done

########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######