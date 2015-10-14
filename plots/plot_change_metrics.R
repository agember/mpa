across <- 2
down <- 4

plotSortedMetric <- function(m) {
    sorted <- sort(metrics[,m])
    sorted <- sorted[which(sorted >= 0)]
    max <- 2
    if (grepl("Fraction", m)) {
        max <- 1
    }
    plot(sorted, ylab=m, xlab='', ylim=c(0, max), cex.lab=1.5, cex.axis=1.5)
}

#'TopChangeAction'
metricnames <- c('FractionWithInterfaceChange','RateOfInterfaceChanges','FractionWithVlanChange','RateOfVlanChanges','FractionWithRouterChange','RateOfRouterChanges','FractionWithAclChange','RateOfAclChanges')

graphfile <- paste(datapath,'graphs','changeaction_freq.png',sep="/")
png(graphfile, height=down*100*2, width=across*100*2)
par(mfrow=c(down,across))
sapply(metricnames, plotSortedMetric)
dev.off()

graphfile <- paste(datapath,'graphs','changeaction_top.png',sep="/")
png(graphfile, height=400, width=600)
counts <- sort(table(metrics$TopChangeAction))
xtics <- barplot(counts, ylim=c(0,max(counts)+100), xaxt='n', ylab='Number of Networks', xlab='Top Change Action', cex.lab=1.25, cex.axis=1.25)
text(x=xtics, y=max(counts), names(counts), srt=90, cex=1.25, adj=1)
dev.off()
