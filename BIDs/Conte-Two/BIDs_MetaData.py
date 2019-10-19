#!/usr/bin/python
# -*- coding: latin-1 -*-
################################
### Load Software and Inputs ###
################################

import os
import os.path
import shutil
import glob
import operator
import json
import sys
import numpy as np
import nipype
from collections import OrderedDict
from nipype.interfaces import afni, ants, fsl, utility
from nipype.interfaces.fsl import Merge, Split, ExtractROI

SUBID=sys.argv[1]

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
			addrow="\n{},{},FMAP-PhaseDirWrong".format(SUBID,FileName)
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
OutFinalFunc="/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/fmap/sub-{}_ses-1_acq-dirAP_magnitude2.nii.gz".format(SUBID,SUBID)
merger = Merge()
merger.inputs.in_files=OutInterFiles
merger.inputs.dimension='t'
merger.inputs.output_type='NIFTI_GZ'
merger.inputs.tr=1.5
merger.inputs.merged_file=OutFinalFunc
merger.run()

InputCopyJson=FUNC.replace(".nii.gz",".json")
OutFinalJson=OutFinalFunc.replace(".nii.gz",".json")
COPY=json.load(open(InputCopyJson), object_pairs_hook=OrderedDict)
COPY["SeriesDescription"] = os.path.basename(OutFinalFunc).replace(".nii.gz","")
COPY["ProtocolName"] = os.path.basename(OutFinalFunc).replace(".nii.gz","")
with open(OutFinalJson, "w") as write_file:
    json.dump(COPY, write_file, indent=12)

InterFILES=glob.glob("{}*.nii.gz".format(OutInterBase))
for file in InterFILES:
	os.remove(file)

#############################################################
### Create Magnitude Scans in AP Direction From DWI Files ###
#############################################################

DWI = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/dwi/*.nii.gz'.format(SUBID))[0]
OutFinalDWI=OutFinalFunc.replace("magnitude2.","magnitude1.")
fslroi = ExtractROI(
	in_file=DWI,
	roi_file=OutFinalDWI,
	output_type="NIFTI_GZ",
	t_min=0,
	t_size=1)
fslroi.run()

InputCopyJson=DWI.replace(".nii.gz",".json")
OutFinalJson=OutFinalDWI.replace(".nii.gz",".json")
COPY=json.load(open(InputCopyJson), object_pairs_hook=OrderedDict)
COPY["SeriesDescription"] = os.path.basename(OutFinalDWI).replace(".nii.gz","")
COPY["ProtocolName"] = os.path.basename(OutFinalDWI).replace(".nii.gz","")
with open(OutFinalJson, "w") as write_file:
    json.dump(COPY, write_file, indent=12)

#########################################################
### Combine Doors-Task Runs Into Single 4D BOLD NIFTI ###
#########################################################

EVENTS=glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/func/*task-doors_events.tsv'.format(SUBID))[0]
RUNS=glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/func/*run-*_task-doors_bold.nii.gz'.format(SUBID))
if (len(RUNS) == 3 and os.path.exists(EVENTS)):
	MERGED=RUNS[0].split("_")
	MERGED="{}_{}_{}_{}".format(MERGED[0],MERGED[1],MERGED[3],MERGED[4])
	merger = Merge()
	merger.inputs.in_files=RUNS
	merger.inputs.dimension='t'
	merger.inputs.output_type='NIFTI_GZ'
	merger.inputs.tr=1.5
	merger.inputs.merged_file=MERGED
	merger.run()
	InputCopyJson=RUNS[0].replace(".nii.gz",".json")	
	OutFinalJson=MERGED.replace(".nii.gz",".json")
	COPY=json.load(open(InputCopyJson), object_pairs_hook=OrderedDict)
	COPY["SeriesDescription"] = os.path.basename(MERGED).replace(".nii.gz","")
	COPY["ProtocolName"] = os.path.basename(MERGED).replace(".nii.gz","")
	with open(OutFinalJson, "w") as write_file:
    		json.dump(COPY, write_file, indent=12)
	for nifti in RUNS:
		json=nifti.replace(".nii.gz",".json")
		os.remove(nifti)
		os.remove(json)
else:
	with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/Failed_BIDs_Formatting.csv', 'a') as file:
		addrow="\n{},{},UnexpectedScanRuns".format(SUBID,"DoorsTaskNifti")

##################################################
### Define Intended Use of fmaps in Json Files ###
##################################################

FMAPS = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/fmap/*.json'.format(SUBID))
FUNCS = list(glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/func/*.nii.gz'.format(SUBID)))
DWIS = list(glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-1/dwi/*.nii.gz'.format(SUBID)))
for singlefile in FMAPS:
	Content=json.load(open(singlefile), object_pairs_hook=OrderedDict)
	TYPE=os.path.basename(singlefile).split("_")[3].split(".")[0]
	if TYPE == "magnitude2":
		Content["IntendedFor"]=[FUNCS]
		with open(singlefile , "a") as write_file:
    			json.dump(Content, write_file, indent=12)
	if TYPE == "magnitude1":
		Content["IntendedFor"]=[DWIS]
		with open(singlefile , "a") as write_file:
			json.dump(Content, write_file, indent=12)

###########################################
### Quality Check Of Phasing Directions ###
###########################################






###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
