datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
lastmonth <- metrics[which(metrics$Month=="2014-12"),]
counts <- table(lastmonth$NumRoles)
hasrole <- names(lastmonth)[grep("HasRole", names(lastmonth))]
hasrole <- c('HasRoleSwitch', 'HasRoleRouter', 'HasRoleL3Switch', 'HasRoleFirewall', 'HasRoleApplicationSwitch', 'HasRoleLoadBalancer')
counts <- colSums(lastmonth[,hasrole])
counts <- counts/nrow(lastmonth)
lbls <- sub("HasRole", "", hasrole)
lbls <- sub("LoadBalancer", "LoadBal", lbls)
lbls <- sub("ApplicationSwitch", "ADC", lbls)

plotfile <- paste(datapath,'plots','hasrole_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(4,3.5,1,0), mgp=c(2,0.3,0))
xtics <- barplot(counts, ylab='Fraction of Networks', xlab='', ylim=c(0,1), xaxt='n', yaxt='n',
        cex.lab=1.4)
axis(2,las=2,cex.axis=1.4,tck=0.03)
text(xtics+0.5, -0.03, labels=lbls, cex=1.4, srt=45, xpd=TRUE, pos=2)
#mtext("Role", side=1, line=4, cex=1.25)
box(which = "plot", lty = "solid")
dev.off()

