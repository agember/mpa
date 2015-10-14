mutualinfo <- function(X, Y) {
    numpoints <- nrow(binned)
    crosstab <- table(X,Y)
    Xtab <- table(X)
    Ytab <- table(Y)
    XYprob <- crosstab / numpoints
    Xprob <- Xtab / numpoints
    Yprob <- Ytab / numpoints

#    print(Xprob)
#    print(Yprob)
#    print(XYprob)

    HX <- sapply(names(Xprob), function(i) Xprob[i] * log(Xprob[i]))
    HX <- -sum(HX)

    HXY <- sapply(names(Yprob), function(i) 
            sapply(names(Xprob), function(j, i)
                XYprob[j,i] * log(Yprob[i] / XYprob[j,i]), i))
    HXY <- sum(HXY, na.rm=TRUE)
    mi <- HX - HXY

    H <- sapply(names(Yprob), function(i) 
            sapply(names(Xprob), function(j, i)
                XYprob[j,i] * log(XYprob[j,i] / (Xprob[j] * Yprob[i])), i))
    mi <- sum(H, na.rm=TRUE)
    return(mi)
}

mutualinfoMean <- function(practice, health) {
    periods <- unique(binned$Month)
    mis <- sapply(periods, function(p) mutualinfo(
            binned[which(binned$Month==p),practice],
            binned[which(binned$Month==p),health]))
    return(mean(mis))
}

mutualinfoAggregate <- function(practice, health) {
    mi <- mutualinfo(binned[,practice], binned[,health])
    return(mi)
}
