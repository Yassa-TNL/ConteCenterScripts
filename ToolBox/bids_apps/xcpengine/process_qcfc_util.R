#!/bin/bash
#$ -q yassalab,free*
#$ -pe openmp 4
#$ -R y
#$ -ckpt restart
################

DIR_LOCAL_SCRIPTS=$1
DIR_LOCAL_APPS=$2
DIR_LOCAL_DATA=$3
ATLAS_LABEL=$4

##################################################################
##### If Missing Curate the Quality CSV Data For Each Pipeline ###
##################################################################

for DIR_PIPE in `find $DIR_LOCAL_APPS/xcpengine -maxdepth 1 -type d | grep fc-` ; do
	LABEL_PIPE=`basename $DIR_PIPE`
	for DIR_STRUC in `find $DIR_LOCAL_APPS/xcpengine/${LABEL_PIPE}/logs | grep directory_structure` ; do
		LABEL_TASK=`basename $DIR_STRUC | cut -d '_' -f3 | cut -d '.' -f1`
		echo "Outputting Residual Correlation Figure"
		FILE_RESID=`ls -t ${DIR_LOCAL_DATA}/${LABEL_TASK}/qcfc/*_${LABEL_PIPE}_Cohort.csv | head -n1`
		RESID_PREFIX=`echo $FILE_RESID | sed s@Cohort@ResidCor@g | sed s@.csv@@g`
		singularity exec --cleanenv $DIR_LOCAL_SCRIPTS/container_xcpengine.simg \
			/xcpEngine/utils/qcfc.R \
			-c ${FILE_RESID} \
			-o ${RESID_PREFIX}
		rsvg-convert ${RESID_PREFIX}.svg -f pdf -o ${RESID_PREFIX}.pdf ; rm ${RESID_PREFIX}.svg
		NUMSIG=`cat ${RESID_PREFIX}_nSigEdges.txt` ; rm ${RESID_PREFIX}_nSigEdges.txt
		ABSCOR=`cat ${RESID_PREFIX}_absMedCor.txt | cut -c1-4` ; rm ${RESID_PREFIX}_absMedCor.txt
		PCTSIG=`cat ${RESID_PREFIX}_pctSigEdges.txt | cut -c1-4` ; rm ${RESID_PREFIX}_pctSigEdges.txt
		mv ${RESID_PREFIX}.pdf ${RESID_PREFIX}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}.pdf
		mv ${RESID_PREFIX}.txt ${RESID_PREFIX}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}.txt
		mv ${RESID_PREFIX}_thr.txt ${RESID_PREFIX}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}_thr.txt
		echo "Outputting Distance-Dependence Figure"
		DIST_PREFIX=`echo $FILE_RESID | sed s@Cohort@DistDepend@g | sed s@.csv@@g`
		singularity exec --cleanenv $DIR_LOCAL_SCRIPTS/container_xcpengine.simg \
			/xcpEngine/utils/qcfcDistanceDependence \
			-a ${DIR_LOCAL_SCRIPTS}/atlases/power264/power264MNI.nii.gz \
			-q ${RESID_PREFIX}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}.txt \
			-o ${DIST_PREFIX}_Cor.txt \
			-d ${DIST_PREFIX}_Mat.txt \
			-f ${DIST_PREFIX}.pdf \
			-i ${DIR_LOCAL_DATA}/${LABEL_TASK}/qcfc > /dev/null 2>&1
		ABSCOR=`cat ${DIST_PREFIX}_Cor.txt` ; rm ${DIST_PREFIX}_Cor.txt
		ABSCOR=`echo $ABSCOR | sed s@'-'@''@g |cut -c 1-4`
		mv ${DIST_PREFIX}_Mat.txt ${DIST_PREFIX}_cor-${ABSCOR}_Mat.txt
		mv ${DIST_PREFIX}.pdf ${DIST_PREFIX}_cor-${ABSCOR}.pdf
		chmod -R 755 ${DIR_LOCAL_DATA}/${LABEL_TASK}/qcfc
	done
done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<SKIP
	for TASK_LABEL in `find $DIR_PIPE/logs/directory_structure_*.csv -printf "%f\n" | cut -d '_' -f3 | cut -d '.' -f1` ; do
		NSUB=`find $DIR_PIPE/sub* -type d -name "task-${TASK_LABEL}" | wc -l`
		echo ""
		echo "###################################################"
		echo "Now Curating Quality Data For `basename $DIR_PIPE` "
		echo "###################################################"
		singularity exec --cleanenv $DIR_LOCAL_SCRIPTS/container_xcpengine.simg \
			/xcpEngine/utils/combineOutput \
			-p "${DIR_PIPE}"  \
			-f "sub-*_network.txt" \
			-o group/n${NSUB}_quality.csv
		chmod -R ug+wrx $DIR_PIPE/group
	done

