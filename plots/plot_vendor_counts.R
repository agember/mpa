across <- 4
down <- 2

datapath <- Sys.getenv("MGMTPLANE_DATA")
stopifnot(datapath != "")
fullpath <- paste(datapath,"vendor_present.txt",sep="/")
vendors <- read.table(fullpath, sep=" ", header=TRUE)

plotVendor <- function(v) {
    sorted <- sort(vendors[,v])
    sorted <- sorted[which(sorted > 0)]
    plot(sorted, ylab=v, xlab='', cex.lab=1.5, cex.axis=1.5, ylim=c(0,max(sorted)))
}

vendornames <- colnames(vendors)
vendornames <- vendornames[2:length(vendornames)]

graphfile <- paste(datapath,'graphs','vendor_counts.png',sep="/")
png(graphfile, height=down*100*2, width=across*100*2)
par(mfrow=c(down,across))
sapply(vendornames, plotVendor)
dev.off()
