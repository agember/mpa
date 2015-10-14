binbounds <- c(0,1,2,3)

filtered <- simple[which(simple$NormalizedEntropy < 0.33),]

rateofchange <- cut(filtered$RateOfChange, binbounds, include.lowest=TRUE, 
        labels=FALSE, right=FALSE)
health <- filtered$NumTickets/filtered$NumDevices

means <- sapply(seq(1,3), function(g) mean(health[which(rateofchange==g)]))
sds <- sapply(seq(1,3), function(g) sd(health[which(rateofchange==g)]))

print(means)
print(sds)

error.bar <- function(x, y, upper, lower=upper, length=0.1, ...){
    if(length(x) != length(y) | length(y) !=length(lower) | length(lower) != length(upper))
        stop("vectors must be same length")
    arrows(x,y+upper, x, y-lower, angle=90, code=3, length=length, ...)
}

plotfile <- paste(datapath,'plots','hotnets_rateofchange_vs_health.png',sep='/')
png(plotfile, height=300, width=500)
xtics <- barplot(means, ylab='tickets/nw size', xlab='change events/day')
error.bar(xtics, means, sds)
box(which='plot', lty='solid')
dev.off()


