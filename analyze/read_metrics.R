# Load data
datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
stopifnot(datapath != "")
stopifnot(datafile != "")
fullpath <- paste(datapath,datafile,sep="/")
metrics <- read.table(fullpath, sep=",", header=TRUE)
cat(paste("Loaded data from '",fullpath,"' into 'metrics'\n", sep=""))

healthnames <- c('NumTickets','NormalizedNumTickets','NumLossTickets', 
        'NormalizedNumLossTickets','TotalTicketDuration','AvgTicketDuration',
        'NumEvents','NumLossEvents','NumUndupEvents','NumLossUndupEvents',
        'NumNoLossUndupEvents','TotalUndupEventDuration',
        'AvgUndupEventDuration')
binarynames <- names(metrics)[grep("IsArch|HasModel|HasVendor|HasRole|HasUnspecified", names(metrics))]
rawrolenames <- names(metrics)[grep("RawRole", names(metrics))]
numrolenames <- names(metrics)[grep("NumRole", names(metrics))]
discretenames <- c('Architecture',
        'FirstPlaceChangeAction','SecondPlaceChangeAction',
        'RawFirstPlaceChangeAction','RawSecondPlaceChangeAction',
        'StampProperty')
idnames <- c('StampName', 'Month')

bnames <- c('NumRoles','NumVendors','NumDevices','NumModels','Entropy',
        'NormalizedEntropy','NumChanges','RateOfChange',
        'FractionDevicesChanged','MeanDevicesChanged',
        'FractionAutoChanges','FractionUnknownChanges',
        'FractionRoleMboxChanges','FractionRoleFwdChanges',
        'NumFirmware','FirmwareEntropy','NormalizedFirmwareEntropy',
        'IntraRefComplex','NormIntraRefComplex',
        'InterRefComplex','NormInterRefComplex')
typenames <- c('FractionStanzaInterfaceChanges','RateStanzaInterfaceChanges',
        'FractionStanzaVlanChange','RateStanzaVlanChanges',
        'FractionStanzaRouterChange','RateStanzaRouterChanges',
        'FractionStanzaAclChange','RateStanzaAclChanges',
        'FractionStanzaPoolChange','RateStanzaPoolChanges',
        'FractionStanzaUserChange','RateStanzaUserChanges')
rawchangenames <- c('RawNumChanges','RawRateOfChange',
        'RawNatureAutoChanges','RawNatureUnknownChanges')
rawtypenames <- c('RawStanzaInterfaceChanges','RawAutoStanzaInterfaceChanges',
        'RawStanzaVlanChanges','RawAutoStanzaVlanChanges',
        'RawStanzaRouterChanges','RawAutoStanzaRouterChanges',
        'RawStanzaAclChanges','RawAutoStanzaAclChanges',
        'RawStanzaPoolChanges','RawAutoStanzaPoolChanges',
        'RawStanzaUserChanges','RawAutoStanzaUserChanges',
        'RawNumTypes','RawNumFullAutoTypes','RawNumFullUnknTypes')

#metrics <- metrics[which(metrics$NumDevices>2),]
