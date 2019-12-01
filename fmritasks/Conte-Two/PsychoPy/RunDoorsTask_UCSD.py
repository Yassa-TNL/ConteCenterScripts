#!/usr/bin/env python2
# -*- coding: utf-8 -*-
###################################################################################################
##########################              CONTE Center 2.0                 ##########################
##########################    Robert Jirsaraie & Stephanie Doering       ##########################
##########################    rjirsara@uci.edu & doerings@uci.edu        ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
'''

Runs all 3 blocks of the Doors Task and Processes log file if task runs to completion. This custom-verion
was designed to be used on the 3T Seimens MRI scanner at UC Irvine. 

'''
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

from __future__ import absolute_import, division
from psychopy.constants import (NOT_STARTED, STARTED, PLAYING, PAUSED,
                                STOPPED, FINISHED, PRESSED, RELEASED, FOREVER)
import os, sys, time, csv, re
import pandas as pd
import numpy as np
from numpy import (sin, cos, tan, log, log10, pi, average,
                   sqrt, std, deg2rad, rad2deg, linspace, asarray)
from numpy.random import random, randint, normal, shuffle
from psychopy import locale_setup, sound, gui, visual, core, data, event, logging

# Ensure that relative paths start from the same directory as this script
_thisDir = os.path.dirname(os.path.abspath(__file__)).decode(sys.getfilesystemencoding())
os.chdir(_thisDir)

# Store info about the experiment session
expTime = time.strftime("%H-%M_%Y%m%d", time.localtime())
expInfo = {'participant':''}
expName = 'DoorsTask'
fname='{}_{}'.format(expName,expTime)
dlg = gui.DlgFromDict(dictionary=expInfo, title=fname)
if dlg.OK == False:
    core.quit()

# Read in jitter csv files
currentDir = os.getcwd()
jitterPath = os.path.join(currentDir, 'JitterOutput')
files = os.listdir(jitterPath)
files = [fi for fi in files if fi[-4:]=='.csv']
shuffle(files)
files = files[:3]
blockTrials = []
blockIntervals = []

# Prepare Log Files
currentDir = os.getcwd()
defaultLogDir = os.path.join(currentDir, "logs")
logDir = os.path.join(currentDir, "data")
filename = os.path.join(logDir, u"%s_%s" % (expInfo['participant'], fname))
f = open(filename+ '.txt', 'w')
f.write("Doors Task: %s\nRandomized Jitter Order: %s\nSubject ID: %s\nBeginning Task..." %(expTime, files, expInfo['participant']))
logging.console.setLevel(logging.WARNING)  # this outputs to the screen, not a file
endExpNow = False  # flag for 'escape' or other condition => quit the exp

for item in files:
    with open(os.path.join(jitterPath,item), 'r') as csvfile:
        reader = csv.reader(csvfile)
        jitterData = [r for r in reader]
        jitterData = jitterData[1:]
        trials = [jitterData[t] for t in range(len(jitterData)) if t%2 ==0]
        intervals = [jitterData[t] for t in range(len(jitterData)) if t%2 ==1]
        
        blockTrials.append(trials)
        blockIntervals.append(intervals)

blockIntervals = [[float(blockIntervals[x][y][1]) for y in range(len(blockIntervals[x]))] for x in range(len(blockIntervals))]
blockTrials = [[blockTrials[x][y][2] for y in range(len(blockTrials[x]))] for x in range(len(blockTrials))]

# Set Up Experiment Window
win = visual.Window(
    size=(1366, 768), fullscr=True, screen=0,
    allowGUI=False, allowStencil=False,
    monitor='testMonitor', color=[1, 1, 1], colorSpace='rgb',
    blendMode='avg', useFBO=True)

# store frame rate of monitor if we can measure it
expInfo['frameRate'] = win.getActualFrameRate()
if expInfo['frameRate'] != None:
    frameDur = 1.0 / round(expInfo['frameRate'])
