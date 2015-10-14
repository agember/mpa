if (!exists("numbins")) {
    numbins <- 10
}
if (!exists("classnums")) {
    classnums <- FALSE
}
if (!exists("nazero")) {
    nazero <- FALSE
}

addToBinned <- function(colname, isFactor=FALSE) {
    if (!isFactor) {
        metrics[which(metrics[,colname] < 0),colname] <<- NA
        if(nazero) {
            metrics[which(is.na(metrics[,colname])),colname] <<- 0
        }
    }
    binned[,colname] <<- metrics[,colname]
}

levelToNumeric <- function(level, binbounds) {
    if (!is.na(level) && level <= 0)
        return(level)
    return(binbounds[level])
}

binValue <- function(n, binbounds) {
    return((binbounds[n] + binbounds[n+1])/2)
}

# Compute binned values for metric
# colname: name of metric
# numbins: number of fixed-width bins
# classnums: if true, output should contain bin number (e.g., 1,2,3,...)
#       instead of mean bin value
# nazero: if true, NA values are converted to 0
convertToBinned <- function(colname, numbins, classnums=FALSE, nazero=FALSE) {
    print(colname)

    # Convert all -1 values to NA
    metrics[which(metrics[,colname] < 0),colname] <<- NA

    # Convert NAs to 0, if requested
    if(nazero) {
        metrics[which(is.na(metrics[,colname])),colname] <<- 0
    }

    # Determine the 5th and 95th percentile values and round outliers
    filtered <- metrics[,colname] 
    range <- quantile(metrics[,colname],c(0.05,0.95),na.rm=TRUE)
    filtered[which(filtered < range[1])] <- range[1]
    filtered[which(filtered > range[2])] <- range[2]

    # Determine the bound for each bin
    binbounds <- seq(range[1],range[2],(range[2]-range[1])/numbins)
#    binbounds[1] <- min(metrics[,colname],na.rm=TRUE)
#    binbounds[length(binbounds)] <- max(metrics[,colname],na.rm=TRUE)
    binbounds <- unique(binbounds)
    print(binbounds)

    # Compute the bin number for each data point
    binnums <- cut(filtered,binbounds,include.lowest=TRUE, labels=FALSE, right=FALSE)
#    print(unique(binnums))

    # Convert bin numbers to mean value for each bin, or keep bin numbers
    if (!classnums) {
        binbounds[1] <- range[1]
        binbounds[length(binbounds)] <- range[2]
        binvals <- sapply(seq(1,length(binbounds)-1), binValue, binbounds)
#       print(binvals)
        binned[,colname] <<- sapply(binnums, levelToNumeric, binvals)
    }
    else {
        binned[,colname] <<- binnums
    }
}

binned <- metrics[,idnames]
sapply(discretenames, addToBinned, TRUE)

specialnames <- c('NumRoles', 'NumVendors', 'NumL2Protocols', 'NumL3Protocols')
sapply(specialnames, addToBinned)

# Cut all zero values
metrics$NumNsrp <- NULL
metrics$NumIsolatedNodes <- NULL

othernames <- colnames(metrics)
#othernames <- othernames[!sapply(othernames, is.element, healthnames)]
othernames <- othernames[!sapply(othernames, is.element, binarynames)]
othernames <- othernames[!sapply(othernames, is.element, discretenames)]
othernames <- othernames[!sapply(othernames, is.element, idnames)]
othernames <- othernames[!sapply(othernames, is.element, rawrolenames)]
othernames <- othernames[!sapply(othernames, is.element, numrolenames)]
othernames <- othernames[!sapply(othernames, is.element, specialnames)]
sapply(othernames, convertToBinned, numbins, classnums, nazero)

#sapply(binarynames, addToBinned)

binned <- data.frame(binned)

cat(paste("Binned health and mgmt metrics using ",numbins," bins (classnums=",
        classnums,", nazero=",nazero,") and stored in 'binned'\n", sep=""))
