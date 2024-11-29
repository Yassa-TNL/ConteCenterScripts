#!/usr/bin/python
# -*- coding: latin-1 -*-
#########################

import re, os, os.path, sys, glob, json, fnmatch, shutil
import pandas as pd, numpy as np

ROOT="/dfs9/yassalab/CONTE2"

######
### Save Events for FEAT1
######

for file in glob.glob(f'{ROOT}/bids/**/func/*.tsv'):
	print(file)
	df = pd.read_csv(file, sep='\t'); df = df.iloc[1:][['rewons_sl', 'won']]
	SUBID=os.path.basename(file).split('_')[0]; RUN=os.path.basename(file).split('_')[2]
	wEVENT=f'{ROOT}/pipelines/xcpfeat/pipe-feat1_task-bandit_{RUN}/logs/{SUBID}_task-bandit_evs-1_lab-won.txt'
	lEVENT=f'{ROOT}/pipelines/xcpfeat/pipe-feat1_task-bandit_{RUN}/logs/{SUBID}_task-bandit_evs-2_lab-loss.txt'
	LOSS = round(df[df['won'] == 0].iloc[:, [0]] / 1000, 3); LOSS[['duration', 'condition']] = [1, 2]
	LOSS.to_csv(lEVENT, sep='\t', index=False, header=False)
	WON = round(df[df['won'] == 1].iloc[:, [0]] / 1000, 3); WON[['duration', 'condition']] = 1
	WON.to_csv(wEVENT, sep='\t', index=False, header=False)

######
### Save Events for FEAT3 - Prediction Error Betas
######

ERRORS=glob.glob(f'{ROOT}/downloads/taskevents_errors/*.csv')
BASENAMES=[os.path.basename(path).split('.')[0] for path in ERRORS]
ERROR_SUBIDS=[path.split('_')[2] for path in BASENAMES]
for EVENT in glob.glob(f'{ROOT}/bids/sub-*/func/*.tsv'):
	SUBID=os.path.basename(EVENT).split('x')[0].split('-')[1]
	FULLID=os.path.basename(EVENT).split('_')[0].split('-')[1]
	if not SUBID in ERROR_SUBIDS:
		continue
	RECORD=pd.read_csv(EVENT,sep='\t')
	for INDEX in [i for i, s in enumerate(ERROR_SUBIDS) if s == SUBID]:
		FILE=ERRORS[INDEX]; 
		FILE1=os.path.basename(FILE).split('_')[3]
		FILE2=''.join(os.path.basename(FILE).split('_')[4:6])
		FILE2=FILE2.replace(".csv","").replace("rpe","")
		print(EVENT)
		print(f'{FILE1}{FILE2}')
		CONTENT=pd.read_csv(FILE, names=[f"{FILE1}{FILE2}"])
		CONTENT=CONTENT.iloc[RECORD['trial']]
		RECORD[f"{FILE1}{FILE2}"]=CONTENT.values
		#RECORD.to_csv(EVENT, sep='\t', index=False, header=True)
		RUN=os.path.basename(EVENT).split('_')[2]
		XCPDIR=f"{ROOT}/pipelines/xcpfeat/pipe-feat3_{FILE1}{FILE2}_{RUN}/logs"
		PREPARE=pd.DataFrame(round(RECORD['rewons_sl']/ 1000, 3))
		PREPARE['duration']=round(PREPARE['rewons_sl'].diff(), 3)
		PREPARE.at[0,'duration']=round(PREPARE.at[0,'rewons_sl'], 3)
		PREPARE['errors']=RECORD[f'{FILE1}{FILE2}']; os.makedirs(XCPDIR,exist_ok=True)
		PREPARE.to_csv(f"{XCPDIR}/sub-{FULLID}.txt", sep='\t', index=False, header=False)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################