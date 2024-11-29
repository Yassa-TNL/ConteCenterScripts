#!/usr/bin/python
# -*- coding: latin-1 -*-
#########################

from __future__ import division
from shutil import copyfile
from collections import OrderedDict
from nipype.interfaces import afni, ants, fsl, utility
from nipype.interfaces.fsl import FSLCommand, Merge, Split, ExtractROI, ImageMeants
import warnings, operator, subprocess, nipype, nibabel as nib
import re, os, os.path, sys, glob, json, fnmatch, shutil
warnings.simplefilter(action='ignore', category=FutureWarning)

DIR_PROJECT=str(sys.argv[1])
OPT_GEN_FMAP_FUNC=str(sys.argv[2])
OPT_GEN_FMAP_DWI=str(sys.argv[3])
OPT_ADD_DEFAULT_ST=str(sys.argv[4])

########################################################
### Define Data Structure and Files For All Subjects ###
########################################################

DICT_DIR = {'j-': 'AP', 'j': 'PA', 'i-': 'RL', 'i': 'LR'}

def insensitive_glob(pattern):
	def either(c):
		return '[%s%s]' % (c.lower(), c.upper()) if c.isalpha() else c
	return glob.glob(''.join(map(either, pattern)))

def directory_structure(directory):
	file_paths = []
	for root, directories, files in os.walk(directory):
		for filename in files:
			filepath = os.path.join(root, filename)
			file_paths.append(filepath)
	return file_paths

for DIR_SUB in glob.glob("{}/sub-*".format(DIR_PROJECT)):
	print(DIR_SUB)
	ANAT_SCANS=list(filter(lambda x:'/anat/sub-' in x, directory_structure(DIR_SUB)))
	DWI_SCANS=list(filter(lambda x:'/dwi/sub-' in x, directory_structure(DIR_SUB)))
	FMAP_SCANS=list(filter(lambda x:'/fmap/sub-' in x, directory_structure(DIR_SUB)))
	FUNC_SCANS=list(filter(lambda x:'/func/sub-' in x, directory_structure(DIR_SUB)))
		
######################################################
### If Specified Create FMAP From FUNC NIFTI Files ###
######################################################
	
	EPI_FMAP=list(filter(lambda x: "_epi.nii.gz" in x, FMAP_SCANS))
	if OPT_GEN_FMAP_FUNC == "TRUE" and FUNC_SCANS and EPI_FMAP:
		JSON=list(filter(lambda x: "_bold.json" in x, FUNC_SCANS))[0]
		NIFTI=list(filter(lambda x: "_bold.nii.gz" in x, FUNC_SCANS))[0]
		TEMP_OUTPUT=list(filter(lambda x: "_epi.nii.gz" in x, FMAP_SCANS))[0]
		Seperate = fsl.Split(
			in_file = NIFTI,
			dimension = "t",
			output_type = "NIFTI_GZ",
			out_base_name = EPI_FMAP[0])
		Seperate.run()
		CONTENT=json.load(open(JSON), object_pairs_hook=OrderedDict)
		CONTENT.pop('SliceTiming',None)
		PHASE_NEW=DICT_DIR.get(CONTENT.get("PhaseEncodingDirection"))
		PHASE_RENAME=TEMP_OUTPUT.replace([x for x in TEMP_OUTPUT.split("_") if "dir-" in x][0],"dir-{}".format(PHASE_NEW))
		os.rename(TEMP_OUTPUT.replace(".nii.gz",".nii.gz0000.nii.gz"),PHASE_RENAME)
		json.dump(CONTENT, open(PHASE_RENAME.replace("nii.gz","json"), "w"), indent=12)
		for TEMP in glob.glob(TEMP_OUTPUT.replace(".nii.gz",".nii.gz*.nii.gz")):
			os.remove(TEMP)
		FMAP_SCANS=list(filter(lambda x:'/fmap/sub-' in x, directory_structure(DIR_SUB)))
		
