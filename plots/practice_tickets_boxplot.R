datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
source(paste(codepath,'analyze/width_bins.R',sep="/"))

designnames <- c('NumProperties','NumDevices','NumVendors','NumModels','NumRoles',
        'NormalizedEntropy','NormalizedFirmwareEntropy',
        'NumL2Protocols','NumL3Protocols','NumVlans','NumBgpInst','NumOspfInst',
        'NormIntraRefComplex','NormInterRefComplex')

operationnames <- c('RawNumChanges','FracNatureAutoChanges','RawNumTypes',
        'NumChanges','MeanDevicesChanged','FractionDevicesChanged','FractionAutoChanges',
        'FractionRoleMboxChanges',
        'FractionStanzaInterfaceChange','FractionStanzaVlanChange','FractionStanzaRouterChange',
        'FractionStanzaAclChange','FractionStanzaPoolChange','FractionStanzaUserChange')

mgmtnames <- c(designnames,operationnames) 

periods <- unique(metrics$Month)

plotPractice <- function(name, period) {
    x <- binned[which(binned$Month==period),name]
    y <- metrics[which(binned$Month==period),'NumTickets']
    boxplot(y~x, ylab='# of Tickets', xlab=name, ylim=c(0,40), cex.lab=1.4, range=2, title=period)
    medians <- tapply(y, x, median)
    lines(1:length(medians),medians,lwd=3,col="#fdae61")
    means <- tapply(y, x, mean)
    lines(1:length(means),means,lwd=3,col="#d7191c")
    
}

across <- 5
down <- 7

plotPeriod <- function(period) {
    plotfile <- paste(datapath,'plots',paste('practice_tickets_boxplot_',period,'.pdf',sep=""),sep="/")
    pdf(plotfile, height=3*down, width=3*across)
    par(mfrow=c(down,across))
    sapply(mgmtnames, plotPractice, period)
    dev.off()
}

sapply(periods, plotPeriod)
