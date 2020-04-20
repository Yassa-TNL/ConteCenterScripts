#!/usr/bin/env Rscript
######################

library(predictmeans)
library(ggplot2)
library(ggpubr)
library(nlme)
library(lme4)

######################################################
##### Load Dataset and Ensure Correct Class Type #####
######################################################

data<-read.csv("/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/GattasICR/lme_PilotData_Gattas.csv")
data$condition<-as.factor(data$condition)
data$subject<-as.factor(data$subject)
data$trail<-as.numeric(data$trail)
data$electrode<-as.factor(data$electrode)
data$activation<-as.numeric(data$activation)

######################################################
##### Create Figures to Visualize Random Effects #####
######################################################

a_fig<-ggplot(data=data, aes(x = condition, y = activation, group = condition)) + 
	geom_boxplot(aes(color = condition)) +
	facet_wrap(~subject) + 
	theme_classic() + 
	guides(fill=FALSE) +
	scale_color_manual(values=c("#E74C3C","#3498DB"))

one_df<-data[which(data$condition == 1),]
b_fig<-ggplot(data=one_df, aes(x = trail, y = activation,group = electrode)) + 
	geom_point(aes(color = electrode)) + 
	stat_smooth(aes(color = electrode),method = "lm",se = FALSE) + 
	facet_wrap(~subject) +
	scale_color_manual(values=c("#E74C3C","#3498DB","#2ECC71","#F1C40F")) +
	theme_classic()

two_df<-data[which(data$condition == 2),]
c_fig<-ggplot(data=two_df, aes(x = trail, y = activation,group = electrode)) + 
	geom_point(aes(color = electrode)) + 
	stat_smooth(aes(color = electrode),method = "lm",se = FALSE) + 
	facet_wrap(~subject) +
	scale_color_manual(values=c("#E74C3C","#3498DB","#2ECC71","#F1C40F")) +
	theme_classic()

final_fig<-ggarrange(a_fig,b_fig,c_fig, nrow = 3, labels = c("A","B","C"))
ggsave(file="/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/analyses/GattasICR/visualize_mixed_effects.pdf", plot=final_fig, device="pdf")

################################################
##### Calculate Linear Longitudinal Models #####
################################################

print("Building Model with the nlme:lme Package")
ctrl <- lmeControl(opt='optim') 
m1<-lme(activation ~ condition, random = ~ 1 | subject/electrode, data=data, control=ctrl, method="REML")
summary(m1)
residplot(m1)

print("Building Model with the lme4:lmer Package")
m1<-lmer(activation ~ condition + (1 | subject/electrode),REML=TRUE , data=data)
summary(m1)
residplot(m1)

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
