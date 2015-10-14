datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")

fullpath <- paste(datapath,"good_metrics.csv",sep="/")
goodmetrics <- read.table(fullpath, sep=",", header=TRUE)


getPrettyByName <- function(name) {
    rows <- which(goodmetrics$Name==name)
    if (length(rows) >= 1) {
        return(levels(goodmetrics$PrettyName)[goodmetrics[rows[1],'PrettyName']])
    } else {
        return("")
    }
}

getPrettyByIndex <- function(index) {
    rows <- which(goodmetrics$Index==index)
    if (length(rows) >= 1) {
        return(levels(goodmetrics$PrettyName)[goodmetrics[rows[1],'PrettyName']])
    } else {
        return("")
    }
}
