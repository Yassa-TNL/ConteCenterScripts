#!/usr/bin/env Rscript
######################

print("Reading Arguments")
DIR_PROJECT="/dfs7/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One"
suppressMessages(require(mgcv))
suppressMessages(require(visreg))
suppressMessages(require(svglite))
suppressMessages(require(cowplot))
suppressMessages(require(reshape))
suppressMessages(require(ggplot2))
suppressMessages(require(corrplot))
suppressMessages(require(interactions))
suppressMessages(require(RColorBrewer))
suppressMessages(require(miceadds))
suppressMessages(require(plyr))
suppressMessages(require(nlme))
suppressMessages(require(lme4))
suppressMessages(require(car))
TODAY=gsub("-","",Sys.Date())

#################################################################################################
##### Find T-values and Z-values Extracted From the Contrasts Maps Calculated with FSL FEAT #####
#################################################################################################

FILES<-list.files(path=paste0(DIR_PROJECT,"/analyses/IntraFlux"), full.names=T, pattern="csv")
CONTRASTS<-read.csv(FILES[5])
CONTENT<-read.csv(FILES[6])
AMG<-read.csv(FILES[7])
LONG<-read.csv(FILES[8])
REST1<-read.csv(FILES[9])
REST2<-read.csv(FILES[10])
TIMESERIES<-read.csv(FILES[11])

### Histograms of Network Stregthen During Each Scan

Hist1<-qplot(REST1$COMP6_MEAN,
      geom="histogram",
      binwidth = 10,
      fill=I("#0006b8"), 
      col=I("#000000"),
      xlim=c(-175,325)) + theme_classic()
Hist2<-qplot(AMG$COMP6_MEAN,
      geom="histogram",
      binwidth = 10,
      fill=I("#80471C"), 
      col=I("#000000"),
      xlim=c(-175,325)) + theme_classic()
Hist3<-qplot(REST2$COMP6_MEAN,
      geom="histogram",
      binwidth = 10,
      fill=I("#45b1ff"), 
      col=I("#000000"),
      xlim=c(-175,325)) + theme_classic()

### F2: Cross-sectional Models

#ggplot() + 
#	geom_smooth(data=REST1,method='lm',aes(PreMood_Ent,COMP6_MEAN),se=FALSE, colour="#FF0000",fullrange=TRUE,size=2) + 
#	geom_point(data=REST1, aes(PreMood_Ent,COMP6_MEAN), colour="#FF0000", size=1.5) + 
#	geom_smooth(data=AMG,method='lm',aes(PreMood_Ent,COMP6_MEAN),se=FALSE, colour="#0000FF",fullrange=TRUE,size=2) + 
#	geom_point(data=AMG, aes(PreMood_Ent,COMP6_MEAN), colour="#0000FF", size=1.5) + 
#	geom_smooth(data=REST2,method='lm',aes(PreMood_Ent,COMP6_MEAN),se=FALSE, colour="#008000",fullrange=TRUE,size=2) + 
#	geom_point(data=REST2, aes(PreMood_Ent,COMP6_MEAN), colour="#008000", size=1.5) +
#	theme_classic()

### Mixed-Effect Model

F3<-REST1[,c("sub","PreMood_Ent","COMP6_MEAN")] ; names(F3)[3]<-c("COMP6_REST1")
F3$COMP6_AMG<-AMG$COMP6_MEAN ; F3$COMP6_REST2<-REST2$COMP6_MEAN
ggplot() + 
	geom_point(data=LONG,aes(x=PreMood_Ent,y=COMP6_MEAN,group=as.factor(sub),fill=as.factor(TASK),color=as.factor(TASK),shape=as.factor(TASK)),size=2.2) +
	scale_color_manual(values=c("#000000","#80471C","#0006b8","#45b1ff")) +
	geom_line(data=LONG,aes(x=PreMood_Ent,y=COMP6_MEAN,group=as.factor(sub),color="#654321"), size=0.5, alpha=.30) + 
 	geom_smooth(data=LONG,method='lm',aes(PreMood_Ent,COMP6_MEAN),span=10,colour="#000000",fullrange=TRUE,level=0.99,size=2) +
	theme_classic()

### Latent Growth Curve Modeling

load.Rdata(list.files(path=paste0(DIR_PROJECT,"/analyses/IntraFlux"), full.names=T, pattern="Rdata"),"INTRA")
Original<-ggplot(data=INTRA, aes(x=timepoint, y=COMP6, group=sub, color=as.factor(class.rchg.2.comp6))) +
	geom_line(alpha=1) + 
	facet_grid(. ~ class.rchg.2.comp6) +
	scale_x_continuous(breaks=1:3, labels=c("REST1","AMG","REST2"), limits=c(.85,3.15)) +
	theme(legend.position="none") +
	ggtitle("Clusters")

INTRA$CLUSTER<-as.factor(INTRA$class.rchg.2.comp6) 
INTRA<-INTRA[,c("sub","TASK","timepoint","CLUSTER")]
LONG<-merge(LONG,INTRA,by=c("sub","TASK"))
ggplot() +
	geom_point(data=LONG,aes(x=timepoint,y=COMP6_MEAN,group=as.factor(sub),fill=as.factor(TASK),color=as.factor(TASK),shape=as.factor(TASK)),size=2.2) +
	geom_line(data=LONG, aes(x=timepoint, y=COMP6_MEAN,group=sub,color=CLUSTER), size=.5, alpha=.30) + 
	scale_x_continuous(breaks=1:3, labels=c("REST1","AMG","REST2")) +
	scale_color_manual(values=c("#000000","#000000","#80471C","#0006b8","#45b1ff")) +
	facet_grid(. ~ CLUSTER)  + 
	theme_classic()

