#!/usr/bin/python
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
'''

Philips Scanners do not store all the metadata needed for preprocessing of functional images. This script
manually adds additional information about phase encoding direction and slice time information to the json
files that were outputed during the BIDs Conversion.

'''
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

from __future__ import division
import numpy as np
import shutil as cp
import os
import os.path
import glob
import operator
import pandas as pd

#######################################################
### Locate Json Files of Functional Images Per Task ###
#######################################################

def LocateFiles(TaskName):
        json = '/dfs2/yassalab/rjirsara/ConteCenter/BIDs/Conte-One/*/*/func/*{}*.json'.format(TaskName)
        json = glob.glob(json)
        return json

JSONS_Hippocampus=LocateFiles('HIPP')
JSONS_Resting=LocateFiles('REST')
JSONS_Amygdala=LocateFiles('AMG')

###########################
### Relabel Tasks Names ###
###########################


#####################################################
### Add Phase Direction Information AP: j, PA: -j ###
#####################################################

"PhaseEncodingDirection": "j",
"PhaseEncodingDirection": "j",

###############################################################
###    Slice Timing Information Based on Scanner Protocol   ###
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


STI_Resting=DefaultSliceTiming(2,51)
STI_Hippocampus=DefaultSliceTiming(2,51)
STI_Amygdala=DefaultSliceTiming(2,42)




###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
