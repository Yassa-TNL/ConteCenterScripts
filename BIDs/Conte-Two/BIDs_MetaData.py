#!/usr/bin/python
# -*- coding: latin-1 -*-
################################
### Load Software and Inputs ###
################################

import os
import os.path
import shutil
import glob
import json
import sys
import nipype
import operator
import subprocess
import numpy as np
from collections import OrderedDict
from nipype.interfaces import afni, ants, fsl, utility
from nipype.interfaces.fsl import Merge, Split, ExtractROI, ImageMeants

SUBID=str(sys.argv[1])
SITE=str(sys.argv[2])

#######################################################
### Locate Json Files of Functional Images Per Task ###
#######################################################

JSONS = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/fmap/*magnitude*.json'.format(SUBID,SITE))
if JSONS != []:
	for singlefile in JSONS:
		PathName=os.path.dirname(singlefile)
		FileName=os.path.basename(singlefile)
		Content=json.load(open(singlefile), object_pairs_hook=OrderedDict)
		if Content["PhaseEncodingDirection"] != 'j' :
			renamedsinglebase=glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-*/{}/BIDs_Residual/'.format(SUBID))
			renamedsinglefile=os.path.basename(singlefile).replace("acq-dirPA","acq-dirERROR")
			renamedsingle="{}{}".format(renamedsinglebase[0],renamedsinglefile)
			os.rename(singlefile,renamedsingle)
			singlenifti=singlefile.replace(".json",".nii.gz")
			renamednifti=renamedsingle.replace(".json",".nii.gz")
			os.rename(singlenifti,renamednifti)
			with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ScannerAcquistionErrors.csv', 'a') as file:
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

if JSONS == []:
	with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ScansMissingErrors.csv', 'a') as file:
		addrow="\n{},{},ALLFMAPS".format(SUBID,SITE)
		file.write(addrow)

##############################################################
### Create Magnitude Scans in AP Direction From BOLD Files ###
##############################################################

