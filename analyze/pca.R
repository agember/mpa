library(scatterplot3d)

codepath <- Sys.getenv("MGMTPLANE_CODE")
source(paste(codepath,'summarize/pretty_names.R',sep="/"))
numbins <- 5

# Prepare data
source(paste(codepath,'analyze/read_metrics.R',sep="/"))
m <- metrics[,c(as.character(goodmetrics$Name),'StampName','Month')]
cat(paste("Read metrics ",datafile,"\n",sep=""))

m$FractionDevicesChanged[which(m$NumChanges==0)] <- 0
m$MeanDevicesChanged[which(m$NumChanges==0)] <- 0
m$FractionAutoChanges[which(m$NumChanges==0)] <- 0
m$FractionRoleMboxChanges[which(m$NumChanges==0)] <- 0
m$FractionStanzaInterfaceChange[which(m$NumChanges==0)] <- 0
m$FractionStanzaVlanChange[which(m$NumChanges==0)] <- 0
m$FractionStanzaRouterChange[which(m$NumChanges==0)] <- 0
m$FractionStanzaAclChange[which(m$NumChanges==0)] <- 0
m$FractionStanzaPoolChange[which(m$NumChanges==0)] <- 0
m$FractionStanzaUserChange[which(m$NumChanges==0)] <- 0
m$FractionRoleMboxChanges[which(m$FractionRoleMboxChanges<0)] <- 0
m$FractionStanzaPoolChange[which(m$FractionStanzaPoolChange<0)] <- 0
m$NormIntraRefComplex[which(m$NormIntraRefComplex<0)] <- mean(m$NormIntraRefComplex[which(m$NormIntraRefComplex>=0)])
m$NormInterRefComplex[which(m$NormInterRefComplex<0)] <- mean(m$NormInterRefComplex[which(m$NormInterRefComplex>=0)])
m$AvgOspfSize[which(m$NumOspfInst==0)] <- 0
m$AvgBgpSize[which(m$NumBgpInst==0)] <- 0
m$NumConnectedStamps[which(m$NumConnectedStamps<0)] <- 0

source(paste(codepath,'analyze/width_bins.R',sep="/"))
bounds <-  c(0,8,max(metrics$NumTickets))
binnums <- cut(metrics$NumTickets, bounds, include.lowest=TRUE, labels=FALSE, right=FALSE)
m$NumTickets <- binnums
#m$NumTickets <- binned$NumTickets

m <- na.omit(m)
cat(paste(nrow(m)," datapoints\n",sep=""))

#sapply(as.character(goodmetrics$Name), function(c) m[,c] <<- scale(m[,c]))

# Run pca
pca <- prcomp(m[,1:(ncol(m)-3)], center=TRUE, scale=TRUE)

# Plot stdev
plotfile <- paste(datapath,'plots','pca_stdev.png',sep="/")
png(plotfile, height=450, width=600)
par(mar=c(4,4,1,0), mgp=c(2.5,1,0))
plot(pca$sdev, type='o', ylab='Std Dev', xlab='Component', lwd=2,
        cex.axis=1.5, cex.lab=1.5)
dev.off()
cat(paste("Created plot ",plotfile,"\n",sep=""))

scores <- data.frame(pca$x)

# Plot points
colors <- c("#d7191c","#fdae61","#ffffbf","#abdda4","#2b83ba")
colors <- c("#d7191c","#fdae61","#2b83ba")
names(colors) <- names(table(m$NumTickets))
m$Color <- sapply(m$NumTickets, function(x) colors[as.character(x)])

blue <- "#2b83ba"
#m[which(scores$PC1 < 0 & scores$PC3 < -2),'Color'] <- blue

plotfile <- paste(datapath,'plots','pca_points.png',sep="/")
png(plotfile, height=500, width=700)
#plot(scores$PC1, scores$PC2, col=m$Color, pch=20)
scatterplot3d(scores$PC1, scores$PC2, scores$PC3, color=m$Color, angle=45+85, 
        xlab='PC1', ylab='PC2', zlab='PC3', cex.lab=1.5, cex.axis=1.5, 
#        mar=c(2.5,3,0,0), 
        mar=c(2.5,0,0,2.5), 
        type='p', pch=20)
legend("bottomleft", #"bottomright", 
        c('0-7 Tickets','>= 8 Tickets'),
        col=colors, pch=20, cex=1.5)
mtext("PC2", side=2,las=2,padj=14,line=-14,cex=1.5)
#mtext("PC2", side=4,las=2,padj=14,line=-14,cex=1.5)
dev.off()
cat(paste("Created plot ",plotfile,"\n",sep=""))

# Plot feature influence
influences <- data.frame(abs(pca$rotation))

plotfile <- paste(datapath,'plots','pca_features.png',sep="/")
png(plotfile, height=750, width=1050)
s3d <- scatterplot3d(influences$PC1, influences$PC2, influences$PC3, angle=25, 
        xlab='PC1', ylab='PC2', zlab='PC3', cex.lab=1.5, cex.axis=1.5, 
        mar=c(2.5,3,0,1.5), type='h')

# convert 3D coords to 2D projection
coords2d <- s3d$xyz.convert(influences$PC1, influences$PC2, influences$PC3)
text(coords2d$x, coords2d$y, labels=row.names(influences), cex=1, pos=4)
dev.off()
cat(paste("Created plot ",plotfile,"\n",sep=""))

regular <- m[which(m$Color!=blue),]
special <- m[which(m$Color==blue),]
plotSortedMetric <- function(colname, data) {
    barplot(table(data[,colname]), xlab=colname, ylab='', cex.lab=1.5, cex.axis=1.5)
}
metricnames <- colnames(m)[1:(ncol(m)-3)]

across <- 5
down <- 7
plotfile <- paste(datapath,'plots','pca_histograms.png',sep="/")
png(plotfile, height=down*100*2, width=across*100*2)
par(mfrow=c(down,across))
sapply(metricnames, plotSortedMetric, m)
dev.off()
cat(paste("Created plot ",plotfile,"\n",sep=""))

#plotfile <- paste(datapath,'plots','pca_special.png',sep="/")
#png(plotfile, height=down*100*2, width=across*100*2)
#par(mfrow=c(down,across))
#sapply(metricnames, plotSortedMetric, special)
#dev.off()
#cat(paste("Created plot ",plotfile,"\n",sep=""))

#plotfile <- paste(datapath,'plots','pca_regular.png',sep="/")
#png(plotfile, height=down*100*2, width=across*100*2)
#par(mfrow=c(down,across))
#sapply(metricnames, plotSortedMetric, regular)
#dev.off()
#cat(paste("Created plot ",plotfile,"\n",sep=""))
