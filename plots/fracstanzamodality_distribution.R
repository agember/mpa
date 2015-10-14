datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))


plotfile <- paste(datapath,'plots','fracstanzamodality_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.5,1,0), mgp=c(2,0.3,0))

at <- metrics$RawNumFullAutoTypes/metrics$RawNumTypes
ut <- metrics$RawNumFullUnknTypes/metrics$RawNumTypes
df <- data.frame(at,ut)
df <- df[order(df$ut,df$at),]

x <- sort(df$at)
len <- length(x)-1
y <- c(0:len)/len
plot(x, y, ylab='Fraction of Networks', xlab='Fraction of Types', ylim=c(0,1), 
        xlim=c(0,1), yaxt='n', xaxt='n', cex.lab=1.4, type='l', lwd=2, lty="solid")

x <- sort(df$ut)
len <- length(x)-1
y <- c(0:len)/len
lines(x, y, lwd=2, lty="dashed")

axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,seq(0,1,0.3),seq(0,1,0.3),cex.axis=1.4,tck=0.03)
legend(0.08,0.3,lwd=2, lty=c("solid","dashed"), 
        legend=c("Always auto","Always manual"), bty="n", cex=1.4, seg.len=1, x.intersp=0.1)
dev.off()