else:
    frameDur = 1.0 / 60.0  # could not measure, so guess

imagesDir = os.path.join(currentDir, "images")

## SET UP THE ROUTINE INFO
# Initialize Intro1
Intro1 = visual.ImageStim(
    win=win, name='Intro1',
    image=os.path.join(imagesDir, 'Intro1.png'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Intro2
Intro2 = visual.ImageStim(
    win=win, name='Intro2',
    image=os.path.join(imagesDir, 'Intro2.png'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize TakeBreak
TakeBreak = visual.ImageStim(
    win=win, name='TakeBreak',
    image=os.path.join(imagesDir, 'TakeBreak.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize GetReady
GetReady = visual.ImageStim(
    win=win, name='GetReady',
    image=os.path.join(imagesDir, 'GetReady.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Fixation
Fixation = visual.ImageStim(
    win=win, name='Fixation',
    image=os.path.join(imagesDir, 'Fixation.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Doors
Doors = visual.ImageStim(
    win=win, name='Doors',
    image=os.path.join(imagesDir, 'Doors.png'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize SelectLeft
SelectLeft = visual.ImageStim(
    win=win, name='SelectLeft',
    image=os.path.join(imagesDir, 'SelectLeft.png'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize SelectRight
SelectRight = visual.ImageStim(
    win=win, name='SelectRight',
    image=os.path.join(imagesDir, 'SelectRight.png'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Correct
Correct = visual.ImageStim(
    win=win, name='Correct',
    image=os.path.join(imagesDir, 'Correct.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Wrong
Wrong = visual.ImageStim(
    win=win, name='Wrong',
    image=os.path.join(imagesDir, 'Wrong.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize WrongNoSelection
# added later if no response should result in a different screen than Wrong

# Initialize EndExperiment
EndExperiment = visual.ImageStim(
    win=win, name='EndExperiment',
    image=os.path.join(imagesDir, 'EndExperiment.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)


##BEGIN EXPERIMENT

#intro 1 - explain game - until '5'
# ------Prepare to start Routine "Intro1"-------
continueRoutine = True
# update component parameters for each repeat
keyresp1 = event.BuilderKeyResponse()
# keep track of which components have finished
Intro1Components = [Intro1, keyresp1]
for thisComponent in Intro1Components:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

# -------Start Routine "Intro1"-------
while continueRoutine:
    
    # *Intro1* updates
    if Intro1.status == NOT_STARTED:
        Intro1.setAutoDraw(True)
    
    # *keyresp1* updates
    if keyresp1.status == NOT_STARTED:
        keyresp1.status = STARTED
        # keyboard checking is just starting
        win.callOnFlip(keyresp1.clock.reset)
        event.clearEvents(eventType='keyboard')
    if keyresp1.status == STARTED:
        theseKeys = event.getKeys(keyList=['a', 's', 'd', 'f', ' '])
        
        # check for quit:
        if "escape" in theseKeys:
            endExpNow = True
        if len(theseKeys) > 0:  # at least one key was pressed
            keyresp1.keys = theseKeys[-1]  # just the last key pressed
            # a response ends the routine
            continueRoutine = False
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in Intro1Components:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished
    
    # check for quit (the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()
    
    # refresh the screen
    if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

# -------Ending Routine "Intro1"-------
for thisComponent in Intro1Components:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)
# check responses
if keyresp1.keys in ['', [], None]:  # No response was made
    keyresp1.keys=None


#intro 2 - explain how to respond - until '5'
# ------Prepare to start Routine "Intro2"-------
continueRoutine = True
# update component parameters for each repeat
keyresp2 = event.BuilderKeyResponse()
# keep track of which components have finished
Intro2Components = [Intro2, keyresp2]
for thisComponent in Intro1Components:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

# -------Start Routine "Intro2"-------
while continueRoutine:    
    # *Intro2* updates
    if Intro2.status == NOT_STARTED:
        Intro2.setAutoDraw(True)
    
    # *keyresp2* updates
    if keyresp2.status == NOT_STARTED:
        keyresp2.status = STARTED
        # keyboard checking is just starting
        win.callOnFlip(keyresp2.clock.reset)
        event.clearEvents(eventType='keyboard')
    if keyresp2.status == STARTED:
        theseKeys = event.getKeys(keyList=['a', 's', 'd', 'f', ' '])
        
        # check for quit:
        if "escape" in theseKeys:
            endExpNow = True
        if len(theseKeys) > 0:  # at least one key was pressed
            keyresp2.keys = theseKeys[-1]  # just the last key pressed
            # a response ends the routine
            continueRoutine = False
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in Intro2Components:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished
    
    # check for quit (the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()
    
    # refresh the screen
    if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

# -------Ending Routine "Intro2"-------
for thisComponent in Intro2Components:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)
# check responses
if keyresp2.keys in ['', [], None]:  # No response was made
    keyresp2.keys=None

#start block loop
for block in range(3):
    
    f.write("\n\nStarting Block %d...\n\nTrial\tDoorsAppear\tResp\tRespTime\t\tFeedback\tFeedbackTime\tJitter" %(block + 1))


    #   Take Break - for blocks 2&3
    if block != 0:
            # ------Prepare to start Routine "TakeBreak"-------
        frameN = -1
        continueRoutine = True
        # update component parameters for each repeat
        keyresp3 = event.BuilderKeyResponse()
        # keep track of which components have finished
        TakeBreakComponents = [TakeBreak, keyresp3]
        for thisComponent in TakeBreakComponents:
            if hasattr(thisComponent, 'status'):
                thisComponent.status = NOT_STARTED

        # -------Start Routine "TakeBreak"-------
        while continueRoutine:
            # *TakeBreak* updates
            if TakeBreak.status == NOT_STARTED:
                TakeBreak.setAutoDraw(True)
            
            # *keyresp3* updates
            if keyresp3.status == NOT_STARTED:
                keyresp3.status = STARTED
                # keyboard checking is just starting
                win.callOnFlip(keyresp3.clock.reset)
                event.clearEvents(eventType='keyboard')
            if keyresp3.status == STARTED:
                theseKeys = event.getKeys(keyList=['a', 's', 'd', 'f', ' '])
                
                # check for quit:
                if "escape" in theseKeys:
                    endExpNow = True
                if len(theseKeys) > 0:  # at least one key was pressed
                    keyresp3.keys = theseKeys[-1]  # just the last key pressed
                    # a response ends the routine
                    continueRoutine = False
            
            # check if all components have finished
            if not continueRoutine:  # a component has requested a forced-end of Routine
                break
            continueRoutine = False  # will revert to True if at least one component still running
            for thisComponent in TakeBreakComponents:
                if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                    continueRoutine = True
                    break  # at least one component has not yet finished
            
            # check for quit (the Esc key)
            if endExpNow or event.getKeys(keyList=["escape"]):
                core.quit()
            
            # refresh the screen
            if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
                win.flip()

        # -------Ending Routine "TakeBreak"-------
        for thisComponent in TakeBreakComponents:
            if hasattr(thisComponent, "setAutoDraw"):
                thisComponent.setAutoDraw(False)
        # check responses
        if keyresp3.keys in ['', [], None]:  # No response was made
            keyresp3.keys=None

    #   Get Ready - until '5'
    # ------Prepare to start Routine "GetReady"-------
    continueRoutine = True
    # update component parameters for each repeat
    keyresp4 = event.BuilderKeyResponse()
    # keep track of which components have finished
    GetReadyComponents = [GetReady, keyresp4]
    for thisComponent in GetReadyComponents:
        if hasattr(thisComponent, 'status'):
            thisComponent.status = NOT_STARTED

    # -------Start Routine "GetReady"-------
    while continueRoutine:
        # *GetReady* updates
        if GetReady.status == NOT_STARTED:
            GetReady.setAutoDraw(True)
        
        # *keyresp4* updates
        if keyresp4.status == NOT_STARTED:
            keyresp4.status = STARTED
            # keyboard checking is just starting
            win.callOnFlip(keyresp4.clock.reset)  # t=0 on next screen flip
            event.clearEvents(eventType='keyboard')
        if keyresp4.status == STARTED:
            theseKeys = event.getKeys(keyList=['5'])
            
            # check for quit:
            if "escape" in theseKeys:
                endExpNow = True
            if len(theseKeys) > 0:  # at least one key was pressed
                keyresp4.keys = theseKeys[-1]  # just the last key pressed
                # a response ends the routine
                continueRoutine = False
        
        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = False  # will revert to True if at least one component still running
        for thisComponent in GetReadyComponents:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished
        
        # check for quit (the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()
        
        # refresh the screen
        if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
            win.flip()

    # -------Ending Routine "GetReady"-------
    for thisComponent in GetReadyComponents:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
    # check responses
    if keyresp4.keys in ['', [], None]:  # No response was made
        keyresp4.keys=None


    # start experiment clock
    mainClock = core.Clock()
    
    #set main clock times for each screen
    initialFixT = 12
    DoorsT = []
    FixT1 = []
    RewardT = []
    FixT2 = []
    total = initialFixT
    for timeTr in range(26):
        DoorsT.append(total + 3)
        FixT1.append(total + 3.5)
        RewardT.append(total + 6)
        FixT2.append(total + 6 + blockIntervals[block][timeTr])
        total = total + 6 + blockIntervals[block][timeTr]
    endExpT = total + 30
        
    blockStartTime = time.time()
    
    
    # ------Prepare to start Routine "Fixation"-------
    continueRoutine = True
    # keep track of which components have finished
    FixationComponents = [Fixation]
    for thisComponent in FixationComponents:
        if hasattr(thisComponent, 'status'):
            thisComponent.status = NOT_STARTED
    
    # -------Start Routine "Fixation"-------
    endTime = blockStartTime + initialFixT
    while time.time() < endTime:
        # *Fixation* updates
        if Fixation.status == NOT_STARTED:
            Fixation.setAutoDraw(True)
        
        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = False  # will revert to True if at least one component still running
        for thisComponent in FixationComponents:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished
        
        # check for quit (the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()
        
        # refresh the screen
        if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
            win.flip()
    
    # -------Ending Routine "Fixation"-------
    for thisComponent in FixationComponents:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
        

    for trial in range(26):
        # doors appear
        # ------Prepare to start Routine "Doors"-------
        continueRoutine = True
        # update component parameters for each repeat
        keyresp5 = event.BuilderKeyResponse()
        # keep track of which components have finished
        DoorsComponents = [Doors, SelectLeft, SelectRight, keyresp5]
        for thisComponent in DoorsComponents:
            if hasattr(thisComponent, 'status'):
                thisComponent.status = NOT_STARTED

        # -------Start Routine "Doors"-------
        endTime = blockStartTime + DoorsT[trial]
        while time.time() < endTime:
            # *Doors* updates
            if Doors.status == NOT_STARTED and SelectLeft.status == NOT_STARTED and SelectRight.status == NOT_STARTED:
                Doors.setAutoDraw(True)
                DoorsAppearTime = "%.10f" %(time.time() - blockStartTime)
                Doors.status == STARTED
            
            # *keyresp5* updates
            if keyresp5.status == NOT_STARTED and Doors.status == STARTED:
                # keep track of start time/frame for later
                keyresp5.status = STARTED
                # keyboard checking is just starting
                win.callOnFlip(keyresp5.clock.reset)  # t=0 on next screen flip
                event.clearEvents(eventType='keyboard')
            if keyresp5.status == STARTED and (Doors.status == STARTED or SelectLeft.status == STARTED or SelectRight.status == STARTED):
                theseKeys = event.getKeys(keyList=['1', '2'])
                
                # check for quit:
                if "escape" in theseKeys:
                    endExpNow = True
                if len(theseKeys) > 0:  # at least one key was pressed
                    keyresp5.keys = theseKeys[-1]  # just the last key pressed
                    resp_rt = time.time() - blockStartTime
                    
                    if keyresp5.keys == '1':
                        SelectRight.status = STOPPED
                        SelectRight.setAutoDraw(False)
                        Doors.status = STOPPED
                        Doors.setAutoDraw(False)
                        SelectLeft.status = STARTED
                        SelectLeft.setAutoDraw(True)
                    elif keyresp5.keys == '2':
                        SelectLeft.status = STOPPED
                        SelectLeft.setAutoDraw(True)
                        Doors.status = STOPPED
                        Doors.setAutoDraw(False)
                        SelectRight.status = STARTED
                        SelectRight.setAutoDraw(True)
            
            # check if all components have finished
            if not continueRoutine:  # a component has requested a forced-end of Routine
                break
            continueRoutine = False  # will revert to True if at least one component still running
            for thisComponent in DoorsComponents:
                if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                    continueRoutine = True
                    break  # at least one component has not yet finished
            
            # check for quit (the Esc key)
            if endExpNow or event.getKeys(keyList=["escape"]):
                core.quit()
            
            # refresh the screen
            if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
                win.flip()

        # -------Ending Routine "Doors"-------
        for thisComponent in DoorsComponents:
            if hasattr(thisComponent, "setAutoDraw"):
                thisComponent.setAutoDraw(False)
        # check responses
        if keyresp5.keys in ['', [], None]:  # No response was made
            keyresp5.keys= None
            response = None

        response = keyresp5.keys


        # fixation - .5 seconds
        # ------Prepare to start Routine "Fixation"-------
        continueRoutine = True
        # keep track of which components have finished
        FixationComponents = [Fixation]
        for thisComponent in FixationComponents:
            if hasattr(thisComponent, 'status'):
                thisComponent.status = NOT_STARTED
        
        # -------Start Routine "Fixation"-------
        endTime = blockStartTime + FixT1[trial]
        while time.time() < endTime:
            # *Fixation* updates
            if Fixation.status == NOT_STARTED:
                Fixation.setAutoDraw(True)
            
            # check if all components have finished
            if not continueRoutine:  # a component has requested a forced-end of Routine
                break
            continueRoutine = False  # will revert to True if at least one component still running
            for thisComponent in FixationComponents:
                if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                    continueRoutine = True
                    break  # at least one component has not yet finished
            
            # check for quit (the Esc key)
            if endExpNow or event.getKeys(keyList=["escape"]):
                core.quit()
            
            # refresh the screen
            if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
                win.flip()
        
        # -------Ending Routine "Fixation"-------
        for thisComponent in FixationComponents:
            if hasattr(thisComponent, "setAutoDraw"):
                thisComponent.setAutoDraw(False)

        # logic for if they get it right or wrong
        if blockTrials[block][trial] == 'WIN':
            # show correct slide
            # ------Prepare to start Routine "Correct"-------
            continueRoutine = True
            # keep track of which components have finished
            CorrectComponents = [Correct]
            for thisComponent in CorrectComponents:
                if hasattr(thisComponent, 'status'):
                    thisComponent.status = NOT_STARTED
            
            # -------Start Routine "Correct"-------
            endTime = blockStartTime + RewardT[trial]
            while time.time() < endTime:
                # *Correct* updates
                if Correct.status == NOT_STARTED:
                    Correct.setAutoDraw(True)
                    FeedbackAppearTime = "%.10f" %(time.time() - blockStartTime)
                
                # check if all components have finished
                if not continueRoutine:  # a component has requested a forced-end of Routine
                    break
                continueRoutine = False  # will revert to True if at least one component still running
                for thisComponent in CorrectComponents:
                    if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                        continueRoutine = True
                        break  # at least one component has not yet finished
                
                # check for quit (the Esc key)
                if endExpNow or event.getKeys(keyList=["escape"]):
                    core.quit()
                
                # refresh the screen
                if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
                    win.flip()
            
            # -------Ending Routine "Correct"-------
            for thisComponent in CorrectComponents:
                if hasattr(thisComponent, "setAutoDraw"):
                    thisComponent.setAutoDraw(False)
            
            tr = "Win"
            
        else:
            # show wrong slide
            # ------Prepare to start Routine "Wrong"-------
            continueRoutine = True
            # keep track of which components have finished
            WrongComponents = [Wrong]
            for thisComponent in WrongComponents:
                if hasattr(thisComponent, 'status'):
                    thisComponent.status = NOT_STARTED
            
            # -------Start Routine "Wrong"-------
            endTime = blockStartTime + RewardT[trial]
            while time.time() < endTime:
                # *redArrow* updates
                if Wrong.status == NOT_STARTED:
                    Wrong.setAutoDraw(True)
                    FeedbackAppearTime = "%.10f" %(time.time() - blockStartTime)
                
                # check if all components have finished
                if not continueRoutine:  # a component has requested a forced-end of Routine
                    break
                continueRoutine = False  # will revert to True if at least one component still running
                for thisComponent in WrongComponents:
                    if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                        continueRoutine = True
                        break  # at least one component has not yet finished
                
                # check for quit (the Esc key)
                if endExpNow or event.getKeys(keyList=["escape"]):
                    core.quit()
                
                # refresh the screen
                if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
                    win.flip()
            
            # -------Ending Routine "Wrong"-------
            for thisComponent in WrongComponents:
                if hasattr(thisComponent, "setAutoDraw"):
                    thisComponent.setAutoDraw(False)
            
            tr = "Loss"
            
        if response == None: 
            keyRespTimeStr = "NA"
            response = "NA"
        else:
            keyRespTimeStr = "%.10f" %(resp_rt)
            
        f.write("\n%d\t%s\t%s\t%s\t%s\t%s\t%s" %(trial+1, DoorsAppearTime, response, keyRespTimeStr, tr, FeedbackAppearTime, blockIntervals[block][trial]))

            # ------Prepare to start Routine "Fixation"-------

        continueRoutine = True
        # keep track of which components have finished
        FixationComponents = [Fixation]
        for thisComponent in FixationComponents:
            if hasattr(thisComponent, 'status'):
                thisComponent.status = NOT_STARTED
        
        # -------Start Routine "Fixation"-------
        endTime = blockStartTime + FixT2[trial]
        while time.time() < endTime:
            # *Fixation* updates
            if Fixation.status == NOT_STARTED:
                Fixation.setAutoDraw(True)
            
            # check if all components have finished
            if not continueRoutine:  # a component has requested a forced-end of Routine
                break
            continueRoutine = False  # will revert to True if at least one component still running
            for thisComponent in FixationComponents:
                if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                    continueRoutine = True
                    break  # at least one component has not yet finished
            
            # check for quit (the Esc key)
            if endExpNow or event.getKeys(keyList=["escape"]):
                core.quit()
            
            # refresh the screen
            if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
                win.flip()
        
        # -------Ending Routine "Fixation"-------
        for thisComponent in FixationComponents:
            if hasattr(thisComponent, "setAutoDraw"):
                thisComponent.setAutoDraw(False)
        

# ------Prepare to start Routine "end"-------
f.write("\n\nEnd Experiment\t")
continueRoutine = True

def process_block(subject, blocknum, block, jitter):
    result = []
    for row in block:
        rowwithoutspace=row.replace(" ","")
        rowfinal=rowwithoutspace.replace("\t",",")
        rowfinal=rowfinal.replace("\n","")
        session=1
        result.append('{}, {}, {}, {}, {}'.format(subject,session,blocknum,jitter,rowfinal))
    return result

with open(filename+ '.txt', 'r') as f:
    data = f.readlines()
    
    #Get General File Information
    Jitter1 = data[1][35]
    Jitter2 = data[1][52]
    Jitter3 = data[1][69]
    subject = data[2]
    subject = subject.replace('Subject ID: ', '')
    subject = subject.replace('\n', '')
    
    #Define Run Sessions
    alltrails = filter(lambda x:'\t' in x, data)
    header1 = alltrails.index('Trial\tDoorsAppear\tResp\tRespTime\t\tFeedback\tFeedbackTime\tJitter\n')
    del alltrails[header1]
    header2 = alltrails.index('Trial\tDoorsAppear\tResp\tRespTime\t\tFeedback\tFeedbackTime\tJitter\n')
    del alltrails[header2]
    header3 = alltrails.index('Trial\tDoorsAppear\tResp\tRespTime\t\tFeedback\tFeedbackTime\tJitter\n')
    del alltrails[header3]
    maxtrail = alltrails.index('End Experiment\t')
    del alltrails[maxtrail]
    block1 = alltrails[header1:header2]
    blocknum1=1
    block2 = alltrails[header2:header3]
    blocknum2=2
    block3 = alltrails[header3:maxtrail]
    blocknum3=3
    
    #Aggregate Sessions into One Timeseries
    results1 = process_block(subject, blocknum1, block1, Jitter1)
    results1 = [row.split(',') for row in results1]
    for row in results1:
        row[4] = str(int(row[4]))
        row[5] = str(int(float(row[5])))
        if row[7]!='NA':
            row[7]=str(int(float(row[7])))
        row[9]=str(int(float(row[9])))
    
    results2 = process_block(subject, blocknum2, block2, Jitter2)
    results2 = [row.split(',') for row in results2]
    for row in results2:
        row[4] = str(int(row[4]) + 26)
        row[5] = str(int(float(row[5]))+225)
        if row[7]!='NA':
            row[7]=str(int(float(row[7]))+225)
        row[9]=str(int(float(row[9]))+225)
    
    results3 = process_block(subject, blocknum3, block3, Jitter3)
    results3 = [row.split(',') for row in results3]
    for row in results3:
        row[4] = str(int(row[4]) + 52)
        row[5] = str(int(float(row[5])) + 450)
        if row[7]!='NA':
            row[7]=str(int(float(row[7]))+450)
        row[9]=str(int(float(row[9]))+450)
        
    #Aggregates Blocks into Single Run
    combined=results1+results2+results3
    FinalHeader=[['sub', 'ses', 'block', 'JitterNum', 'TrailNumTotal', 'DoorsAppearTimeTotal', 'Response', 'ResponceTimeTotal', 'Contrasts', 'FeedbackAppearTimeTotal', 'JitterTimeDur']]
    FINAL=FinalHeader+combined
    
    #Save Output Files
    np.savetxt(filename+ '.csv', FINAL, delimiter=",", fmt='%s')
    np.savetxt(filename+ '.tsv', FINAL, delimiter="\t", fmt='%s')


# keep track of which components have finished
endComponents = [EndExperiment]
for thisComponent in endComponents:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

# -------Start Routine "EndExperiment"-------
#while continueRoutine and routineTimer.getTime() > 0:
endTime = blockStartTime + endExpT
while time.time() < endTime:
    # *EndExperiment* updates
    if EndExperiment.status == NOT_STARTED:
        EndExperiment.setAutoDraw(True)
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in endComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished
    
    # check for quit (the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()
    
    # refresh the screen
    if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

# -------Ending Routine "end"-------
for thisComponent in endComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw()


win.close()
core.quit()

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################