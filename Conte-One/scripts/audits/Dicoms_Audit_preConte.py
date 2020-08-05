#!/usr/bin/python
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

import pandas as pd
import nibabel as nb
import numpy as np
import shutil as cp
import os
import os.path
import glob 

###########################################
### Copy Files Into Temp Data Structure ###
###########################################

audit = pd.read_csv('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/Audit_Master_ConteMRI.csv')
base = audit.loc[audit['Session'] == 0]
base_maxrows = base.shape[0]

for row in range(base_maxrows):
	subid = base.iloc[row][0]
	MRIses = base.iloc[row][1]
	dir_output = '/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-PreOne/{}_0_{}/NIFTIS'.format(subid,MRIses)
    	if not os.path.isdir(dir_output):
        	os.makedirs(dir_output)
	input_files = '/dfs2/yassalab/ConteCenter/1point0/preConte/LACIE_SHARE/all-Nifti_files_asof_sept21-09/{}.*'.format(subid)
	input_files = glob.glob(input_files)
	subid
	if input_files != "":
		for FILE in input_files:
			cp.copy(FILE, dir_output)
			print('Copying File: {}'.format(FILE))

##############################
### Convert Files to NIFTI ###
##############################

images = '/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-PreOne/*/*/*.img'
images = glob.glob(images)

for image in images:
	fname = image  
	img = nb.load(fname)
	nb.save(img, fname.replace('.img', '.nii.gz'))
	print('Coverting this image: {}'.format(image))

#################################################
### Copy Existing Files to Aggregated Dataset ###
#################################################

NIFTIS = '/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-PreOne/*/*/*.nii.gz'
NIFTIS = glob.glob(NIFTIS)

for nii in NIFTIS:
	subid = os.path.basename(nii)
	subid = os.path.splitext(subid)[0]
 	subid = os.path.splitext(subid)[0]
	PATH='/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/{}_0_0/NIFTIS/'.format(subid)
	if not os.path.isdir(PATH):
        	os.makedirs(PATH)
	OUTPUT='{}/sub-{}_ses-0_T1w.nii.gz'.format(PATH,subid)
	cp.copy(nii, OUTPUT)
	print('Finalizing for Subject: {}'.format(subid))

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
