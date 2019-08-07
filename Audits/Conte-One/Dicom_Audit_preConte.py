#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

import os 

with open("/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/Audit_Master_ConteMRI.csv", "r") as audit:
	csv=audit.read()
print(csv)


####

import pandas as pd
import os
import pathlib
import glob  
from shutil import copyfile



audit = pd.read_csv('/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/Audit_Master_ConteMRI.csv')
base = audit.loc[audit['Session'] == 0]
base_maxrows = base.shape[0]

for row in range(base_maxrows):
	subid = base.iloc[row][0]
	MRIses = base.iloc[row][1]
	input_files = '/dfs2/yassalab/ConteCenter/1point0/preConte/LACIE_SHARE/all-Nifti_files_asof_sept21-09/{}*'.format(subid)
	input_files = glob.glob(input_files)
	dir_output = '/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-PreOne/{}_0_{}'.format(subid,MRIses)
	pathlib.Path(dir_output).mkdir(parents=True, exist_ok=True)
		os.makedirs(dir_output)






	for file in input_files:
		copyfile(file, dir_output)



	copyfile(input_files, dir_output)


	






subid
	session



"this {}is {}some {}string!".format(1,2,3)

maxrow




row_count = sum(for row in audit)







for row in audit[0:maxrow]:
	print(row)





df.iloc[3:6] 








audit=open("/dfs2/yassalab/rjirsara/ConteCenter/Audits/Conte-One/Audit_Master_ConteMRI.csv")
text=audit.read()

print(text)













os.getcwd()
