datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
lastmonth <- metrics[which(metrics$Month=="2014-12"),]
x <- lastmonth$NormalizedEntropy
y <- lastmonth$NormalizedFirmwareEntropy

plotfile <- paste(datapath,'plots','firmwareentropy_vs_hardwareentropy.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.1,1,0.4), mgp=c(1.8,0.3,0))
plot(x, y, ylab='Firmware Entropy', xlab='Hardware Entropy', yaxt='n', xaxt='n', xlim=c(0,0.8), ylim=c(0,0.8),
        cex.lab=1.4, type='p')
axis(2,seq(0,1,0.2),las=2,cex.axis=1.4,tck=0)
axis(1,seq(0,1,0.2),cex.axis=1.4,tck=0)
dev.off()

print("Pearson correlation coefficient")
print(cor(x,y,method="pearson"))
print("Kendall correlation coefficient")
print(cor(x,y,method="kendall"))
