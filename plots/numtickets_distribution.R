datapath <- Sys.getenv("MGMTPLANE_DATA")

counts <- table(metrics$NumTickets)

binnums <- cut(metrics$NumTickets, c(0,1,8,max(metrics$NumTickets)), 
        include.lowest=TRUE, labels=FALSE, right=FALSE)
df <- data.frame(binnums, metrics$NumTickets)
colnames(df) <- c('Bin','Raw')

#counts <- table(df$Bin)

plotfile <- paste(datapath,'plots','numtickets_distribution.png',sep="/")
png(plotfile, height=400, width=550)
par(mar=c(3,4.5,1,0), mgp=c(2,0.4,0))
xtics <- barplot(counts, ylab='', xlab='# of Tickets', 
       xaxt='n', yaxt='n', cex.lab=1.4)
mtext("Number of <stamp,month> tuples", 2, line=3, cex=1.4) 
axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1, xtics, 0:(length(counts)-1), cex.axis=1.4, tick=FALSE)
box(which = "plot", lty = "solid")
dev.off()

