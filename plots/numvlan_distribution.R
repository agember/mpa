datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
lastmonth <- metrics[which(metrics$Month=="2014-12"),]
x <- sort(lastmonth$NumVlans[which(lastmonth$NumVlans > -1)])
len <- length(x)-1
y <- c(0:len)/len

plotfile <- paste(datapath,'plots','numVlan_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar = c(3, 3.3, 1, 0.9), mgp=c(2, 0.3, 0))
plot(log10(x), y, ylab='Fraction of Networks', xlab = '# of VLANs', cex.lab=1.4, type = 'l', lwd = 2, 
        yaxt='n', ylim=c(0,1))
axis(2,las=2,cex.axis=1.4,tck=0.03)
dev.off()

print("Minimum # of VLANs")
print(min(x))
print("Maximum # of VLANs")
print(max(x))
print("% of networks with 1 or more VLANs")
print(1-ecdf(x)(0))
print("% of networks with < 5 VLANs")
print(ecdf(x)(4.9))
print("% of networks with > 10 VLANs")
print(1-ecdf(x)(10))
print("% of networks with > 100 VLANs")
print(1-ecdf(x)(100))
