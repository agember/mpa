datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

#source(paste(codepath,'analyze/read_metrics.R',sep="/"))
#source(paste(codepath,'analyze/quantile_bins.R',sep="/"))
#counts <- table(binned$NumDevices)
#counts <- counts/nrow(metrics)
#
#plotfile <- paste(datapath,'plots','numdevices_distribution.pdf',sep="/")
#pdf(plotfile, height=3, width=3)
#par(mar=c(3,3,1,0), mgp=c(2,0.5,0))
#xtics <- barplot(counts, ylab='Fraction of Networks', xlab='# of Devices', ylim=c(0,0.6), xaxt='n',
#        cex.lab=1.5, cex.axis=1.5)
#axis(1, xtics, names(counts), cex.axis=1.5, tick=FALSE)
#box(which = "plot", lty = "solid")
#dev.off()

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
x <- sort(metrics$NumDevices)
len <- length(metrics$NumDevices)-1
y <- c(0:len)/len

plotfile <- paste(datapath,'plots','numdevices_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.5,1,0), mgp=c(2,0.3,0))
plot(x, y, ylab='Fraction of Networks', xlab='# of Devices', ylim=c(0,1), yaxt='n', 
        cex.lab=1.4, type='l')
axis(2,las=2,cex.axis=1.4,tck=0.03)
dev.off()

