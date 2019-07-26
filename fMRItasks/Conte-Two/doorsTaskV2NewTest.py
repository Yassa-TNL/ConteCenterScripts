#!/usr/bin/env python2
# -*- coding: utf-8 -*-

#######################################
#######################################
#script         : doorsTask.py
#author         : Stephanie Doering
#email          : doerings@uci.edu
#date           : 7/19/2019
#status         : In development
#usage          : python doorsTaskV2NewTest.py
#######################################
#######################################

from __future__ import absolute_import, division
from psychopy.constants import (NOT_STARTED, STARTED, PLAYING, PAUSED,
                                STOPPED, FINISHED, PRESSED, RELEASED, FOREVER)
import numpy as np
from numpy import (sin, cos, tan, log, log10, pi, average,
                   sqrt, std, deg2rad, rad2deg, linspace, asarray)
from numpy.random import random, randint, normal, shuffle
import os, sys, time
from psychopy import locale_setup, sound, gui, visual, core, data, event, logging


##EXPERIMENT SET-UP


# Ensure that relative paths start from the same directory as this script
_thisDir = os.path.dirname(os.path.abspath(__file__)).decode(sys.getfilesystemencoding())
os.chdir(_thisDir)

# Store info about the experiment session
expName = 'doorsTask'  # from the Builder filename that created this script
expInfo = {'participant':''}
dlg = gui.DlgFromDict(dictionary=expInfo, title=expName)
if dlg.OK == False:
    core.quit()  # user pressed cancel

# Prepare Log Files
currentDir = os.getcwd()
defaultLogDir = os.path.join(currentDir, "logs")
logDir = os.path.join(currentDir, "data")
#filename = _thisDir + os.sep + u'data/%s_%s_log' % (expInfo['participant'], expName)
filename = os.path.join(logDir, u"%s_%s_log" % (expInfo['participant'], expName))
logTime = time.strftime("%H:%M on %m/%d/%y", time.localtime())
f = open(filename+ '.txt', 'w')
f.write("Doors Task: %s\nSubject ID: %s\nBeginning Task..." %(logTime, expInfo['participant']))
logging.console.setLevel(logging.WARNING)  # this outputs to the screen, not a file

endExpNow = False  # flag for 'escape' or other condition => quit the exp

