datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
hasChanges <- metrics[which(metrics$RawNumChanges > 0),]
x <- tapply(hasChanges$RawNatureAutoChanges/hasChanges$RawNumChanges, hasChanges$StampName, mean)
#xN <- tapply(metrics$RawNumChanges, metrics$StampName, mean)
#xA <- tapply(metrics$RawNatureAutoChanges, metrics$StampName, mean)
#x <- xA/xN
x <- sort(x)
len <- length(x)-1
y <- c(0:len)/len

plotfile <- paste(datapath,'plots','fracautochanges_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3.5,3.5,1,0), mgp=c(2,0.3,0))
plot(x, y, ylab='Fraction of Networks', xlab=' ', ylim=c(0,1), xlim=c(0,1), 
        yaxt='n', xaxt='n', cex.lab=1.4, type='l')
mtext("Fraction of Changes", 1, line=1.3, cex=1.4) 
mtext("Automated/Month", 1, line=2.3, cex=1.4) 
axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,seq(0,1,0.3),seq(0,1,0.3),cex.axis=1.4,tck=0.03)
dev.off()

print("% of networks with > half of changes automated")
print(1-ecdf(x)(0.5))

print("% of networks with > quarter of changes automated")
print(1-ecdf(x)(0.25))

xN <- tapply(hasChanges$RawNumChanges, hasChanges$StampName, mean)
print("Pearson correlation between fraction of auto changes and number of changes")
print(cor(xN[names(x)],x,method="pearson"))
