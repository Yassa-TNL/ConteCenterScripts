#!/usr/bin/python
###################################################################################################
##########################              CONTE Center 2.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡   ⚡  #####
###################################################################################################
'''
This script executes a quality assurance check to ensure PA field maps were acquired properly. Secondly,
it calculates AP feild maps to be stored seperately for distortion correction. Lastly, Doors-Task scans 
are merged into single run.
'''
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡   ⚡  #####
###################################################################################################

from collections import OrderedDict
from __future__ import division
import os
import os.path
import shutil
import glob
import operator
import json
import sys
import numpy as np
from nipype.interfaces import afni, ants, fsl, utility as niu
from nipype.interfaces.fsl import Merge, Split

SUBID=sys.argv[0]

#######################################################
### Locate Json Files of Functional Images Per Task ###
#######################################################

JSONS = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/fmap/*magnitude*.json'.format(SUBID))

for singlefile in JSONS:
	PathName=os.path.dirname(singlefile)
	FileName=os.path.basename(singlefile)
	Content=json.load(open(singlefile), object_pairs_hook=OrderedDict)
	if Content["PhaseEncodingDirection"] != u'j' :
		renamedsinglebase=glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-*/{}/BIDs_Residual/'.format(SUBID))
		renamedsinglefile=os.path.basename(singlefile).replace("acq-dirPA","acq-dirAP")
		renamedsingle="{}{}".format(renamedsinglebase[0],renamedsinglefile)
		os.rename(singlefile,renamedsingle)
		singlenifti=singlefile.replace(".json",".nii.gz")
		renamednifti=renamedsingle.replace(".json",".nii.gz")
		os.rename(singlenifti,renamednifti)
		with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/Failed_BIDs_Formatting.csv', 'a') as file:
			addrow="\n{},{},WrongPhasingDir".format(SUBID,FileName)
			file.write(addrow)
	elif FileName.find("_run-") != -1:
		FileNameParts=FileName.split("_")
		FileNameNew="{}_{}_{}_{}".format(FileNameParts[0],FileNameParts[1],FileNameParts[2],FileNameParts[4])
		FileNameNew="{}/{}".format(PathName,FileNameNew)
		os.rename(singlefile,FileNameNew)
 		singlenifti=singlefile.replace(".json",".nii.gz")
		renamednifti=FileNameNew.replace(".json",".nii.gz")
		os.rename(singlenifti,renamednifti)

##############################################################
### Create Magnitude Scans in AP Direction From BOLD Files ###
##############################################################

FUNC = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/func/*.nii.gz'.format(SUBID))[0]
OutInterBase="{}/SPLIT".format(os.path.dirname(FUNC))
Seperate = fsl.Split(
	in_file=FUNC,
	dimension="t",
	output_type="NIFTI_GZ",
 	out_base_name=OutInterBase)
Seperate.run()

OutInterFiles=glob.glob("{}*000[1-5].nii.gz".format(OutInterBase))
OutFinalFile="/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/fmap/sub-{}_ses-1_acq-dirAP_magnitude2.nii.gz".format(SUBID,SUBID)
merger = Merge()
merger.inputs.in_files=OutInterFiles
merger.inputs.dimension='t'
merger.inputs.output_type='NIFTI_GZ'
merger.inputs.tr=1.5
merger.inputs.merged_file=OutFinalFile
merger.run()

InputCopyJson=FUNC.replace(".nii.gz",".json")
OutFinalJson=OutFinalFile.replace(".nii.gz",".json")
COPY=json.load(open(InputCopyJson), object_pairs_hook=OrderedDict)
COPY["SeriesDescription"] = os.path.basename(OutFinalFile).replace(".nii.gz","")
COPY["ProtocolName"] = os.path.basename(OutFinalFile).replace(".nii.gz","")
with open(OutFinalJson, "w") as write_file:
    json.dump(COPY, write_file, indent=12)

InterFILES=glob.glob("{}*.nii.gz".format(OutInterBase))
for file in InterFILES:
	os.remove(file)

##############################################################
### Create Magnitude Scans in AP Direction From BOLD Files ###
##############################################################

events=glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/func/*task-doors*.tsv'.format(SUBID))