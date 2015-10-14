datafile <- 'all_metrics_filtered.csv'
source('analyze/read_metrics.R')
numbins <- 5
nazero <- FALSE
source('analyze/width_bins.R')
source('qed/qed_matchit.R')
batchMatchAndVerify('NumDevices')
outcomes <- batchMatchAndOutcomes('NumDevices')
mean(outcomes[[1]])
