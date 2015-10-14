datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
source(paste(codepath,'analyze/width_bins.R',sep="/"))
x <- binned$NumRoles
y <- metrics$NumModels
y <- y[which(x < 7)]
x <- x[which(x < 7)]


plotfile <- paste(datapath,'plots','numroles_nummodels_boxplot.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(2,3.2,0.5,0), mgp=c(0.7,0.2,0), cex=1.4)
boxplot(y~x, range=2, ylab='# of Models', xlab='# of Roles', 
        cex.lab=1.4, outline=FALSE)

medians <- tapply(y, x, median)
lines(1:length(medians),medians,lwd=5,col="#fdae61")

means <- tapply(y, x, mean)
lines(1:length(means),means,lwd=3,col="#d7191c")
dev.off()