##################################################
##### Merge Quality CSV Data For All Pipelines ###
##################################################

	FILE_FMRI=`echo ${DIR_LOCAL_DATA}/${TASK_LABEL}/motionVisual/n*_Quality*${TASK_LABEL}.csv | cut -d ' ' -f1`
	if [[ ! -f $FILE_FMRI ]] ; then
		echo ""
		echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡ "
		echo "ERROR: Could Not Find Quality Data From FMRIPREP For Curating "
		echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡ "
		exit 0
	else
		echo ""
		echo "############################################################"
		echo "Creating Copy of FMRIPREP QA Dataset To Merge New Variables "
		echo "############################################################"
		FILE_FMRI=`ls -t ${DIR_LOCAL_DATA}/${TASK_LABEL}/motionVisual/n*_Quality*${TASK_LABEL}.csv | head -n1`
		FILE_OUT=`echo $FILE_FMRI | sed s@"motionVisual"@"evalQC"@g`
		if [[ `cat $FILE_FMRI | head -n1 | cut -d ',' -f1` == '""' ]] ; then
			mkdir -p ${DIR_LOCAL_DATA}/${TASK_LABEL}/evalQC
			cut -d "," -f2- $FILE_FMRI > $FILE_OUT
		else
			mkdir -p ${DIR_LOCAL_DATA}/${TASK_LABEL}/evalQC
			cp $FILE_FMRI $FILE_OUT
		fi
	fi

##################################################
##### Merge Quality CSV Data For All Pipelines ###
##################################################

	for DIR_PIPE in `find $DIR_LOCAL_APPS/xcpengine -maxdepth 2 -type d | tail -n +3` ; do
		PIPE_LABEL=`basename $DIR_PIPE`
		echo ""
		echo "#######################################"
		echo "Now Working on QC Eval For $PIPE_LABEL "
		echo "#######################################"
		echo ""
		echo "Adding Number of Regressors to QC Dataset"
		ADD_ROW_HEADER=`echo '"'nRegressorsX${PIPE_LABEL}'"'`
		NEW_FILE_HEADER=$(echo `head -n1 $FILE_OUT`,${ADD_ROW_HEADER})
		cat $FILE_OUT | sed s@`head -n1 $FILE_OUT`@${NEW_FILE_HEADER}@g > TEMP.csv
		mv TEMP.csv $FILE_OUT
		for REGRESS in `find $DIR_PIPE/sub-* -name "sub-*_modelParameterCount.txt" -type f` ; do
			SUBID=`basename $REGRESS | cut -d "_" -f1 | cut -d "-" -f2`
			if [[ `echo $REGRESS` == *"ses-"* ]] ; then 
				SESID=`basename $REGRESS | cut -d "_" -f2 | cut -d "-" -f2`
				OLD_ROW=`cat $FILE_OUT | grep ^${SUBID},${SESID}`
			else
				OLD_ROW=`cat $FILE_OUT | grep ^$SUBID,`
			fi
			NEW_ROW=$(echo ${OLD_ROW},`cat $REGRESS`)
			cat $FILE_OUT | sed s@${OLD_ROW}@${NEW_ROW}@g > TEMP.csv
			mv TEMP.csv $FILE_OUT
		done
		echo ""
		echo "Adding Number of Volumes Censored to QC Dataset"
		ADD_ROW_HEADER=`echo '"'nCensoredX${PIPE_LABEL}'"'`
		NEW_FILE_HEADER=$(echo `head -n1 $FILE_OUT`,${ADD_ROW_HEADER})
		cat $FILE_OUT | sed s@`head -n1 $FILE_OUT`@${NEW_FILE_HEADER}@g > TEMP.csv
		mv TEMP.csv $FILE_OUT
		for REGRESS in `find $DIR_PIPE/sub-* -name "sub-*_modelParameterCount.txt" -type f` ; do
			if [[ `echo $REGRESS` == *"ses-"* ]] ; then
				SUBID=`basename $REGRESS | cut -d '_' -f1 | cut -d '-' -f2`
				SESID=`basename $REGRESS | cut -d '_' -f2 | cut -d '-' -f2`
				CENSOR=`find $DIR_PIPE/sub-${SUBID}/ses-${SESID} | grep  "sub-${SUBID}_ses-${SESID}_nVolumesCensored.txt"`
				if  [[ ! -z $CENSOR ]] ; then
					OLD_ROW=`cat $FILE_OUT | grep ^${SUBID},${SESID}`
					NEW_ROW=$(echo ${OLD_ROW},`cat $CENSOR`)
					cat $FILE_OUT | sed s@${OLD_ROW}@${NEW_ROW}@g > TEMP.csv
					mv TEMP.csv $FILE_OUT
				else
					OLD_ROW=`cat $FILE_OUT | grep ^$SUBID,${SESID}`
					NEW_ROW=$(echo ${OLD_ROW},"NA")
					cat $FILE_OUT | sed s@${OLD_ROW}@${NEW_ROW}@g > TEMP.csv
					mv TEMP.csv $FILE_OUT
				fi
			else
				SUBID=`basename $REGRESS | cut -d '_' -f1 | cut -d '-' -f2`
				CENSOR=`find $DIR_PIPE/sub-${SUBID} | grep  "sub-${SUBID}_nVolumesCensored.txt"`
				if  [[ ! -z $CENSOR ]] ; then
					OLD_ROW=`cat $FILE_OUT | grep ^$SUBID,`
					NEW_ROW=$(echo ${OLD_ROW},`cat $CENSOR`)
					cat $FILE_OUT | sed s@${OLD_ROW}@${NEW_ROW}@g > TEMP.csv
					mv TEMP.csv $FILE_OUT
				else
					OLD_ROW=`cat $FILE_OUT | grep ^$SUBID,`
					NEW_ROW=$(echo ${OLD_ROW},"NA")
					cat $FILE_OUT | sed s@${OLD_ROW}@${NEW_ROW}@g > TEMP.csv
					mv TEMP.csv $FILE_OUT
				fi
			fi
		done

