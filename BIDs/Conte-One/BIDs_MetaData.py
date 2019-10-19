#!/usr/bin/python
# -*- coding: latin-1 -*-##################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
'''

Philips Scanners do not store all the metadata needed for preprocessing of functional images. This script
manually adds additional information about phase encoding direction and slice time information to the json
files that were outputed during the BIDs Conversion.

'''
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

from collections import OrderedDict
from __future__ import division
import os
import os.path
import glob
import operator
import json

#######################################################
### Locate Json Files of Functional Images Per Task ###
#######################################################

def LocateFiles(TaskName):
        json = '/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/*/*/func/*{}*.json'.format(TaskName)
        json = glob.glob(json)
        return json

JSONS_REST=LocateFiles('REST')
JSONS_HIPP=LocateFiles('HIPP')
JSONS_AMG=LocateFiles('AMG')

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
