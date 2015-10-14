library(MatchIt)
library(BSDA)
codepath <- Sys.getenv("MGMTPLANE_CODE")
source(paste(codepath,'qed/signtest.R',sep="/"))
source(paste(codepath,'summarize/pretty_names.R',sep="/"))

factors <- c("NumDevices", "NumChanges","NormIntraRefComplex", "RawNumTypes", "NumVlans", "NumModels", "NumRoles", "MeanDevicesChanged", "FractionStanzaInterfaceChange", "FractionStanzaAclChange", "FractionAutoChanges","NumL2Protocols","AvgBgpSize","AvgOspfSize")
#factors <- as.character(goodmetrics$Name)
factors <- c('NumDevices','NumChanges','NormIntraRefComplex','RawNumTypes','NumVlans','NumModels','NumRoles',
        'MeanDevicesChanged','FractionStanzaInterfaceChange','FractionStanzaAclChange','FractionAutoChanges',
        'NumL2Protocols','AvgBgpSize','AvgOspfSize','NumProperties','NormalizedEntropy','FractionDevicesChanged',
        'FractionStanzaPoolChange','NormalizedFirmwareEntropy','FractionStanzaRouterChange','NormInterRefComplex',
        'FractionRoleMboxChanges','NumBgpInst','FractionStanzaVlanChange','NumVendors','FractionStanzaUserChange',
        'NumL3Protocols','NumOspfInst') 
#factors <- c('NumDevices','NumChanges','NormIntraRefComplex','RawNumTypes',
factors <- c('NumDevices','NumChanges','RawNumTypes',
        'NumVlans','NumModels','NumRoles','MeanDevicesChanged',
        'FractionStanzaInterfaceChange','FractionStanzaAclChange',
        'FractionAutoChanges','NumL2Protocols','NumProperties',
        'NormalizedEntropy','FractionDevicesChanged','FractionStanzaPoolChange',
        'NormalizedFirmwareEntropy','FractionStanzaRouterChange',
        'FractionRoleMboxChanges','NumBgpInst','FractionStanzaVlanChange',
        'NumVendors','FractionStanzaUserChange','NumL3Protocols','NumOspfInst') 


addfactors <- setdiff(as.character(goodmetrics$Name), factors)
cols <- c("NumTickets", factors)
#binned <- na.omit(binned)
#metrics <- na.omit(metrics)
qeddata <- binned[,cols]
qeddata <- metrics[,cols]
queddata <- na.omit(qeddata)
qeddata[is.na(qeddata)] <- 0

runMatch <- function(factor, untreat, treat) {
    tmpqeddata <- qeddata
    tmpqeddata[,factor] <- binned[,factor]
#    untreatLow <- quantile(tmpqeddata[,factor],(untreat-1)*0.2)
#    untreatHigh <- quantile(tmpqeddata[,factor],untreat*0.2)
#    treatLow <- quantile(tmpqeddata[,factor],(treat-1)*0.2)
#    treatHigh <- quantile(tmpqeddata[,factor],treat*0.2)
    tmpqeddata$Treated <- -1
#    tmpqeddata[which(tmpqeddata[,factor]>=untreatLow & tmpqeddata[,factor]<untreatHigh),'Treated'] <- 0
#    tmpqeddata[which(tmpqeddata[,factor]>=treatLow & tmpqeddata[,factor]<treatHigh),'Treated'] <- 1
    tmpqeddata[which(tmpqeddata[,factor]>=untreat-0.001 & tmpqeddata[,factor]<=untreat+0.001),'Treated'] <- 0
    tmpqeddata[which(tmpqeddata[,factor]>=treat-0.001 & tmpqeddata[,factor]<=treat+0.001),'Treated'] <- 1
#    tmpqeddata[which(tmpqeddata[,factor]<=untreatUpper+0.001),'Treated'] <- 0
#    tmpqeddata[which(tmpqeddata[,factor]>=treatLower-0.001),'Treated'] <- 1
    tmpqeddata <- tmpqeddata[which(tmpqeddata$Treated>=0),]
    cat(paste("Treated=",length(which(tmpqeddata$Treated==1)),"\n",sep=""))
    cat(paste("Untreated=",length(which(tmpqeddata$Treated==0)),"\n",sep=""))
#    tmpqeddata$Treated <- as.factor(tmpqeddata$Treated)

    confounding <- factors[which(factors!=factor)]
    formula <- paste('Treated', paste(confounding, collapse=" + "), sep=" ~ ")
    
    matchout <- tryCatch(
            matchit(as.formula(formula), data=tmpqeddata, method="nearest", 
                    ratio=1, replace=TRUE, 
#                  distance="rpart", distance.options=list(method="class"),
                    distance="logit", distance.options=list(maxit=5000),
                    discard="both", reestimate=TRUE)
            ,error=function(e) NULL)

    return(matchout)
}

