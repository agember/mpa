datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
lastmonth <- metrics[which(metrics$Month=="2014-12"),]
x <- sort(lastmonth$NumProperties-lastmonth$HasUnspecifiedProperty)
len <- length(x)-1
y <- c(0:len)/len

plotfile <- paste(datapath,'plots','numproperties_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar = c(3, 3.3, 1, 0.9), mgp=c(2, 0.3, 0))
plot(x, y, ylab='Fraction of Networks', xlab = '# of Services', cex.lab=1.4, type = 'l', lwd = 2, 
        yaxt='n', ylim=c(0,1))
axis(2,las=2,cex.axis=1.4,tck=0.03)
dev.off()

unspecstamps <- lastmonth[which(lastmonth$StampProperty=="unspecified"),]
print("# of stamps with unspecified property")
print(nrow(unspecstamps))

print("% of stamps with unspecified property and all unspecified devices")
print(ecdf(x)(0))

print("% of networks with 1 property")
print(length(which(x==1))/nrow(lastmonth))
