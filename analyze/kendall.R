library(energy)
library(FSelector)

corColsPearson <- function(bcol, ubcol) {
    keeps <- which(!is.na(bcol))
    avgs <- tapply(ubcol[keeps], bcol[keeps], mean)
    return(cor(avgs, as.numeric(names(avgs)), method="pearson"))
}

corColsDistance <- function(bcol, ubcol) {
    keeps <- which(!is.na(bcol))
    avgs <- tapply(ubcol[keeps], bcol[keeps], mean)
    return(dcor(avgs, as.numeric(names(avgs))))
}

corColsUnbinned <- function(bcol, ubcol) {
    keeps <- which(!is.na(bcol))
    return(cor(ubcol[keeps], bcol[keeps], method="kendall"))
}

corCols <- function(bcol, ubcol) {
    keeps <- which(!is.na(bcol))
    avgs <- tapply(ubcol[keeps], bcol[keeps], mean)
    return(cor(avgs, as.numeric(names(avgs)), method="kendall"))
}

corColsKendall <- corCols

corMetricPair <- function(bname, ubname, bsrc, ubsrc) {
    return(corCols(bsrc[,bname],ubsrc[,ubname]))
}

corMetricPairKendall <- corMetricPair

corMetricPairPearson <- function(bname, ubname, bsrc, ubsrc) {
    return(corColsPearson(bsrc[,bname],ubsrc[,ubname]))
}

corMetricPairUnavg <- function(bname, ubname, bsrc, ubsrc) {
    return(corColsUnbinned(bsrc[,bname],ubsrc[,ubname]))
}

corMetricPairDistance <- function(bname, ubname, bsrc, ubsrc) {
    return(corColsDistance(bsrc[,bname],ubsrc[,ubname]))
}

igCols <- function(nameA, nameB, bsrc) {
    keeps <- which(!is.na(bcol))
    avgs <- tapply(ubcol[keeps], bcol[keeps], mean)
    return(cor(avgs, as.numeric(names(avgs)), method="pearson"))
}

igMetricPair <- function(nameA, nameB, bsrc) {
    keeps <- which(!is.na(bsrc[,nameA]) & !is.na(bsrc[,nameB]))
    formula <- as.formula(paste(nameA,nameB,sep="~"))
    return(information.gain(formula, bsrc[keeps,])[1,1])
}

corMetricPairInfoGain <- function(nameA, nameB, bsrc, useless) {
    return(igMetricPair(nameA, nameB, bsrc))
}
