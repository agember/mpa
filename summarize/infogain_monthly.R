library(lsr)
datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "xiujun/1_univariate_fullrange_nona/Health9.csv"

fullpath <- paste(datapath,datafile,sep="/")
infogains <- read.table(fullpath, sep=",", header=TRUE)

source(paste(codepath,'analyze/kendall.R',sep="/"))
periods <- unique(infogains$Month)
keeps <- 1:length(periods)
periods <- periods[keeps]

designnames <- c('NumProperties','NumDevices','NumVendors','NumModels','NumRoles',
        'NormalizedEntropy','NormalizedFirmwareEntropy',
        'NumL2Protocols','NumL3Protocols','NumVlans', 'NumOspfInst','AvgOspfSize','NumBgpInst','AvgBgpSize',
        'NormIntraRefComplex','NormInterRefComplex')

operationnames <- c('RawNumChanges','FracNatureAutoChanges','RawNumTypes',
        'NumChanges','MeanDevicesChanged','FractionDevicesChanged','FractionAutoChanges',
        'FractionRoleMboxChanges',
        'FractionStanzaInterfaceChange','FractionStanzaVlanChange','FractionStanzaRouterChange',
        'FractionStanzaAclChange','FractionStanzaPoolChange','FractionStanzaUserChange')

mgmtnames <- c(designnames,operationnames) 

medianMetric <- function(name, igs) {
    return(mean(igs[keeps,name]))
}

devs <- data.frame(sapply(mgmtnames, medianMetric, infogains))
colnames(devs) <- c("Mean")
devs$Names <- mgmtnames
rownames(devs) <- 1:nrow(devs)
devs$Pretty <- sapply(mgmtnames,getPrettyByName)
print(devs[order(-devs$Mean),c('Pretty','Mean','Names')],right=FALSE)
