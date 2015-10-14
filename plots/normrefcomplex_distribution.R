datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
#lastmonth <- metrics[which(metrics$Month=="2013-08"),]
lastmonth <- metrics
x <- sort(log10(lastmonth[which(lastmonth$NormIntraRefComplex>0),'NormIntraRefComplex']))
len <- length(x)-1
y <- c(0:len)/len

xF <- sort(log10(lastmonth[which(lastmonth$NormInterRefComplex>0),'NormInterRefComplex']))
len <- length(xF)-1
yF <- c(0:len)/len

plotfile <- paste(datapath,'plots','normrefcomplex_distribution.pdf',sep="/")
pdf(plotfile, height=3, width=3)
par(mar=c(4,3.3,1,0.9), mgp=c(1.5,0.3,0))
plot(x, y, ylab='', xlab='Normalized', 
        ylim=c(0,1), xlim=c(0,3), 
        yaxt='n', xaxt='n', cex.lab=1.4, type='l', lwd=2)
lines(xF, yF, type='l', lty="dashed", lwd=2)
mtext("Fraction of Networks", 2, line=2, cex=1.4) 
mtext("Referential Complexity", 1, line=2.5, cex=1.4) 
axis(2,las=2,cex.axis=1.4,tck=0.03)
axis(1,0:3,c(0,10,100,1000),cex.axis=1.4,tck=0.03)
legend(1,0.35,lwd=2, lty=c("solid","dashed"), legend=c("Intra","Inter"), bty="n", cex=1.4, seg.len=1.5)
dev.off()

print("% of networks with Log(NormIntraRefComplex) > 2")
print(1-ecdf(x)(2))
print("% of networks with Log(NormIntraRefComplex) > 2")
print(1-ecdf(x)(2))

#print("% of networks with one role and one model")
#print(length(which(lastmonth$NumRoles==1 & lastmonth$NumModels==1))/length(lastmonth$StampName))
#print("Highest entropy")
#print(max(x))

print("Pearson correlation between NumDevices and NormIntraRefComplex")
print(cor(lastmonth$NumDevices,lastmonth$NormIntraRefComplex,method="pearson"))

print("Pearson correlation between NumDevices and NormInterRefComplex")
print(cor(lastmonth$NumDevices,lastmonth$NormInterRefComplex,method="pearson"))

print("Pearson correlation between NormalizedEntropy and NormInterRefComplex")
print(cor(lastmonth$NormalizedEntropy,lastmonth$NormInterRefComplex,method="pearson"))

print("Pearson correlation between NormalizedEntropy and NormIntraRefComplex")
print(cor(lastmonth$NormalizedEntropy,lastmonth$NormIntraRefComplex,method="pearson"))

