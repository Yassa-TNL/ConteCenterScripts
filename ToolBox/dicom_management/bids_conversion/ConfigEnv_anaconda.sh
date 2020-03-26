#!/bin/bash
###########

module purge ; module load anaconda/2.7-4.3.1

############################################
### Configure Personal Conda Environment ###
############################################

if [[ ! -f ~/.condarc || ! -f ~/Settings/MyCondaEnv.sh ]] ; then

	which conda
	conda info
	more ~/.condarc
	conda init bash
	sed -n '/# >>> conda initialize >>>/,/# <<< conda initialize <<</p' ~/.bashrc > ~/Settings/MyCondaEnv.sh
	grep -i -B 10 '# >>> conda initialize >>>' ~/.bashrc | sed '$d' > ~/.bashrc_revert
	mv ~/.bashrc_revert ~/.bashrc
	source ~/Settings/MyCondaEnv.sh
	conda activate local

########################################################
### Create Software Program Within Conda Environment ###
########################################################

	if [[ ! -d ~/.conda/envs/local ]] ; then 

		conda create -n local python=3.6.8 anaconda
		conda config --add channels conda-forge

	fi

###################################################################
### Install Specific Software Packages Within Conda Environment ###
###################################################################

	conda install -c imperial-college-research-computing dcm2bids
	conda install -c conda-forge/label/cf201901 nodejs
	conda install --channel conda-forge mock
	conda install --channel conda-forge nipype
	conda install --channel conda-forge nilearn
	npm install -g bids-validator
	pip install --upgrade dcm2bids
	pip install https://github.com/INCF/BIDS2NDA/archive/master.zip

fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
