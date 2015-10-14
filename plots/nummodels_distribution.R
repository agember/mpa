datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
x <- sort(metrics$NumModels)
len <- length(metrics$NumModels)-1
y <- c(0:len)/len

plotfile <- paste(datapath,'plots','nummodels_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.5,1,0), mgp=c(2,0.3,0))
plot(x, y, ylab='Fraction of Networks', xlab='# of Models', ylim=c(0,1), yaxt='n', xaxt='n',
        cex.lab=1.4, type='l')
axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,cex.axis=1.4,tck=0.03)
dev.off()

