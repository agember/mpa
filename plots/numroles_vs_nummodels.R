datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
x <- metrics$NumRoles
y <- metrics$NumTickets
y <- y[which(x < 7)]
x <- x[which(x < 7)]


plotfile <- paste(datapath,'plots','numroles_vs_nummodels.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3,3.2,0.5,0), mgp=c(1.7,0.2,0))
plot(x,y, ylab='# of Models', xlab='# of Roles', 
        cex.lab=1.4)

dev.off()

