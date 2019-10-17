#!/usr/bin/python
###################################################################################################
##########################              CONTE Center 2.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
'''

This script executes a quality assurance check to ensure PA field maps were acquired properly. Secondly,
it calculates AP feild maps to be stored seperately for distortion correction. Lastly, Doors-Task scans 
are merged into single run.

'''
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
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
from nipype.pipeline import engine as pe
from nipype.interfaces import afni, ants, fsl, utility as niu

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

fslsplit = pe.Node(fsl.Split(dimension='t'), name='ImageHMCSplit')

FSLSplit(dimension='t', in_file=FUNC, out_files="/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-Pilot2T/ses-1/func/test-Pilot2T_ses-1_run-03_task-doors_bold.nii.gz")




split = pe.MapNode(fsl.Split(dimension='t'), iterfield='in_file',name='split')

fsl.Split(dimension='t'), iterfield=FUNC, name='split')












'''
JSONS = glob.glob('/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-Two/sub-*/ses-*/fmap/*{}*.json'.format("magnitude"))
for singlefile in JSONS:	






# Move a file by renaming it's path
os.rename('/Users/billy/d1/xfile.txt', '/Users/billy/d2/xfile.txt')

# Move a file from the directory d1 to d2
shutil.move('/Users/billy/d1/xfile.txt', '/Users/billy/d2/xfile.txt')




if nSlices % 2 > 0:





def LocateFiles(TaskName):

        return json

JSONS_One=LocateFiles('magnitude1')
JSONS_Two=LocateFiles('magnitude2')








for singlefile in JSONS_One:
	Content=json.load(open(singlefile), object_pairs_hook=OrderedDict)
	Content 




	for singlefile in JSONS:
		Content=json.load(open(singlefile), object_pairs_hook=OrderedDict)
		if 'SliceTiming' in Content.keys():
			print ''
  			print "Information Already Appended for Following File:"
			print singlefile
		else:
			software=Content['ConversionSoftware']
			del Content['ConversionSoftware']
			version=Content['ConversionSoftwareVersion']
			del Content['ConversionSoftwareVersion']
			Content["TaskName"] = taskname
			Content["SliceTiming"] = STI
			Content["PhaseEncodingDirection"] = PhaseEncod #AP= j RL= i
			Content["ConversionSoftware"] = software
			Content["ConversionSoftwareVersion"] = version
			Content["ImageType"]=['ORIGINAL','PRIMARY','M','FFE','M','FFE']
			print "Outputing File:"			
			print(singlefile)
			print(Content)			
			with open(singlefile, "w") as write_file:
    				json.dump(Content, write_file, indent=12)




for singlefile in JSONS_One:




###############################################################
###            Define Slice Timing Information              ###
### 51/42 Slices, TR: 2, Default Slice Order/Single Package ###
###############################################################

def DefaultSliceTiming(TRsec,nSlices):
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
    return(final)


STI_REST=DefaultSliceTiming(2,51)
STI_HIPP=DefaultSliceTiming(2,51)
STI_AMG=DefaultSliceTiming(2,42)

###########################################
### Append New Information in Json File ###
###  Phasing Direction: AP = j RL = i   ###
###########################################

def AppendJsonFiles(JSONS,STI,taskname,PhaseEncod):
	for singlefile in JSONS:
		Content=json.load(open(singlefile), object_pairs_hook=OrderedDict)
		if 'SliceTiming' in Content.keys():
			print ''
  			print "Information Already Appended for Following File:"
			print singlefile
		else:
			software=Content['ConversionSoftware']
			del Content['ConversionSoftware']
			version=Content['ConversionSoftwareVersion']
			del Content['ConversionSoftwareVersion']
			Content["TaskName"] = taskname
			Content["SliceTiming"] = STI
			Content["PhaseEncodingDirection"] = PhaseEncod #AP= j RL= i
			Content["ConversionSoftware"] = software
			Content["ConversionSoftwareVersion"] = version
			Content["ImageType"]=['ORIGINAL','PRIMARY','M','FFE','M','FFE']
			print "Outputing File:"			
			print(singlefile)
			print(Content)			
			with open(singlefile, "w") as write_file:
    				json.dump(Content, write_file, indent=12)


AppendJsonFiles(JSONS_REST,STI_REST,'REST','j')
AppendJsonFiles(JSONS_HIPP,STI_HIPP,'HIPP','i')
AppendJsonFiles(JSONS_AMG,STI_AMG,'AMG','j')

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
