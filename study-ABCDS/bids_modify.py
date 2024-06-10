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
	
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######
####           ⚡     ⚡    ⚡   ⚡   ⚡   ⚡  ⚡  ⚡  ⚡    ⚡  ⚡  ⚡  ⚡   ⚡   ⚡   ⚡    ⚡     ⚡         ####
########⚡⚡⚡⚡⚡⚡#################################⚡⚡⚡⚡⚡⚡################################⚡⚡⚡⚡⚡⚡#######