# Set Up Experiment Window - cool red speckle thing with [255,255,255]
win = visual.Window(
    size=(1536, 864), fullscr=True, screen=0,
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
Intro1Clock = core.Clock()
Intro1 = visual.ImageStim(
    win=win, name='Intro1',
    image=os.path.join(imagesDir, 'Intro1.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Intro2
Intro2Clock = core.Clock()
Intro2 = visual.ImageStim(
    win=win, name='Intro2',
    image=os.path.join(imagesDir, 'Intro2.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize TakeBreak
TakeBreakClock = core.Clock()
TakeBreak = visual.ImageStim(
    win=win, name='TakeBreak',
    image=os.path.join(imagesDir, 'TakeBreak.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize GetReady
GetReadyClock = core.Clock()
GetReady = visual.ImageStim(
    win=win, name='GetReady',
    image=os.path.join(imagesDir, 'GetReady.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Fixation
FixationClock = core.Clock()
Fixation = visual.ImageStim(
    win=win, name='Fixation',
    image=os.path.join(imagesDir, 'Fixation.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Doors
DoorsClock = core.Clock()
Doors = visual.ImageStim(
    win=win, name='Doors',
    image=os.path.join(imagesDir, 'Doors.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize SelectLeft
SelectLeftClock = core.Clock()
SelectLeft = visual.ImageStim(
    win=win, name='SelectLeft',
    image=os.path.join(imagesDir, 'SelectLeft.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize SelectRight
SelectRightClock = core.Clock()
SelectRight = visual.ImageStim(
    win=win, name='SelectRight',
    image=os.path.join(imagesDir, 'SelectRight.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Correct
CorrectClock = core.Clock()
Correct = visual.ImageStim(
    win=win, name='Correct',
    image=os.path.join(imagesDir, 'Correct.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Initialize Wrong
WrongClock = core.Clock()
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
EndExperimentClock = core.Clock()
EndExperiment = visual.ImageStim(
    win=win, name='EndExperiment',
    image=os.path.join(imagesDir, 'EndExperiment.jpg'), mask=None,
    ori=0, pos=(0, 0), size=(2, 2),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=0.0)

# Create some handy timers
globalClock = core.Clock()  # to track the time since experiment started
routineTimer = core.CountdownTimer()  # to track time remaining of each (non-slip) routine 


##BEGIN EXPERIMENT

#intro 1 - explain game - until '5'
# ------Prepare to start Routine "Intro1"-------
t = 0
Intro1Clock.reset()  # clock
frameN = -1
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
    # get current time
    t = Intro1Clock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    
    # *Intro1* updates
    if t >= 0.0 and Intro1.status == NOT_STARTED:
        # keep track of start time/frame for later
        Intro1.tStart = t
        Intro1.frameNStart = frameN  # exact frame index
        Intro1.setAutoDraw(True)
    frameRemains = 0.0 + 120- win.monitorFramePeriod * 0.75  # most of one frame period left
    if Intro1.status == STARTED and t >= frameRemains:
        Intro1.setAutoDraw(False)
    
    # *keyresp1* updates
    if t >= 0.0 and keyresp1.status == NOT_STARTED:
        # keep track of start time/frame for later
        keyresp1.tStart = t
        keyresp1.frameNStart = frameN  # exact frame index
        keyresp1.status = STARTED
        # keyboard checking is just starting
        win.callOnFlip(keyresp1.clock.reset)  # t=0 on next screen flip
        event.clearEvents(eventType='keyboard')
    if keyresp1.status == STARTED:
        theseKeys = event.getKeys(keyList=['1', '2', '3', '4', '5', ' '])
        
        # check for quit:
        if "escape" in theseKeys:
            endExpNow = True
        if len(theseKeys) > 0:  # at least one key was pressed
            keyresp1.keys = theseKeys[-1]  # just the last key pressed
            keyresp1.rt = keyresp1.clock.getTime()
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
#thisExp.addData('keyresp1.keys',keyresp1.keys)
if keyresp1.keys != None:  # we had a response
    pass
    #thisExp.addData('keyresp1.rt', keyresp1.rt)
#thisExp.nextEntry()
# the Routine "Intro1" was not non-slip safe, so reset the non-slip timer
routineTimer.reset()


#intro 2 - explain how to respond - until '5'
# ------Prepare to start Routine "Intro2"-------
t = 0
Intro2Clock.reset()  # clock
frameN = -1
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
    # get current time
    t = Intro2Clock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame
    
    # *Intro2* updates
    if t >= 0.0 and Intro2.status == NOT_STARTED:
        # keep track of start time/frame for later
        Intro2.tStart = t
        Intro2.frameNStart = frameN  # exact frame index
        Intro2.setAutoDraw(True)
    frameRemains = 0.0 + 120- win.monitorFramePeriod * 0.75  # most of one frame period left
    if Intro2.status == STARTED and t >= frameRemains:
        Intro2.setAutoDraw(False)
    
    # *keyresp2* updates
    if t >= 0.0 and keyresp2.status == NOT_STARTED:
        # keep track of start time/frame for later
        keyresp2.tStart = t
        keyresp2.frameNStart = frameN  # exact frame index
        keyresp2.status = STARTED
        # keyboard checking is just starting
        win.callOnFlip(keyresp2.clock.reset)  # t=0 on next screen flip
        event.clearEvents(eventType='keyboard')
    if keyresp2.status == STARTED:
        theseKeys = event.getKeys(keyList=['1', '2', '3', '4', '5', ' '])
        
        # check for quit:
        if "escape" in theseKeys:
            endExpNow = True
        if len(theseKeys) > 0:  # at least one key was pressed
            keyresp2.keys = theseKeys[-1]  # just the last key pressed
            keyresp2.rt = keyresp2.clock.getTime()
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
#thisExp.addData('keyresp2.keys',keyresp2.keys)
if keyresp2.keys != None:  # we had a response
    pass
    #thisExp.addData('keyresp2.rt', keyresp2.rt)
#thisExp.nextEntry()
# the Routine "Intro2" was not non-slip safe, so reset the non-slip timer
routineTimer.reset()


for block in range(3):
    
    f.write("\n\nStarting Block %d...\n\nTrial\tResp\tRespTime\t\tFeedback\tFeedbackTime" %(block + 1))
    
    # Set Up Logic
    trialTypeOrder = ['2' for c in range(14)] + ['3' for w in range(14)]
    shuffle(trialTypeOrder)


    #   Take Break - for blocks 2&3
    if block != 0:
            # ------Prepare to start Routine "TakeBreak"-------
        t = 0
        TakeBreakClock.reset()  # clock
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
            # get current time
            t = TakeBreakClock.getTime()
            frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
            
            # *TakeBreak* updates
            if t >= 0.0 and TakeBreak.status == NOT_STARTED:
                # keep track of start time/frame for later
                TakeBreak.tStart = t
                TakeBreak.frameNStart = frameN  # exact frame index
                TakeBreak.setAutoDraw(True)
            frameRemains = 0.0 + 120- win.monitorFramePeriod * 0.75  # most of one frame period left
            if TakeBreak.status == STARTED and t >= frameRemains:
                TakeBreak.setAutoDraw(False)
            
            # *keyresp3* updates
            if t >= 0.0 and keyresp3.status == NOT_STARTED:
                # keep track of start time/frame for later
                keyresp3.tStart = t
                keyresp3.frameNStart = frameN  # exact frame index
                keyresp3.status = STARTED
                # keyboard checking is just starting
                win.callOnFlip(keyresp3.clock.reset)  # t=0 on next screen flip
                event.clearEvents(eventType='keyboard')
            if keyresp3.status == STARTED:
                theseKeys = event.getKeys(keyList=['1', '2', '3', '4', '5', ' '])
                
                # check for quit:
                if "escape" in theseKeys:
                    endExpNow = True
                if len(theseKeys) > 0:  # at least one key was pressed
                    keyresp3.keys = theseKeys[-1]  # just the last key pressed
                    keyresp3.rt = keyresp3.clock.getTime()
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
        #thisExp.addData('keyresp3.keys',keyresp3.keys)
        if keyresp3.keys != None:  # we had a response
            pass
            #thisExp.addData('keyresp3.rt', keyresp3.rt)
        #thisExp.nextEntry()
        # the Routine "TakeBreak" was not non-slip safe, so reset the non-slip timer
        routineTimer.reset()


    #   Get Ready - until '5'
    # ------Prepare to start Routine "GetReady"-------
    t = 0
    GetReadyClock.reset()  # clock
    frameN = -1
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
        # get current time
        t = GetReadyClock.getTime()
        frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
        
        # *GetReady* updates
        if t >= 0.0 and GetReady.status == NOT_STARTED:
            # keep track of start time/frame for later
            GetReady.tStart = t
            GetReady.frameNStart = frameN  # exact frame index
            GetReady.setAutoDraw(True)
        frameRemains = 0.0 + 120- win.monitorFramePeriod * 0.75  # most of one frame period left
        if GetReady.status == STARTED and t >= frameRemains:
            GetReady.setAutoDraw(False)
        
        # *keyresp4* updates
        if t >= 0.0 and keyresp4.status == NOT_STARTED:
            # keep track of start time/frame for later
            keyresp4.tStart = t
            keyresp4.frameNStart = frameN  # exact frame index
            keyresp4.status = STARTED
            # keyboard checking is just starting
            win.callOnFlip(keyresp4.clock.reset)  # t=0 on next screen flip
            event.clearEvents(eventType='keyboard')
        if keyresp4.status == STARTED:
            theseKeys = event.getKeys(keyList=['1', '2', '3', '4', '5', ' '])
            
            # check for quit:
            if "escape" in theseKeys:
                endExpNow = True
            if len(theseKeys) > 0:  # at least one key was pressed
                keyresp4.keys = theseKeys[-1]  # just the last key pressed
                keyresp4.rt = keyresp4.clock.getTime()
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
    #thisExp.addData('keyresp4.keys',keyresp4.keys)
    if keyresp4.keys != None:  # we had a response
        pass
        #thisExp.addData('keyresp4.rt', keyresp4.rt)
    #thisExp.nextEntry()
    # the Routine "GetReady" was not non-slip safe, so reset the non-slip timer
    routineTimer.reset()


    # start experiment clock
    mainClock = core.Clock()


    for trial in range(28):
        # ------Prepare to start Routine "Fixation"-------
        t = 0
        FixationClock.reset()  # clock
        frameN = -1
        continueRoutine = True
        routineTimer.add(1.500000)
        # keep track of which components have finished
        FixationComponents = [Fixation]
        for thisComponent in FixationComponents:
            if hasattr(thisComponent, 'status'):
                thisComponent.status = NOT_STARTED
        
        # -------Start Routine "Fixation"-------
        while continueRoutine and routineTimer.getTime() > 0:
            # get current time
            t = FixationClock.getTime()
            frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
            
            # *Fixation* updates
            if t >= 0.0 and Fixation.status == NOT_STARTED:
                # keep track of start time/frame for later
                Fixation.tStart = t
                Fixation.frameNStart = frameN  # exact frame index
                Fixation.setAutoDraw(True)
            frameRemains = 0.0 + 1.5- win.monitorFramePeriod * 0.75  # most of one frame period left
            if Fixation.status == STARTED and t >= frameRemains:
                Fixation.setAutoDraw(False)
            
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
                
                
        # doors appear
        # ------Prepare to start Routine "Doors"-------
        t = 0
        DoorsClock.reset()  # clock
        frameN = -1
        continueRoutine = True
        routineTimer.add(3.000000)
        # update component parameters for each repeat
        keyresp5 = event.BuilderKeyResponse()
        # keep track of which components have finished
        DoorsComponents = [Doors, SelectLeft, SelectRight, keyresp5]
        for thisComponent in DoorsComponents:
            if hasattr(thisComponent, 'status'):
                thisComponent.status = NOT_STARTED

        # -------Start Routine "Doors"-------
        while continueRoutine and routineTimer.getTime() > 0:
            # get current time
            t = DoorsClock.getTime()
            frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
            
            # *Doors* updates
            if t >= 0.0 and Doors.status == NOT_STARTED and SelectLeft.status == NOT_STARTED and SelectRight.status == NOT_STARTED:
                # keep track of start time/frame for later
                Doors.tStart = t
                Doors.frameNStart = frameN  # exact frame index
                Doors.setAutoDraw(True)
                Doors.status == STARTED
            frameRemains = 0.0 + 120- win.monitorFramePeriod * 0.75  # most of one frame period left
            if Doors.status == STARTED and t >= frameRemains:
                Doors.setAutoDraw(False)
            elif SelectLeft.status == STARTED and t >= frameRemains:
                SelectLeft.setAutoDraw(False)
            elif SelectRight.status == STARTED and t >= frameRemains:
                SelectRight.setAutoDraw(False)
            
            # *keyresp5* updates
            if t >= 0.0 and keyresp5.status == NOT_STARTED and Doors.status == STARTED:
                # keep track of start time/frame for later
                keyresp5.tStart = t
                keyresp5.frameNStart = frameN  # exact frame index
                keyresp5.status = STARTED
                # keyboard checking is just starting
                win.callOnFlip(keyresp5.clock.reset)  # t=0 on next screen flip
                event.clearEvents(eventType='keyboard')
            frameRemains = 0.0 + 3- win.monitorFramePeriod * 0.75  # most of one frame period left
            if keyresp5.status == STARTED and (Doors.status == STARTED or SelectLeft.status == STARTED or SelectRight.status == STARTED):
                theseKeys = event.getKeys(keyList=['2', '3'])
                
                # check for quit:
                if "escape" in theseKeys:
                    endExpNow = True
                if len(theseKeys) > 0:  # at least one key was pressed
                    keyresp5.keys = theseKeys[-1]  # just the last key pressed
                    keyresp5.rt = keyresp5.clock.getTime()
                    doorsRespTime = DoorsClock.getTime()
                    resp_rt = mainClock.getTime()
                    # a response ends the routine
                    #continueRoutine = False
                    
                    if keyresp5.keys == '2':
                        SelectRight.status = STOPPED
                        SelectRight.setAutoDraw(False)
                        Doors.status = STOPPED
                        Doors.setAutoDraw(False)
                        SelectLeft.status = STARTED
                        SelectLeft.setAutoDraw(True)
                    elif keyresp5.keys == '3':
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
            keyresp5.keys=None
            response = None
        #thisExp.addData('keyresp5.keys',keyresp5.keys)
        if keyresp5.keys != None:  # we had a response
            response = keyresp5.keys
            #thisExp.addData('keyresp5.rt', keyresp5.rt)
        #thisExp.nextEntry()
        # the Routine "Doors" was not non-slip safe, so reset the non-slip timer
        response = keyresp5.keys
        routineTimer.reset()


        # fixation - 1.5 seconds
        # ------Prepare to start Routine "Fixation"-------
        t = 0
        FixationClock.reset()  # clock
        frameN = -1
        continueRoutine = True
        routineTimer.add(1.500000)
        # keep track of which components have finished
        FixationComponents = [Fixation]
        for thisComponent in FixationComponents:
            if hasattr(thisComponent, 'status'):
                thisComponent.status = NOT_STARTED
        
        # -------Start Routine "Fixation"-------
        while continueRoutine and routineTimer.getTime() > 0:
            # get current time
            t = FixationClock.getTime()
            frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
            
            # *Fixation* updates
            if t >= 0.0 and Fixation.status == NOT_STARTED:
                # keep track of start time/frame for later
                Fixation.tStart = t
                Fixation.frameNStart = frameN  # exact frame index
                Fixation.setAutoDraw(True)
            frameRemains = 0.0 + 1.5- win.monitorFramePeriod * 0.75  # most of one frame period left
            if Fixation.status == STARTED and t >= frameRemains:
                Fixation.setAutoDraw(False)
            
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
        if response == None:
            # show incorrect slide -- should be changed if they decide to do 
            # something different for non responses
            # ------Prepare to start Routine "Wrong"-------
            t = 0
            WrongClock.reset()  # clock
            frameN = -1
            continueRoutine = True
            routineTimer.add(2.000000)
            # keep track of which components have finished
            WrongComponents = [Wrong]
            for thisComponent in WrongComponents:
                if hasattr(thisComponent, 'status'):
                    thisComponent.status = NOT_STARTED
            
            # -------Start Routine "Wrong"-------
            recordTime = mainClock.getTime()
            while continueRoutine and routineTimer.getTime() > 0:
                # get current time
                t = WrongClock.getTime()
                frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
                
                # *redArrow* updates
                if t >= 0.0 and Wrong.status == NOT_STARTED:
                    # keep track of start time/frame for later
                    Wrong.tStart = t
                    Wrong.frameNStart = frameN  # exact frame index
                    Wrong.setAutoDraw(True)
                frameRemains = 0.0 + 2- win.monitorFramePeriod * 0.75  # most of one frame period left
                if Wrong.status == STARTED and t >= frameRemains:
                    Wrong.setAutoDraw(False)
                
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
            #thisExp.nextEntry()
            
            tr = "Wrong  "
            
            
        elif response == trialTypeOrder[trial]:
            # show correct slide
            # ------Prepare to start Routine "Correct"-------
            t = 0
            CorrectClock.reset()  # clock
            frameN = -1
            continueRoutine = True
            routineTimer.add(2.000000)
            # keep track of which components have finished
            CorrectComponents = [Correct]
            for thisComponent in CorrectComponents:
                if hasattr(thisComponent, 'status'):
                    thisComponent.status = NOT_STARTED
            
            # -------Start Routine "Correct"-------
            recordTime = mainClock.getTime()
            while continueRoutine and routineTimer.getTime() > 0:
                # get current time
                t = CorrectClock.getTime()
                frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
                
                # *Correct* updates
                if t >= 0.0 and Correct.status == NOT_STARTED:
                    # keep track of start time/frame for later
                    Correct.tStart = t
                    Correct.frameNStart = frameN  # exact frame index
                    Correct.setAutoDraw(True)
                frameRemains = 0.0 + 2- win.monitorFramePeriod * 0.75  # most of one frame period left
                if Correct.status == STARTED and t >= frameRemains:
                    Correct.setAutoDraw(False)
                
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
            #thisExp.nextEntry()
            
            tr = "Correct"
            
        else:
            # show wrong slide
            # ------Prepare to start Routine "Wrong"-------
            t = 0
            WrongClock.reset()  # clock
            frameN = -1
            continueRoutine = True
            routineTimer.add(2.000000)
            # keep track of which components have finished
            WrongComponents = [Wrong]
            for thisComponent in WrongComponents:
                if hasattr(thisComponent, 'status'):
                    thisComponent.status = NOT_STARTED
            
            # -------Start Routine "Wrong"-------
            recordTime = mainClock.getTime()
            while continueRoutine and routineTimer.getTime() > 0:
                # get current time
                t = WrongClock.getTime()
                frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
                
                # *redArrow* updates
                if t >= 0.0 and Wrong.status == NOT_STARTED:
                    # keep track of start time/frame for later
                    Wrong.tStart = t
                    Wrong.frameNStart = frameN  # exact frame index
                    Wrong.setAutoDraw(True)
                frameRemains = 0.0 + 2- win.monitorFramePeriod * 0.75  # most of one frame period left
                if Wrong.status == STARTED and t >= frameRemains:
                    Wrong.setAutoDraw(False)
                
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
            #thisExp.nextEntry()
            
            tr = "Wrong  "
            
        if response == None: 
            keyRespTimeStr = "\t"
            response = "\t"
        else:
            keyRespTimeStr = resp_rt
            
        f.write("\n%d\t%s\t%s\t%s\t%s" %(trial+1, response, keyRespTimeStr, tr, recordTime))

# ------Prepare to start Routine "end"-------
f.write("\n\nEnd Experiment")

t = 0
endClock.reset()
frameN = -1
continueRoutine = True
routineTimer.add(30.000000)
# keep track of which components have finished
endComponents = [End]
for thisComponent in endComponents:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

# -------Start Routine "EndExperiment"-------
while continueRoutine and routineTimer.getTime() > 0:
    t = EndExperimentClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    
    # *EndExperiment* updates
    if t >= 0.0 and EndExperiment.status == NOT_STARTED:
        EndExperiment.setAutoDraw(True)
    frameRemains = 0.0 + 30- win.monitorFramePeriod * 0.75  # most of one frame period left
    if EndExperiment.status == STARTED and t >= frameRemains:
        EndExperiment.setAutoDraw(False)
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in EndExperimentComponents:
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
for thisComponent in EndExperimentComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)


win.close()
core.quit()