#####################################################
### If Specified Create FMAP From DWI NIFTI Files ###
#####################################################
	
	DWI_FMAP=list(filter(lambda x: "_dwi.nii.gz" in x, FMAP_SCANS))
	if OPT_GEN_FMAP_DWI == "TRUE" and DWI_SCANS and DWI_FMAP:
		JSON=list(filter(lambda x: "_dwi.json" in x, DWI_SCANS))[0]
		NIFTI=list(filter(lambda x: "_dwi.nii.gz" in x, DWI_SCANS))[0]
		CONTENT=json.load(open(JSON), object_pairs_hook=OrderedDict)
		CONTENT.pop('SliceTiming',None)
		PHASE_NEW=DICT_DIR.get(CONTENT.get("PhaseEncodingDirection"))
		TEMP_OUTPUT=list(filter(lambda x: "_dwi.nii.gz" in x, FMAP_SCANS))[0].replace("","")
		OUTPUT=TEMP_OUTPUT.replace([x for x in TEMP_OUTPUT.split("_") if "dir-" in x][0],"dir-{}".format(PHASE_NEW))
		Extract = ExtractROI(
			in_file=NIFTI,
			roi_file=OUTPUT,
			output_type="NIFTI_GZ",
			t_min=0,
			t_size=1)
		Extract.run()
		json.dump(CONTENT, open(OUTPUT.replace("nii.gz","json"), "w"), indent=12)
		FMAP_SCANS=list(filter(lambda x:'/fmap/sub-' in x, directory_structure(DIR_SUB)))
	
#########################################################################
### If Specified Add Slice Timing Information - Philips Default Order ###
#########################################################################
	
	if OPT_ADD_DEFAULT_ST == "TRUE" and FUNC_SCANS:
		for TASK in [x for x in " ".join(list(filter(lambda x: ".nii.gz" in x, FUNC_SCANS))).split("_") if "task-" in x]:
			NIFTI=nib.load([x for x in FUNC_SCANS if "{}_bold.nii.gz".format(TASK) in x ][0])
			nSlices=NIFTI.shape[2]
			TRsec=NIFTI.header.get_zooms()[-1]
			TA=TRsec/nSlices
			HalfPoint=int(nSlices/2)
			ONE=range(HalfPoint)
			TWO=range(HalfPoint)
			if nSlices % 2 > 0:
				HalfPoint=int(nSlices/2)+1
				ONE=range(HalfPoint)
				first=[]
				for x in ONE:
					TimeofSliceODD=TA*x
					first.append(TimeofSliceODD)
					TWO=range(HalfPoint)
					TWO.pop(0)
				second=[]
				for y in TWO:
					TAmaxODD=max(enumerate(first), key=operator.itemgetter(1))[1]
					TimeofSliceEVEN=TA*y
					TimeofSliceEVEN=TimeofSliceEVEN+TAmaxODD
					second.append(TimeofSliceEVEN)
					IndexmaxEVEN=max(enumerate(second), key=operator.itemgetter(1))[0]
				final=[]
				INDEXmaxODD=max(enumerate(first), key=operator.itemgetter(1))[0]
				for z in range(IndexmaxEVEN+1):
					final.append(first[z])
					final.append(second[z])
					final.append(first[INDEXmaxODD])
			else:
				HalfPoint=int(nSlices/2)
				ONE=range(HalfPoint)
				first=[]
				for x in ONE:
					TimeofSliceODD=TA*x
					first.append(TimeofSliceODD)
					TWO=range(HalfPoint)
				second=[]
				for y in TWO:
					TAmaxODD=max(enumerate(first), key=operator.itemgetter(1))[1]
					y_trueval=y+1
					TimeofSliceEVEN=TA*y_trueval
					TimeofSliceEVEN=TimeofSliceEVEN+TAmaxODD
					second.append(TimeofSliceEVEN)
				final=[]
				for z in TWO:
					final.append(first[z])
					final.append(second[z])
			for JSON in [x for x in FUNC_SCANS if "{}_bold.json".format(TASK) in x ]:
				CONTENT=json.load(open(JSON), object_pairs_hook=OrderedDict)	
				CONTENT['SliceTiming'] = final
				LISTOFCONTENT=list(CONTENT.items())
				POSITION = [i for i, s in enumerate(LISTOFCONTENT) if 'TrueEchoSpacing' in s]
				REORDER_DICT= []
				for NUM in range(0, len(CONTENT)-1):
					REORDER_DICT.append(NUM)
				REORDER_DICT.insert(POSITION[0]+1,len(CONTENT)-1)
				CONTENT=OrderedDict([LISTOFCONTENT[i] for i in REORDER_DICT])
				json.dump(CONTENT, open(JSON, "w"), indent=12)
	
