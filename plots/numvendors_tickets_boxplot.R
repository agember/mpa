datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
source(paste(codepath,'analyze/width_bins.R',sep="/"))
x <- binned$NumVendors
y <- metrics$NumTickets

medians <- tapply(y, x, median)

plotfile <- paste(datapath,'plots','numvendors_tickets_boxplot.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(2.6,3.2,0.5,0), mgp=c(1.3,0.2,0))
boxplot(y~x, range=0, ylab='# of Tickets', xlab='# of Vendors', xaxt='n',
        cex.lab=1.4)

lines(1:length(medians),medians,lwd=3,col="#fdae61")

axis(1,seq(1,6,1),seq(1,6,1),cex.axis=1.4,tck=0)
dev.off()

