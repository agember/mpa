datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
#lastmonth <- metrics[which(metrics$Month=="2014-12"),]
x <- sort(tapply(metrics$NumChanges, metrics$StampName, mean))
#x <- sort(lastmonth$NumChanges)
len <- length(x)-1
y <- c(0:len)/len

plotfile <- paste(datapath,'plots','numchanges_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(2.8,3.1,1,0.3), mgp=c(1.9,0.3,0))
plot(x, y, ylab='Fraction of Networks', xlab='No. of Change Events', ylim=c(0,1), yaxt='n', 
        cex.lab=1.4, type='l', lwd=2)
#lines(xF, yF, type='l', lty="dashed", lwd=2)
axis(2,las=2,cex.axis=1.4,tck=0.03)
#legend(0.15,0.35,lwd=2, lty=c("solid","dashed"), legend=c("Hardware","Firmware"), bty="n", cex=1.4, seg.len=1.5)
dev.off()

print("Precentiles")
print(quantile(x,c(0.1,0.25,0.5,0.75,0.9)))


