datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
source(paste(codepath,'analyze/width_bins.R',sep="/"))
source(paste(codepath,'analyze/kendall.R',sep="/"))

designnames <- c('NumProperties','NumDevices','NumVendors','NumModels','NumRoles',
        'NormalizedEntropy','NormalizedFirmwareEntropy',
        'NumL2Protocols','NumL3Protocols','NumVlans',
        'NormIntraRefComplex','NormInterRefComplex')

operationnames <- c('RawNumChanges','RawNatureAutoChanges','RawNumTypes',
        'NumChanges','MeanDevicesChanged','FractionDevicesChanged','FractionAutoChanges',
        'FractionRoleMboxChanges',
        'FractionStanzaInterfaceChange','FractionStanzaVlanChange','FractionStanzaRouterChange',
        'FractionStanzaAclChange','FractionStanzaPoolChange','FractionStanzaUserChange')

mgmtnames <- c(designnames,operationnames) 

corAll <- function(method) {
    return(sapply(mgmtnames, method, 'NumTickets', binned, metrics))
}

corrs <- data.frame(sapply(c(corMetricPairPearson, corMetricPairKendall),corAll))
colnames(corrs) <- c("Pearson","Kendall")
print(corrs)
