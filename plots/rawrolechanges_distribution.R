datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))

metrics <- metrics[which(metrics$RawNumChanges>0),]
dfChange <- data.frame(
            metrics$RawSwitchChanges/metrics$RawNumChanges,
            metrics$RawLoadBalancerChanges/metrics$RawNumChanges,
            metrics$RawL3SwitchChanges/metrics$RawNumChanges,
            metrics$RawRouterChanges/metrics$RawNumChanges, 
            metrics$RawFirewallChanges/metrics$RawNumChanges,
            metrics$RawApplicationChanges/metrics$RawNumChanges)
colnames(dfChange) <- c('Switch','LoadBal','L3Switch','Router','Firewall','ADC')
mostChange <- apply(dfChange, 1, which.max)

counts <- table(mostChange)
counts <- counts/nrow(metrics)
lbls <- colnames(dfChange)

plotfile <- paste(datapath,'plots','rawrolechanges_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(4,3.5,1,0), mgp=c(2,0.3,0))
xtics <- barplot(counts, ylab='Fraction of Networks', xlab='', ylim=c(0,1), xaxt='n', yaxt='n',
        cex.lab=1.4)
axis(2,las=2,cex.axis=1.4,tck=0.03)
text(xtics+0.5, -0.03, labels=lbls[1:4], cex=1.4, srt=45, xpd=TRUE, pos=2)
box(which = "plot", lty = "solid")
dev.off()
