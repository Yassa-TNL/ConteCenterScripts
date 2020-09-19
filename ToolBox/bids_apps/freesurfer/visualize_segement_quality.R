#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load freesurfer/6.0

###################################################################
##### Define the Subjects-Level Directories & the Output Path #####
###################################################################


function viewfreesurfer(){
        if [ $# -ne  1 ]; then
                echo "Usage: viewfreesurfer [PATH_TO_FS_SUBJ_DIR]";
        else
                `freeview -v "$1"/mri/T1.mgz \ 
		"$1"/mri/wm.mgz \
		"$1"/mri/brainmask.mgz \
		"$1"/mri/aparc+aseg.mgz:colormap=lut:opacity=0.4 \
		-f "$1"/surf/lh.white:edgecolor=blue \
		   "$1"/surf/lh.pial:edgecolor=red \
		   "$1"/surf/rh.white:edgecolor=blue \
		   "$1"/surf/rh.pial:edgecolor=red`

        fi
}

###################################################################
##### Define the Subjects-Level Directories & the Output Path #####
###################################################################

/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-One
