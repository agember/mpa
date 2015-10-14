datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
lastmonth <- metrics[which(metrics$Month=="2014-12"),]
x <- sort(lastmonth$NormalizedEntropy)
len <- length(x)-1
y <- c(0:len)/len

xF <- sort(lastmonth$NormalizedFirmwareEntropy)
len <- length(xF)-1
yF <- c(0:len)/len

plotfile <- paste(datapath,'plots','normentropy_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.5,1,0), mgp=c(2,0.3,0))
plot(x, y, ylab='Fraction of Networks', xlab='Normalized Entropy', ylim=c(0,1), xlim=c(0,1), yaxt='n', xaxt='n',
        cex.lab=1.4, type='l', lwd=2)
lines(xF, yF, type='l', lty="dashed", lwd=2)
axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,seq(0,1,0.3),seq(0,1,0.3),cex.axis=1.4,tck=0.03)
legend(0.15,0.35,lwd=2, lty=c("solid","dashed"), legend=c("Hardware","Firmware"), bty="n", cex=1.4, seg.len=1.5)
dev.off()

print("% of networks with no hardware entropy")
print(ecdf(x)(0))
print("% of networks with one role and one model")
print(length(which(lastmonth$NumRoles==1 & lastmonth$NumModels==1))/length(lastmonth$StampName))
print("Highest hardware entropy")
print(max(x))
print("% of networks with hardware entropy > 0.6")
print(1-ecdf(x)(0.6))


