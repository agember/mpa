library(lsr)
datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "xiujun/Health9.csv"

fullpath <- paste(datapath,datafile,sep="/")
infogains <- read.table(fullpath, sep=",", header=TRUE)

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

infogains <- infogains[which(is.element(infogains$Metric,mgmtnames)),]

infogains$Pretty <- sapply(infogains$MgmtIndex,getPrettyByIndex)
print(infogains[order(-infogains$InfoGain),c('Pretty','InfoGain')],right=FALSE)
