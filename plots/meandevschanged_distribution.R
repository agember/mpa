datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))

plotfile <- paste(datapath,'plots','meandevschanged_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3.7,3.7,1,0), mgp=c(2.6,0.3,0))

x <- sort(metrics[which(metrics$NumChanges>0),'MeanDevicesChanged'])
len <- length(x)-1
y <- c(0:len)/len
plot(x, y, ylab='Fraction of Networks', xlab='Mean Devices\nChanged/Event', ylim=c(0,1), xlim=c(1,7), yaxt='n', xaxt='n',
        cex.lab=1.4, type='l', lwd=2, lty="solid")

#x <- sort(metrics[which(metrics$NumChanges>0),'MeanRolesChanged'])
#len <- length(x)-1
#y <- c(0:len)/len
#lines(x, y, lwd=2, lty="dashed")
#
#x <- sort(metrics[which(metrics$NumChanges>0),'MeanModelsChanged'])
#len <- length(x)-1
#y <- c(0:len)/len
#lines(x, y, lwd=2, lty="dotted")
#
#legend(3,0.45,lwd=2, lty=c("solid","dashed","dotted"), 
#        legend=c("Devices","Roles","Models"), bty="n", cex=1.4, seg.len=1, x.intersp=0.1)

axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,seq(1,8,2),seq(1,8,2),cex.axis=1.4,tck=0.03)
dev.off()