### Timeseries Within And Between All Scans

names(TIMESERIES)[which(names(TIMESERIES) == "class.rchg.2.comp6")] <- "CLUSTER"
TIMESERIES[,c("Gender","CLUSTER","COLOR")]<-lapply(TIMESERIES[,c("Gender","CLUSTER","COLOR")],factor)
ALFF_AMG<-read.csv(FILES[1]) ; ALFF_REST1<-read.csv(FILES[3]) ; ALFF_REST2<-read.csv(FILES[4])
MERGE<-ALFF_REST1[,c("sub","COMP6_ALFF")] ; names(MERGE)[2]<-"ALFF_REST1"
MERGE<-cbind(MERGE,ALFF_AMG$COMP6_ALFF) ; names(MERGE)[3]<-"ALFF_AMG"
MERGE<-cbind(MERGE,ALFF_REST2$COMP6_ALFF) ; names(MERGE)[4]<-"ALFF_REST2"
CONTENT<-merge(CONTENT,MERGE,by="sub") ; CONTENT$VARIABLE_CLUSTER<-as.factor(CONTENT$VARIABLE_CLUSTER)
CONTENT$VARIABLE_CLUSTER<-Recode(CONTENT$VARIABLE_CLUSTER, "0='B'; 1='A'")

ggplot(TIMESERIES, aes(x=Volume,y=BOLD,group=sub,color=COLOR)) + geom_line(size=0.2,alpha=0.8) + geom_abline(intercept=0,slope=0) + theme_classic() + facet_wrap(~CLUSTER) + scale_color_manual(values=c("#0006b8","#80471C","#45b1ff"))

mu <- ddply(CONTENT, "VARIABLE_CLUSTER", summarise, grp.mean=mean(ALFF_REST1))
ggplot(CONTENT, aes(x=ALFF_REST1, color=VARIABLE_CLUSTER, fill=VARIABLE_CLUSTER)) +
	geom_histogram(aes(y=..density..), position="identity", alpha=0.80,bins=20)+
	geom_density(alpha=0.25)+
	xlim(50000,2000000) +
	geom_vline(data=mu, aes(xintercept=grp.mean, color=VARIABLE_CLUSTER),linetype="longdash",size=1.9)+
	scale_color_manual(values=c("#000000","#0006b8", "#000000"))+
	scale_fill_manual(values=c("#000000","#0006b8", "#000000"))+
	theme_classic()

mu <- ddply(CONTENT, "VARIABLE_CLUSTER", summarise, grp.mean=mean(ALFF_AMG))
ggplot(CONTENT, aes(x=ALFF_AMG, color=VARIABLE_CLUSTER, fill=VARIABLE_CLUSTER)) +
	geom_histogram(aes(y=..density..), position="identity", alpha=0.80,bins=15)+
	geom_density(alpha=0.2)+
	xlim(50000,2000000) +
	geom_vline(data=mu, aes(xintercept=grp.mean, color=VARIABLE_CLUSTER),linetype="longdash",size=1.9)+
	scale_color_manual(values=c("#000000","#80471C", "#000000"))+
	scale_fill_manual(values=c("#000000","#80471C", "#000000"))+
	theme_classic()

mu <- ddply(CONTENT, "VARIABLE_CLUSTER", summarise, grp.mean=mean(ALFF_REST2))
ggplot(CONTENT, aes(x=ALFF_REST2, color=VARIABLE_CLUSTER, fill=VARIABLE_CLUSTER)) +
	geom_histogram(aes(y=..density..), position="identity", alpha=0.80,bins=15)+
	geom_density(alpha=0.2)+
	xlim(50000,2750000) +
	geom_vline(data=mu, aes(xintercept=grp.mean, color=VARIABLE_CLUSTER),linetype="longdash",size=1.9)+
	scale_color_manual(values=c("#000000","#45b1ff", "#000000"))+
	scale_fill_manual(values=c("#000000","#45b1ff", "#000000"))+
	theme_classic()

### Timeseries Figures Across All Scans

ggplot(CONTENT, aes(x=ALFF_REST1, fill=VARIABLE_CLUSTER)) + geom_density(alpha=.8) +scale_fill_manual(values=c("#000000","#FF0000")) + theme_classic()
ggplot(TIMESERIES, aes(x=Volume,y=BOLD,group=sub,color=CLUSTER)) + geom_line(size=0.2,alpha=0.8) + geom_abline(intercept=0,slope=0) + theme_classic() + scale_color_manual(values=c("#000000","#FF0000"))
ggplot(CONTENT, aes(x=TIME_SD, fill=VARIABLE_CLUSTER)) + geom_density(alpha=.8) +scale_fill_manual(values=c("#FF0000","#000000")) + theme_classic()
ggplot(CONTENT, aes(x=ALFF_MEAN, fill=VARIABLE_CLUSTER)) + geom_density(alpha=.8) +scale_fill_manual(values=c("#FF0000","#000000")) + theme_classic()

### Save Figures

png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Histogram1.png")) ; print(Hist1) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Histogram2.png")) ; print(Hist2) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Histogram3.png")) ; print(Hist3) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Figure2.png")) ; print(Figure2) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Figure3.png")) ; print(Figure3) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Figure4.png")) ; print(Figure4) ; dev.off()

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
