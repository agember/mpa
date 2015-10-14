# Load data
datapath <- Sys.getenv("MGMTPLANE_DATA")
stopifnot(datapath != "")
fullpath <- paste(datapath,"basic_metrics.csv",sep="/")
simple <- read.table(fullpath, sep=",", header=TRUE)
cat(paste("Loaded data from '",fullpath,"' into 'simple'\n", sep=""))
