datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))

plotfile <- paste(datapath,'plots','fracstanzaautochanges_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.5,1,0), mgp=c(2,0.3,0))

x <- sort(metrics$RawAutoStanzaInterfaceChanges/metrics$RawStanzaInterfaceChanges)
len <- length(x)-1
y <- c(0:len)/len
iface <- x
plot(x, y, ylab='Fraction of Networks', xlab='Fraction Automated', ylim=c(0,1), xlim=c(0,1), yaxt='n', 
        xaxt='n', cex.lab=1.4, type='l', lwd=2, lty="solid", col="gray40")

x <- sort(metrics$RawAutoStanzaPoolChanges/metrics$RawStanzaPoolChanges)
len <- length(x)-1
y <- c(0:len)/len
pool <- x
lines(x, y, lwd=2, lty="solid")

x <- sort(metrics$RawAutoStanzaAclChanges/metrics$RawStanzaAclChanges)
len <- length(x)-1
y <- c(0:len)/len
acl <- x
lines(x, y, lwd=2, lty="dotted")

x <- sort(metrics$RawAutoStanzaRouterChanges/metrics$RawStanzaRouterChanges)
len <- length(x)-1
y <- c(0:len)/len
lines(x, y, lwd=2, lty="dashed")

x <- sort(metrics$RawAutoStanzaUserChanges/metrics$RawStanzaUserChanges)
len <- length(x)-1
y <- c(0:len)/len
lines(x, y, lwd=2, lty="dashed", col="gray40")

axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,seq(0,1,0.3),seq(0,1,0.3),cex.axis=1.4,tck=0.03)
legend(0.45,0.7,lwd=2, lty=c("solid","solid","dotted","dashed","dashed"), col=c("gray40","black","black","black","gray40"),
        legend=c("iface","pool","acl","router","user"), bty="n", cex=1.4, seg.len=1.5, x.intersp=0.1)
dev.off()

