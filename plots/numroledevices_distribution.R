datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))

dfRole <- data.frame(metrics$NumRoleRouter/metrics$NumDevices, 
            metrics$NumRoleSwitch/metrics$NumDevices,
            metrics$NumRoleL3Switch/metrics$NumDevices,
            metrics$NumRoleLoadBalancer/metrics$NumDevices,
            metrics$NumRoleFirewall/metrics$NumDevices,
            metrics$NumRoleApplication/metrics$NumDevices)
colnames(dfRole) <- c('Router','Switch','L3Switch','LB','FW','ADC')
mostRole <- apply(dfRole, 1, which.max)


plotfile <- paste(datapath,'plots','numroledevices_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(3.5,5,1,0), mgp=c(2.5,0.3,0))

#metrics <- metrics[which(metrics$NumRoles > 2),]

x <- sort(metrics$NumRoleRouter/metrics$NumDevices)
#x[which(x==0)] <- NA
len <- length(x)-1
y <- c(0:len)/len
plot(x, y, ylab='Fraction of networks', xlab='Fraction of devices', yaxt='n', xaxt='n', xlim=c(0,1),
        ylim=c(0,1), cex.lab=1.4, type='l', lwd=2, pch=1)

x <- sort(metrics$NumRoleSwitch/metrics$NumDevices)
#x[which(x==0)] <- NA
lines(x, y, lty="dashed", lwd=2, type='l', pch=2) 

x <- sort(metrics$NumRoleL3Switch/metrics$NumDevices)
#x[which(x==0)] <- NA
lines(x, y, lty="dotted", lwd=2, type='l', pch=3) 

x <- sort(metrics$NumRoleLoadBalancer/metrics$NumDevices)
#x[which(x==0)] <- NA
lines(x, y, lty="longdash", lwd=2, type='l', pch=4) 

x <- sort(metrics$NumRoleFirewall/metrics$NumDevices)
#x[which(x==0)] <- NA
lines(x, y, lty="solid", lwd=2, type='l', pch=5) 

x <- sort(metrics$NumRoleApplication/metrics$NumDevices)
#x[which(x==0)] <- NA
lines(x, y, lty="solid", lwd=2, type='l', pch=0) 

axis(2,las=2,cex.axis=1.4,tck=0.03)
#axis(1,seq(0,1,0.3),seq(0,1,0.3),cex.axis=1.4,tck=0.03)
axis(1,cex.axis=1.4,tck=0.03)
dev.off()

