#!/bin/sh
###################################################################################################
##########################               CONTE Center 1.0                ##########################
##########################               Robert Jirsaraie                ##########################
##########################               rjirsara@uci.edu                ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡ #####
###################################################################################################

module load freesurfer/6.0

#############################################################
##### Define the Subjects of Interest and Load Software #####
#############################################################

free_dir=/dfs2/yassalab/rjirsara/ConteCenter/freesurfer/Conte-One-DBK
subjects=`ls $free_dir | grep 861_tp`

#####################################
##### View the Processed Images #####
#####################################

for s in $subjects ; do

freeview -v \
${free_dir}/${s}/mri/T1.mgz \
${free_dir}/${s}/mri/wm.mgz \
${free_dir}/${s}/mri/brainmask.mgz \
${free_dir}/${s}/mri/aseg.mgz:colormap=lut:opacity=0.2 \
-f ${free_dir}/${s}/surf/lh.white:edgecolor=blue \
${free_dir}/${s}/surf/lh.pial:edgecolor=red \
${free_dir}/${s}/surf/rh.white:edgecolor=blue \
${free_dir}/${s}/surf/rh.pial:edgecolor=red \
-viewport cor -layout 1

done

#####################################
##### View the Processed Images #####
#####################################

for s in $subjects ; do

freeview -f  ${free_dir}/${s}/surf/lh.pial:annot=aparc.annot:name=pial_aparc:visible=0 \
${free_dir}/${s}/surf/lh.pial:annot=aparc.a2009s.annot:name=pial_aparc_des:visible=0 \
${free_dir}/${s}/surf/lh.inflated:overlay=lh.thickness:overlay_threshold=0.1,3::name=inflated_thickness:visible=0 \
${free_dir}/${s}/surf/lh.inflated:visible=0 \
${free_dir}/${s}/lh.white:visible=0 \
${free_dir}/${s}/lh.pial \
--viewport 3d

done

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡ #####
###################################################################################################
