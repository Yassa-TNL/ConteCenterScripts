#!/usr/bin/env Rscript
###################################################################################################
##########################                   NSF-GRFP                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

library(mgcv)
library(ggplot2)
library(cowplot)
library(RColorBrewer)

####################
### Read in Data ###
####################

data<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/COVA-n424_Age+Sex_20191008_RESP-n415_Aseg_volume_20191105/QAMeeting/n414_gam_sAgeAtScank4_Merged.csv")

########################################################################################
### Create Subject-Level Plots of Total Gray Volume Changes by Session and AgeAtScan ###
########################################################################################

vars<-c(AgeAtScan ses)
for (varname in vars){

  ### Plot Connecting Points
  ggplot(data = allscans, aes(x = varname, y = TotalGrayVol)) + 
	geom_line() +
	facet_wrap(~sub)

  ### Plot Line of Best Fit
  ggplot(data = data, aes(x = varname, y = TotalGrayVol, group = sub)) + 
	geom_point() + 
	stat_smooth(method = "lm",se = FALSE) + 
	facet_wrap(~sub)
}

#######################################################################
### Create Group-Level Plots of Total Gray Volume Changes AgeAtScan ###
#######################################################################

ggplot(data = allscans, aes(x=AgeAtScan, y=TotalGrayVol, group=sub)) + stat_smooth(method = "lm",se = FALSE) + facet_wrap(~Gender)

#######################################################################
### Create Group-Level Plots of Total Gray Volume Changes AgeAtScan ###
#######################################################################

ggplot(data = allscans, aes(x=AgeAtScan, y=TotalGrayVol, group=sub)) + stat_smooth(method = "lm",se = FALSE) + facet_wrap(~Gender)
ggplot(data = allscans, aes(x=AgeAtScan, y=TotalGrayVol, group=sub)) + stat_smooth(method = "lm",se = FALSE) + facet_wrap(~Gender)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