#############################################################
### Create Directionary Keys of Task Names for FUNC Scans ###
#############################################################
	
	if FUNC_SCANS:
		FUNC_JSONS=list(filter(lambda x:'bold.json' in x, FUNC_SCANS))
		for FUNC_JSON in FUNC_JSONS:
			if any(not 'task-' for elem in os.path.basename(FUNC_JSON).split("_")):
				Error = open(os.path.join('.', 'Fatal_BIDS_Error.txt'), 'w')
				Error.write('BOLD Labels Do Not Include Task Name')
				Error.close()
				sys.exit()
			else:
				LABEL=os.path.basename(FUNC_JSON).split("_")
				INDEX=[i for i, s in enumerate(LABEL) if 'task-' in s]
				TASKLABEL=LABEL[INDEX[0]].split("-")[1]
				CONTENT=json.load(open(FUNC_JSON), object_pairs_hook=OrderedDict)
				CONTENT['TaskName'] = TASKLABEL
				LISTOFCONTENT=list(CONTENT.items())
				POSITION = [i for i, s in enumerate(LISTOFCONTENT) if 'ProtocolName' in s]
				REORDER_DICT= []
				for NUM in range(0, len(CONTENT)-1):
					REORDER_DICT.append(NUM)
				REORDER_DICT.insert(POSITION[0]+1,len(CONTENT)-1)
				CONTENT=OrderedDict([LISTOFCONTENT[i] for i in REORDER_DICT])
				json.dump(CONTENT, open(FUNC_JSON, "w"), indent=12)
	
#################################################################
### Define FMAPS Intended Use For their Respective Modalities ###
#################################################################

	for TYPE in " ".join(list(set([x for x in "_".join(FMAP_SCANS).split("_") if ".nii.gz" in x]))).replace(".nii.gz","").split(" "):
		if TYPE == "":
			break
		if TYPE == "epi" and FMAP_SCANS and FUNC_SCANS:
			FILES=[x for x in FUNC_SCANS if ".nii.gz" in x]
		if TYPE == "dwi" and FMAP_SCANS and DWI_SCANS:	
			FILES=[x for x in DWI_SCANS if ".nii.gz" in x]
		SUBID=os.path.basename(DIR_SUB).replace("sub-","")
		INTENT="@".join(FILES).replace(f"{DIR_PROJECT}/sub-{SUBID}/","").split("@")
		for JSON in [x for x in FMAP_SCANS if "{}.json".format(TYPE) in x]:
			CONTENT=json.load(open(JSON), object_pairs_hook=OrderedDict)
			CONTENT["IntendedFor"] = INTENT
			LISTOFCONTENT=list(CONTENT.items())
			POSITION = [i for i, s in enumerate(LISTOFCONTENT) if "PhaseEncodingDirection" in s]
			REORDER_DICT= []
			for NUM in range(0, len(CONTENT)-1):
				REORDER_DICT.append(NUM)
			REORDER_DICT.insert(POSITION[0]-1,len(CONTENT)-1)
			CONTENT=OrderedDict([LISTOFCONTENT[i] for i in REORDER_DICT])
			json.dump(CONTENT, open(JSON, "r+"), indent=12)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################