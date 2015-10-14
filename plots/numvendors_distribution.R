datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
source(paste(codepath,'analyze/quantile_bins.R',sep="/"))
counts <- table(binned$NumVendors)
counts <- counts/nrow(metrics)

plotfile <- paste(datapath,'plots','numvendors_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.5,1,0), mgp=c(2,0.3,0))
xtics <- barplot(counts, ylab='Fraction of Networks', xlab='# of Vendors', xaxt='n', yaxt='n',
        cex.lab=1.4)
axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1, xtics, 1:length(counts), cex.axis=1.4, tick=FALSE)
box(which = "plot", lty = "solid")
dev.off()

