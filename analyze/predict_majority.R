months <- unique(binned$Month)
monthlyCounts <- data.frame(sapply(unique(binned$Month), function (x) table(binned$NumTickets[which(binned$Month==x)])))
colnames(monthlyCounts) <- months

majorityForMonth <- function(month, counts) {
    windowCounts <- counts[,month]
    majorityIndex <- which(windowCounts==max(windowCounts))
    percent <- windowCounts[majorityIndex] / sum(windowCounts)
    return(percent)
}

accuracies <- sapply(months[2:length(months)], majorityForMonth, monthlyCounts)
names(accuracies) <- months[2:length(months)]
overallAccuracy <- majorityForMonth(1, data.frame(rowSums(monthlyCounts)))

#majorityForMonth <- function(index, window, counts) {
#    filteredCounts <- counts[(index-window):(index-1)]
#    windowCounts <- rowSums(filteredCounts)
#    majorityIndex <- which(windowCounts==max(windowCounts))
#    return(windowCounts[majorityIndex] / sum(windowCounts))
#}
#
#majorityForWindow <- function(window, counts) {
#    indices <- (window+1):length(months)
#    majorities <- sapply(indices, majorityForMonth, window, counts)
#    majorities <- c(rep(NA,window), majorities)
#    names(majorities) <- months
#    return(majorities)
#}
#
#windows <- c(1,3,6,9)
#accuracies <- data.frame(sapply(windows, majorityForWindow, monthlyCounts))
#colnames(accuracies) <- paste('Win',windows, sep='')
