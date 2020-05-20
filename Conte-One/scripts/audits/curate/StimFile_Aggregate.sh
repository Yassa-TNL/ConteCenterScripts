#!/bin/bash
###########

DIR_LOCAL_BIDS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/bids
DIR_LOCAL_AUDITS=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits
mkdir -p $DIR_LOCAL_APPS $DIR_LOCAL_DATA

module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

########################################################
### If Missing Build the XCPEngine Singularity Image ###
########################################################

for LABEL in `find ${DIR_LOCAL_BIDS} -iname *task-AMG*` ; do

	SUB=`basename $LABEL | cut -d '_' -f1 | cut -d '-' -f2`
	SES=`basename $LABEL | cut -d '_' -f2 | cut -d '-' -f2`
	echo $SUB $SES

	



done