try:
	FUNC = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/func/*.nii.gz'.format(SUBID,SITE))[0]
except:
	FUNC = None

if FUNC is not None:
	Check=json.load(open(FUNC.replace("nii.gz","json")))
	if Check["PhaseEncodingDirection"] == "j-":
		OutInterBase="{}/SPLIT".format(os.path.dirname(FUNC))
		Seperate = fsl.Split(
			in_file=FUNC,
			dimension="t",
			output_type="NIFTI_GZ",
			out_base_name=OutInterBase)
		Seperate.run()
		OutInterFiles=glob.glob("{}*0005.nii.gz".format(OutInterBase))
		OutFinalFunc="/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/fmap/sub-{}_ses-{}_acq-dirAP_magnitude2.nii.gz".format(SUBID,SITE,SUBID,SITE)
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
		COPY["SeriesDescription"] = "fmap-magnitude2_acq-dirPA"
		COPY["ProtocolName"] = "fmap-magnitude2_acq-dirPA"
		with open(OutFinalJson, "w") as write_file:
			json.dump(COPY, write_file, indent=12)
		InterFILES=glob.glob("{}*.nii.gz".format(OutInterBase))
		for file in InterFILES:
			os.remove(file)
	else:
		with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ScannerAcquistionErrors.csv', 'a') as file:
			addrow="\n{},{},FUNC-PhaseDirWrong".format(SUBID,FUNC)
			file.write(addrow)


FUNCS = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/func/*.nii.gz'.format(SUBID,SITE))
if any("_task-doors_" not in s for s in FUNCS):
	with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ScansMissingErrors.csv', 'a') as file:
		addrow="\n{},{},ALLDOORS".format(SUBID,SITE)
		file.write(addrow)

if any("_task-REST_" not in s for s in FUNCS):
	with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ScansMissingErrors.csv', 'a') as file:
		addrow="\n{},{},ALLREST".format(SUBID,SITE)
		file.write(addrow)

##############################################
### Define Task Name of Resting State Scan ###
##############################################

if any("_task-REST_" in s for s in FUNCS):
	RESTING = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/func/*task-REST*.json'.format(SUBID,SITE))
	for REST in RESTING:
		Content=json.load(open(REST), object_pairs_hook=OrderedDict)
		Content['TaskName'] = "REST"
		json.dump(Content, open(REST, "w"), indent=12)

#############################################################
### Create Magnitude Scans in AP Direction From DWI Files ###
#############################################################

try:
	DWI = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/dwi/*.nii.gz'.format(SUBID,SITE))[0]
except:
	DWI = None

if DWI is not None:
	Check=json.load(open(DWI.replace("nii.gz","json")))
	if Check["PhaseEncodingDirection"] == "j-":
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
		COPY["SeriesDescription"] = "fmap-magnitude1_acq-dirAP"
		COPY["ProtocolName"] = "fmap-magnitude1_acq-dirAP"
		with open(OutFinalJson, "w") as write_file:
			json.dump(COPY, write_file, indent=12)
	else:
		with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ScannerAcquistionErrors.csv', 'a') as file:
			addrow="\n{},{},DWI-PhaseDirWrong".format(SUBID,DWI)
			file.write(addrow)

DWIS = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/dwi/*.nii.gz'.format(SUBID,SITE))
if DWIS == []:
	with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ScansMissingErrors.csv', 'a') as file:
		addrow="\n{},{},ALLDWI".format(SUBID,SITE)
		file.write(addrow)

if any("_run-01_" in s for s in DWIS):
	with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ExtraRunErrors.csv', 'a') as file:
		addrow="\n{},{},ExtraDWI".format(SUBID,SITE)
		file.write(addrow)

#################################################
### Reduce Dimensions of MAPS in PA Direction ###
#################################################

try:
	MAG1 = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/fmap/*acq-dirPA_magnitude1.nii.gz'.format(SUBID,SITE))[0]
except:
	MAG1 = None

if MAG1 is not None:
	OutInterBase="{}/SPLIT".format(os.path.dirname(MAG1))
	Seperate = fsl.Split(
		in_file=MAG1,
		dimension="t",
		output_type="NIFTI_GZ",
		out_base_name=OutInterBase)
	Seperate.run()
	OUTPUT=glob.glob('{}000{}*'.format(OutInterBase,"5"))[0]
	os.rename(OUTPUT,MAG1)
	INTERS=glob.glob('{}000*'.format(OutInterBase))
	for INTER in INTERS:
		os.remove(INTER)

try:
	MAG2 = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/fmap/*acq-dirPA_magnitude2.nii.gz'.format(SUBID,SITE))[0]
except:
	MAG2 = None

if MAG2 is not None:
	OutInterBase="{}/SPLIT".format(os.path.dirname(MAG2))
	Seperate = fsl.Split(
		in_file=MAG2,
		dimension="t",
		output_type="NIFTI_GZ",
		out_base_name=OutInterBase)
	Seperate.run()
	OUTPUT=glob.glob('{}0004.nii.gz'.format(OutInterBase))[0]
	os.rename(OUTPUT,MAG2)
	INTERS=glob.glob('{}000*.nii.gz'.format(OutInterBase))
	for INTER in INTERS:
		os.remove(INTER)

#########################################################
### Combine Doors-Task Runs Into Single 4D BOLD NIFTI ###
#########################################################

try:
	EVENTS = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/func/*task-doors_events.tsv'.format(SUBID,SITE))[0]
except:
	EVENTS = None

RUNS=glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/func/*run-*_task-doors_bold.nii.gz'.format(SUBID,SITE))
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
	import json
	COPY=json.load(open(InputCopyJson), object_pairs_hook=OrderedDict)
	COPY["SeriesDescription"] = "func_task-doors_bold"
	COPY["ProtocolName"] = "func_task-doors_bold"
	COPY["TaskName"] = "doors"
	json.dump(COPY, open(OutFinalJson, "w"), indent=12)
	for nifti in RUNS:
		json=nifti.replace(".nii.gz",".json")
		os.remove(nifti)
		os.remove(json)

if RUNS != []:
	if (len(RUNS) != 3 and os.path.exists(EVENTS)):
		with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ExtraRunErrors.csv', 'a') as file:
			addrow="\n{},{},ExtraDoors".format(SUBID,SITE)

if any("_run-01_" in s for s in FUNCS):
	with open('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-Two/logs/ExtraRunErrors.csv', 'a') as file:
		addrow="\n{},{},ExtraREST".format(SUBID,SITE)
		file.write(addrow)

##################################################
### Define Intended Use of fmaps in Json Files ###
##################################################

FMAPS = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/fmap/*.json'.format(SUBID,SITE))
FUNCS = str(glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/func/*.nii.gz'.format(SUBID,SITE))).strip('[]')
DWIS = str(glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}/ses-{}/dwi/*.nii.gz'.format(SUBID,SITE))).strip('[]')

if FMAPS != []:
	for updatefile in FMAPS:
		import json
		Content=json.load(open(updatefile), object_pairs_hook=OrderedDict)
		if Content["SeriesDescription"].split("_")[0] == 'fmap-magnitude2':
			Content["IntendedFor"]=[FUNCS]
			json.dump(Content, open(updatefile, "w"), indent=12)
		if Content["SeriesDescription"].split("_")[0] == 'fmap-magnitude1':
			Content["IntendedFor"]=[DWIS]
			json.dump(Content, open(updatefile, "w"), indent=12)

subprocess.call(['chmod', '-R', 'ug+wrx', '/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-{}'.format(SUBID)])
qsublogs=glob.glob("{}/{}{}C.*".format(os.getcwd(),SITE,SUBID))
for qlog in qsublogs:
	os.remove(qlog)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
