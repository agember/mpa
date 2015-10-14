datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_all_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
print("RawFirstPlaceChangeAction")
print(sort(table(metrics$RawFirstPlaceChangeAction)))
print("RawSecondPlaceChangeAction")
print(sort(table(metrics$RawSecondPlaceChangeAction)))
