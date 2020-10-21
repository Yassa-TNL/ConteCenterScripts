#!/usr/bin/env Rscript
######################

print("Reading Arguments")
install.packages("miceadds")

DIR_PROJECT="/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One"
suppressMessages(require(mgcv))
suppressMessages(require(visreg))
suppressMessages(require(svglite))
suppressMessages(require(cowplot))
suppressMessages(require(reshape))
suppressMessages(require(ggplot2))
suppressMessages(require(corrplot))
suppressMessages(require(interactions))
suppressMessages(require(RColorBrewer))
suppressMessages(require(nlme))
suppressMessages(require(lme4))
suppressMessages(require(miceadds))
TODAY=gsub("-","",Sys.Date())

#################################################################################################
##### Find T-values and Z-values Extracted From the Contrasts Maps Calculated with FSL FEAT #####
#################################################################################################

FILES<-list.files(path=paste0(DIR_PROJECT,"/analyses/IntraFlux"), full.names=T, pattern="csv")
EVContrasts<-read.csv(FILES[1])
REST1<-read.csv(FILES[4])
AMG<-read.csv(FILES[2])
REST2<-read.csv(FILES[5])
LONG<-read.csv(FILES[3])

### F1: Histograms of Network Stregthen D*~uring Each Scan

Hist1<-qplot(REST1$COMP6_MEAN,
      geom="histogram",
      binwidth = 3,
      fill=I("#FF0000"), 
      col=I("#000000"),
      xlim=c(-50,80)) + theme_classic()

Hist2<-qplot(AMG$COMP6_MEAN,
      geom="histogram",
      binwidth = 3,
      fill=I("#0000FF"), 
      col=I("#000000"),
      xlim=c(-50,80)) + theme_classic()

Hist3<-qplot(REST2$COMP6_MEAN,
      geom="histogram",
      binwidth = 3,
      fill=I("#008000"), 
      col=I("#000000"),
      xlim=c(-50,80)) + theme_classic()

### F2: Cross-sectional Models

Figure2 <- ggplot() + 
	geom_smooth(data=REST1,method='lm',aes(PreMood_Ent,COMP6_MEAN),se=FALSE, colour="#FF0000",fullrange=TRUE,size=2) + 
	geom_point(data=REST1, aes(PreMood_Ent,COMP6_MEAN), colour="#FF0000", size=1.5) + 
	geom_smooth(data=AMG,method='lm',aes(PreMood_Ent,COMP6_MEAN),se=FALSE, colour="#0000FF",fullrange=TRUE,size=2) + 
	geom_point(data=AMG, aes(PreMood_Ent,COMP6_MEAN), colour="#0000FF", size=1.5) + 
	geom_smooth(data=REST2,method='lm',aes(PreMood_Ent,COMP6_MEAN),se=FALSE, colour="#008000",fullrange=TRUE,size=2) + 
	geom_point(data=REST2, aes(PreMood_Ent,COMP6_MEAN), colour="#008000", size=1.5) +
	theme_classic()

### F3: Mixed-Effect Model

F3<-REST1[,c("sub","PreMood_Ent","COMP6_MEAN")]
names(F3)[3]<-c("COMP6_REST1")
F3$COMP6_AMG<-AMG$COMP6_MEAN
F3$COMP6_REST2<-REST2$COMP6_MEAN

Figure3 <- ggplot() + 
	geom_line(data=LONG,aes(x=PreMood_Ent,y=COMP6_MEAN,group=as.factor(sub),color="#654321"), size=.5, alpha=.30) + 
	geom_point(data=LONG,aes(x=PreMood_Ent,y=COMP6_MEAN,group=as.factor(sub),color=as.factor(TASK)),size=1.5) + 
	geom_smooth(data=LONG,method='lm',aes(PreMood_Ent,COMP6_MEAN),span = 10,colour="#000000",fullrange=TRUE,level=0.99,size=2) +
	scale_color_manual(values=c("#000000","#0000FF","#FF0000","#008000")) +
	theme_classic()

### F4: Latent Growth Curve Modeling

load.Rdata(list.files(path=paste0(DIR_PROJECT,"/analyses/IntraFlux"), full.names=T, pattern="Rdata"),"INTRA")
Original<-ggplot(data=INTRA, aes(x=timepoint, y=COMP6, group=sub, color=as.factor(class.rchg.2.comp6))) +
  geom_line(alpha=1) + 
  facet_grid(. ~ class.rchg.2.comp6) +
  scale_x_continuous(breaks=1:3, labels=c("REST1","AMG","REST2"), limits=c(.85,3.15)) +
  theme(legend.position="none") +
  ggtitle("Clusters")

INTRA$CLUSTER<-as.factor(INTRA$class.rchg.2.comp6)
Figure4<-ggplot() +
	geom_point(data=INTRA, aes(x=timepoint, y=COMP6,group=sub,color=TASK),size=1.5) + 
	geom_line(data=INTRA, aes(x=timepoint, y=COMP6,group=sub,color=CLUSTER), size=.5, alpha=.30) + 
	scale_x_continuous(breaks=1:3, labels=c("REST1","AMG","REST2")) +
	scale_color_manual(values=c("#000000","#000000","#0000FF","#FF0000","#008000")) +
	facet_grid(. ~ CLUSTER) + 
	theme_classic()

### F4: Latent Growth Curve Modeling

png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Histogram1.png")) ; print(Hist1) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Histogram2.png")) ; print(Hist2) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Histogram3.png")) ; print(Hist3) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Figure2.png")) ; print(Figure2) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Figure3.png")) ; print(Figure3) ; dev.off()
png(paste0(DIR_PROJECT,"/analyses/IntraFlux/Figures/Figure4.png")) ; print(Figure4) ; dev.off()

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
