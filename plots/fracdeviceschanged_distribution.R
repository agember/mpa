datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
x <- tapply(metrics$FractionDevicesChanged, metrics$StampName, mean)
x <- sort(x)
print(length(unique(x)))
len <- length(x)-1
y <- c(0:len)/len

datafile <- "all_metrics_12m_nomissing_filtered.csv"
source(paste(codepath,'analyze/read_metrics.R',sep="/"))
xY <- sort(metrics$FractionDevicesChanged)
print(length(unique(xY)))
len <- length(xY)-1
yY <- c(0:len)/len

plotfile <- paste(datapath,'plots','fracdeviceschanged_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3.7,3.3,1,0), mgp=c(1.4,0.3,0))
plot(x, y, ylab='', xlab='Fraction of Devices', yaxt='n', xaxt='n', 
        ylim=c(0,1), xlim=c(0,1), cex.lab=1.4, type='l', lwd=2, lty='solid')

lines(xY, yY, type='l', lty="dashed", lwd=2)

mtext("Fraction of Networks", 2, line=2, cex=1.4) 
mtext("Changed", 1, line=2.5, cex=1.4) 
axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,seq(0,1,0.3),seq(0,1,0.3),cex.axis=1.4,tck=0.03)
legend(-0.08,1.1,lwd=2, lty=c("solid","dashed"), legend=c("Month","Year"), bty="n", cex=1.4, seg.len=1.5)
dev.off()

print("% of networks with < half of devices changed per month")
print(ecdf(x)(0.4999))
print("% of networks with < quarter of devices changed per month")
print(ecdf(x)(0.2499))
print("% of networks with > half of devices changed per year")
print(1-ecdf(xY)(0.4999))
print("% of networks with > 75% of devices changed per year")
print(1-ecdf(xY)(0.7499))