##############################################################
##### Create Cohort Files For Residual-Motion Correaltions ###
##############################################################

		TODAY=`date "+%Y%m%d"`
		RESID_PREFIX=`echo /${DIR_LOCAL_DATA}/${TASK_LABEL}/evalQC/${PIPE_LABEL}`
		mkdir -p $RESID_PREFIX
		echo ""
		echo "Computing Cohort File From QA Dataset"
		if [[ `echo $REGRESS` == *"ses-"* ]] ; then
			awk -F "\"*,\"*" '{print $1,$2,$3}' $FILE_OUT | sed s@'"'@''@g | sed s@' '@','@g | sed s@"fdMEAN"@"motion,connectivity"@g > ${PIPE_LABEL}_TEMP.csv
			for FCON in `find $DIR_PIPE/sub-* -name "*${ATLAS_LABEL}_network.txt" -type f` ; do
				SUBID=`basename $FCON | cut -d '_' -f1 | cut -d '-' -f2`
				SESID=`basename $FCON | cut -d '_' -f2 | cut -d '-' -f2`
				OLD_ROW=`cat ${PIPE_LABEL}_TEMP.csv | grep ^${SUBID},${SESID}`
				NEW_ROW=$(echo ${OLD_ROW},`echo $FCON`)
				cat ${PIPE_LABEL}_TEMP.csv | sed s@${OLD_ROW}@${NEW_ROW}@g > ${PIPE_LABEL}_TEMP1.csv
				mv ${PIPE_LABEL}_TEMP1.csv ${PIPE_LABEL}_TEMP.csv
			done
		else
			awk -F "\"*,\"*" '{print $1,$2}' $FILE_OUT | sed s@'"'@''@g | sed s@' '@','@g | sed s@"fdMEAN"@"motion,connectivity"@g > ${PIPE_LABEL}_TEMP.csv
			for FCON in `find $DIR_PIPE/sub-* -name "*${ATLAS_LABEL}_network.txt" -type f` ; do
				SUBID=`basename $FCON | cut -d '_' -f1 | cut -d '-' -f2`
				OLD_ROW=`cat ${PIPE_LABEL}_TEMP.csv | grep ^$SUBID,`
				NEW_ROW=$(echo ${OLD_ROW},`echo $FCON`)
				cat ${PIPE_LABEL}_TEMP.csv | sed s@${OLD_ROW}@${NEW_ROW}@g > ${PIPE_LABEL}_TEMP1.csv
				mv ${PIPE_LABEL}_TEMP1.csv ${PIPE_LABEL}_TEMP.csv
			done
		fi
		cat ${PIPE_LABEL}_TEMP.csv | grep 'network.txt\|connectivity' > ${PIPE_LABEL}_TEMP1.csv
		NSUBS=$((`cat ${PIPE_LABEL}_TEMP1.csv | wc -l` -1 )) ; rm ${PIPE_LABEL}_TEMP.csv
		mv ${PIPE_LABEL}_TEMP1.csv ${RESID_PREFIX}/n${NSUBS}_ResidCor_Cohort_${PIPE_LABEL}_${TODAY}.csv

