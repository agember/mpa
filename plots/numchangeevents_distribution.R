datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
#x <- metrics$RawNumChanges/10
#y <- metrics$NumChanges/10

x <- metrics$NumChanges/10
y <- metrics$NumDevices

plotfile <- paste(datapath,'plots','numchangeevents_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3.5,3.5,1,0), mgp=c(2.2,0.3,0))
plot(x, y, ylab='# Devices', xlab='# Change Events/Month', 
        cex.lab=1.4, type='p')
dev.off()

