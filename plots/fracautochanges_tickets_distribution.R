datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
source(paste(codepath,'analyze/width_bins.R',sep="/"))
x <- binned$FracNatureAutoChanges
y <- metrics$NumTickets


plotfile <- paste(datapath,'plots','fracautochanges_tickets_boxplot.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.2,0.5,0), mgp=c(1.7,0.2,0))
boxplot(y~x, range=2, ylab='# of Tickets', xlab='Fraction of\nChanges Automated', ylim=c(0,40), yaxt='n', xaxt='n',
        cex.lab=1.4)

medians <- tapply(y, x, median)
lines(1:length(medians),medians,lwd=3,col="#fdae61")

means <- tapply(y, x, mean)
lines(1:length(means),means,lwd=3,col="#d7191c")
#axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(2,c(0,40),c(0,'O(10)'),las=2,cex.axis=1.4,tck=0.03)
axis(1,c(0.5,9.5),c(0,1),cex.axis=1.4,tck=0)
dev.off()

