across <- 5
down <- 7

plotSortedMetric <- function(m) {
    sorted <- sort(metrics[(which(metrics$NumDevices >=5)),m])
    if (m != "Architecture") {
        sorted <- sorted[which(sorted >= 0)]
    }
    plot(sorted, ylab=m, xlab='', cex.lab=1.5, cex.axis=1.5)
}

metricnames <- colnames(metrics)
metricnames <- metricnames[!sapply(metricnames, is.element, binarynames)]
metricnames <- metricnames[!sapply(metricnames, is.element, idnames)]
#metricnames <- metricnames[!sapply(metricnames, is.element, discretenames)]
excludes <- c('NormalizedNumTickets','NormalizedNumLossTickets',
    'TotalTicketDuration','AvgTicketDuration','NumEvents','NumLossEvents','NumUndupEvents',
    'NumLossUndupEvents','NumNoLossUndupEvents','TotalUndupEventDuration','AvgUndupEventDuration')
metricnames <- metricnames[!sapply(metricnames, is.element, excludes)]

graphfile <- paste(datapath,'graphs',paste(datafile,'.png',sep=''),sep="/")
png(graphfile, height=down*100*2, width=across*100*2)
par(mfrow=c(down,across))
sapply(metricnames, plotSortedMetric)
dev.off()
