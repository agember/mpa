binbounds <- c(0,0.33,0.66,1)

normentropy <- cut(simple$NormalizedEntropy, binbounds, include.lowest=TRUE, 
        labels=FALSE, right=FALSE)
health <- simple$NumTickets/simple$NumDevices

means <- sapply(seq(1,3), function(g) mean(health[which(normentropy==g)]))
sds <- sapply(seq(1,3), function(g) sd(health[which(normentropy==g)]))

print(means)
print(sds)

error.bar <- function(x, y, upper, lower=upper, length=0.1, ...){
    if(length(x) != length(y) | length(y) !=length(lower) | length(lower) != length(upper))
        stop("vectors must be same length")
    arrows(x,y+upper, x, y-lower, angle=90, code=3, length=length, ...)
}

plotfile <- paste(datapath,'plots','hotnets_normentropy_vs_health.png',sep='/')
png(plotfile, height=300, width=500)
xtics <- barplot(means, ylab='tickets/nw size', xlab='normalized entropy')
error.bar(xtics, means, sds)
box(which='plot', lty='solid')
dev.off()