#################################################
##### Outputting Residual Correlation Figures ###
#################################################

		echo ""
		echo "Outputting Residual Correlation Figure"
		singularity exec --cleanenv $DIR_LOCAL_SCRIPTS/container_xcpengine.simg \
			/xcpEngine/utils/qcfc.R \
			-c ${RESID_PREFIX}/n${NSUBS}_ResidCor_Cohort_${PIPE_LABEL}_${TODAY}.csv \
			-o ${RESID_PREFIX}/ResidCor
		rsvg-convert ${RESID_PREFIX}/ResidCor.svg -f pdf -o ${RESID_PREFIX}/ResidCor.pdf ; rm ${RESID_PREFIX}/ResidCor.svg
		NUMSIG=`cat ${RESID_PREFIX}/ResidCor_nSigEdges.txt` ; rm ${RESID_PREFIX}/ResidCor_nSigEdges.txt
		ABSCOR=`cat ${RESID_PREFIX}/ResidCor_absMedCor.txt | cut -c1-4` ; rm ${RESID_PREFIX}/ResidCor_absMedCor.txt
		PCTSIG=`cat ${RESID_PREFIX}/ResidCor_pctSigEdges.txt | cut -c1-4` ; rm ${RESID_PREFIX}/ResidCor_pctSigEdges.txt
		mv ${RESID_PREFIX}/ResidCor.pdf ${RESID_PREFIX}/ResidCor_parc-${ATLAS_LABEL}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}_${PIPE_LABEL}.pdf
		mv ${RESID_PREFIX}/ResidCor.txt ${RESID_PREFIX}/ResidCor_parc-${ATLAS_LABEL}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}_${PIPE_LABEL}.txt
		mv ${RESID_PREFIX}/ResidCor_thr.txt ${RESID_PREFIX}/ResidCor_parc-${ATLAS_LABEL}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}_${PIPE_LABEL}_thr.txt
		cat `find $DIR_LOCAL_APPS/xcpengine/$TASK_LABEL/${PIPE_LABEL} | grep ${ATLAS_LABEL}.net | head -n1` | awk {'print $1'} | tail -n +3 > TEMP1.csv
		cat `find $DIR_LOCAL_APPS/xcpengine/$TASK_LABEL/${PIPE_LABEL} | grep ${ATLAS_LABEL}.net | head -n1` | awk {'print $2'} | tail -n +3 > TEMP2.csv
		paste TEMP1.csv TEMP2.csv ${RESID_PREFIX}/ResidCor_parc-${ATLAS_LABEL}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}_${PIPE_LABEL}_thr.txt | tr '\t' ',' > TEMP3.csv
		mv TEMP3.csv `echo ${RESID_PREFIX}/ResidCor_parc-${ATLAS_LABEL}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}_${PIPE_LABEL}_thr.txt | sed s@.txt@.csv@g`
		rm TEMP*.csv `echo ${RESID_PREFIX}/ResidCor_parc-${ATLAS_LABEL}_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}_${PIPE_LABEL}_thr.txt`
		echo ""
		echo "Outputting Distance-Dependence Figure"
		singularity exec --cleanenv $DIR_LOCAL_SCRIPTS/container_xcpengine.simg \
			/xcpEngine/utils/qcfcDistanceDependence \
			-a ${DIR_LOCAL_SCRIPTS}/parcs/${ATLAS_LABEL}/${ATLAS_LABEL}MNI.nii.gz  \
			-q ${RESID_PREFIX}/ResidCor_num-${NUMSIG}_pct-${PCTSIG}_cor-${ABSCOR}_${PIPE_LABEL}.txt \
			-o ${RESID_PREFIX}EMP_DistDepend_Cor.txt \
			-d ${RESID_PREFIX}EMP_DistDepend_Mat.txt \
			-f ${RESID_PREFIX}/DistDepend.pdf \
			-i ${RESID_PREFIX}EMP > /dev/null 2>&1
		DISTCOR=`cat ${RESID_PREFIX}EMP_DistDepend_Cor.txt` ; rm ${RESID_PREFIX}EMP*
		mv ${RESID_PREFIX}/DistDepend.pdf ${RESID_PREFIX}/DistDepend_cor-${DISTCOR}_${PIPE_LABEL}.pdf
	done
	chmod -R ug+wrx ${DIR_LOCAL_DATA}
done
SKIP
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################		
