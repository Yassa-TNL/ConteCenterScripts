#!/usr/bin/env Rscript
###################################################################################################
##########################                   NSF-GRFP                    ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ####
###################################################################################################

library(mgcv)
library(ggplot2)
library(cowplot)
library(RColorBrewer)

####################
### Read in Data ###
####################

data<-read.csv("/dfs2/yassalab/rjirsara/NSF/Data/COVA-n275_Age+Sex_20190829_RESP-n360_Aseg_volume_20190829/AllScans/n268_gamm4_sAgeAtScank4-Gender_random_1sub_Merged.csv")

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
  ggplot(data = allscans, aes(x = varname, y = TotalGrayVol, group = sub)) + 
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
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ####
###################################################################################################