batchMatch <- function(factor) {
    bins <- sort(unique(binned[,factor]))
    lowest <- bins[1]
    upper <- bins[2:length(bins)]
    matchouts <- lapply(1:(length(bins)-1), function(i, b) 
            runMatch(factor, bins[i], bins[(i+1)]), bins)
    return(matchouts)
}

checkBalance <- function(matchout, interactions=FALSE) {
    if (is.null(matchout)) {
        return(NULL)
    }
    matchTable <- summary(matchout, standardize=TRUE, interactions=interactions 
            )$sum.matched
#            addlvariables=binned[,addfactors])$sum.matched
    stdDiffMeans <- matchTable[,'Std. Mean Diff.']
    sdControl <- matchTable['SD Control']
    sdTreat <- (matchTable[,'Means Treated'] - matchTable[,'Means Control'])/stdDiffMeans
    ratioVariances <- (sdTreat^2) / (sdControl^2)
    matchBal <- data.frame(stdDiffMeans, ratioVariances, row.names=rownames(matchTable))
    colnames(matchBal) <- c('stdDiffMeans','ratioVariances')
    cat("----------\n")
    print(matchBal[1,])
    numViolations <- countViolations(matchBal)
    cat(paste("Violations=",numViolations,"\n",sep=""))
    if (numViolations > 0) {
        print(matchBal[which(matchBal$stdDiffMeans>0.25),])
    }
    return(matchBal)
}

countViolations <- function(matchBal) {
    numViolations <- length(which(matchBal$stdDiffMeans>0.25))
    return(numViolations)
}

batchMatchAndVerify <- function(factor) {
    matchouts <- batchMatch(factor)
    balances <- lapply(matchouts, checkBalance)
    return(balances)
}

computePairOutcome <- function(treatedName, matches, matchdata, binary=TRUE) {
    untreatedName <- matches[treatedName,'1']
    treatedOutcome <- matchdata[treatedName,'NumTickets']
    untreatedOutcome <- matchdata[untreatedName,'NumTickets']
    outcome <- treatedOutcome - untreatedOutcome
    if (binary) {
        if (outcome < 0) {
            outcome <- -1
        }
        if (outcome > 0) {
            outcome <- 1
        }
    }
    return(outcome)
}

computeOutcomes <- function(matchout) {
    if (is.null(matchout)) {
        return(NULL)
    }
    matches <- matchout$match.matrix
#    print(nrow(matches))
    matchdata <- match.data(matchout)
    treated <- getTreatedUnits(matchout)
    outcomes <- sapply(rownames(treated), computePairOutcome, matches, 
            matchdata, FALSE)
    return(outcomes)
}

batchMatchAndOutcomes <- function(factor) {
    matchouts <- batchMatch(factor)
    outcomes <- lapply(matchouts, computeOutcomes)
    return(outcomes)
}

getTreatedUnits <- function(matchout) {
    matches <- matchout$match.matrix
    matchdata <- match.data(matchout)
    matched <- which(as.numeric(matches[,"1"])>0)
    matches <- matches[matched,]
    return(matchdata[names(matches),])
}

getUntreatedUnits <- function(matchout) {
    matches <- matchout$match.matrix
    matchdata <- match.data(matchout)
    matched <- unique(as.numeric(matches[,"1"]))
    matched <- matched[which(matched>0)]
    return(matchdata[as.character(matched),])
}

testHypothesis <- function(outcomes) {
    if (is.null(outcomes)) {
        return(NULL)
    }
    signresult <- signtest(outcomes, conf.level=0.95)
    return(signresult)
}

runQED <- function(factor, untreatUpper, treatLower) {
    print(factor)
    matchout <- runMatch(factor, untreatUpper, treatLower)
#    print(summary(matchout))
    outcomes <- runOutcome(matchout)
#    print(table(outcomes))
    signresult <- testHypothesis(outcomes)
    return(signresult$p.value)
}

batchQED <- function(factor) {
    bins <- sort(unique(binned[,factor]))
    lowest <- bins[1]
    upper <- bins[2:length(bins)]
#    matchouts <- lapply(upper, function(u) runMatch(factor, lowest, u))
    matchouts <- lapply(1:(length(bins)-1), function(i, b) runMatch(factor, bins[i], bins[(i+1)]), bins)
    outcomes <- lapply(matchouts, computeOutcomes)
    signresults <- lapply(outcomes, testHypothesis)
    pvalues <- sapply(signresults, function(s) s$p.value)
    return(pvalues)
}
