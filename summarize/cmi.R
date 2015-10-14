library(lsr)
datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "xiujun/pairs_cmi_labeled.csv"

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

infogains <- infogains[which(is.element(infogains$NameA,mgmtnames)),]
infogains <- infogains[which(is.element(infogains$NameB,mgmtnames)),]

infogains$PrettyA <- sapply(infogains$IndexA,getPrettyByIndex)
infogains$PrettyB <- sapply(infogains$IndexB,getPrettyByIndex)
print(head(infogains[order(-infogains$LossValue),c('PrettyA','PrettyB','LossValue')],n=10),right=FALSE)
