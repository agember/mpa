datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
x <- tapply(metrics$RawNumChanges, metrics$StampName, mean)
y <- tapply(metrics$NumDevices, metrics$StampName, mean)

plotfile <- paste(datapath,'plots','rawnumchanges_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.5,1,0.1), mgp=c(2,0.3,0))
plot(x, y, ylab='# of Devices', xlab=' ', 
        cex.lab=1.4, type='p')
mtext("# of Changes/Month", 1, line=1.5, cex=1.4) 
dev.off()

print("Highest # of changes with approx 20 devices")
changes <- max(x[which(y>20 & y<25)])
print ("# of changes")
print(changes)
print ("# of devices")
print(y[which(x==changes)])
print(max(x[which(y==20)]))

print("Smallest # of devices with approx 300 changes")
devices <- min(y[which(x>300 & x<350)])
print ("# of devices")
print(devices)
print ("# of changes")
print(x[which(y==devices)])
