datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))

plotfile <- paste(datapath,'plots','fracstanzachanges_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.3,1,0), mgp=c(1.8,0.3,0))

x <- sort(metrics$RawStanzaInterfaceChanges/metrics$RawNumChanges)
len <- length(x)-1
y <- c(0:len)/len
plot(x, y, ylab='Fraction of Networks', xlab='Fraction of Changes', ylim=c(0,1), xlim=c(0,1), 
        yaxt='n', xaxt='n', cex.lab=1.4, type='l', lwd=2, lty="solid", col="#d7191c")

x <- sort(metrics$RawStanzaPoolChanges/metrics$RawNumChanges)
lines(x, y, lwd=2, lty="solid", col="#fdae61")

print("% of networks with no pool changes")
print(ecdf(x)(0))

x <- sort(metrics$RawStanzaAclChanges/metrics$RawNumChanges)
lines(x, y, lwd=2, lty="solid", col="#2b83ba")

x <- sort(metrics$RawStanzaRouterChanges/metrics$RawNumChanges)
lines(x, y, lwd=2, lty="dashed", col="#d7191c")

x <- sort(metrics$RawStanzaUserChanges/metrics$RawNumChanges)
lines(x, y, lwd=2, lty="dashed", col="#fdae61")

axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,seq(0,1,0.3),seq(0,1,0.3),cex.axis=1.4,tck=0.03)
legend(0.45,0.7,lwd=2, lty=c("solid","solid","solid","dashed","dashed"), 
        col=c("#d7191c","#fdae61","#2b83ba","#d7191c","#fdae61"),
        legend=c("iface","pool","acl","router","user"), bty="n", cex=1.4, seg.len=1.5, x.intersp=0.1)
dev.off()

