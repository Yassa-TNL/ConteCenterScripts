
#!/bin/bash
###################################################################################################
##########################              CONTE Center 2.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script uses software from optseq2 to create a rapid-presentation event rate for trails of the 
Doors Guessing Task. The aim is to define the optimal timing of events that will allow for varying
amounts of overlap between each trail to better track the hemodynamic responce function.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load afni/v19.0.01

/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fMRItasks/Conte-Two/optseq2 --ntp 110 --tr 2 \
--psdwin 0 20 2 --ev WIN 6 11 --ev LOSS 6 11  --tprescan -10 --evc 1 -1 --nkeep 3 --o Doors --tnullmin 2 \
--tnullmax 10 --nsearch 1000


/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fMRItasks/Conte-Two/optseq2 --ntp 110 --tr 2 \
--psdwin 0 20 2 --ev WIN 6 13 --ev LOSS 6 13  --tprescan -12 --evc 1 -1 --nkeep 3 --o TRY2 --tnullmin 2 \
--tnullmax 10 --nsearch 1000

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################