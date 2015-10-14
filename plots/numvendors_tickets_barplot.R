datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
source(paste(codepath,'analyze/width_bins.R',sep="/"))
bcol <- binned$NumVendors
ubcol <- metrics$NumTickets
keeps <- which(!is.na(bcol))
avgs <- tapply(ubcol[keeps], bcol[keeps], mean)


plotfile <- paste(datapath,'plots','numvendors_tickets_barplot.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(2.6,2.7,0.5,0), mgp=c(1.55,0.2,0))
xtics <- barplot(avgs, ylab='Tickets', xlab='# of Vendors', yaxt='n', xaxt='n',
        cex.lab=1.4)

y <- c(avgs[1],avgs[3],avgs[4],avgs[5],avgs[6])
x <- c(xtics[1],xtics[3],xtics[4],xtics[5],xtics[6])
lines(x,y,lwd=2)

axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,xtics,seq(1,6,1),cex.axis=1.4,tck=0)
box(which = "plot", lty = "solid")
dev.off()

