datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
lastmonth <- metrics[which(metrics$Month=="2014-12"),]

print("% of networks with less than 20 devices")
print(ecdf(lastmonth$NumDevices)(19.9))

print("% of networks with more than 100 devices")
print(1-ecdf(lastmonth$NumDevices)(99.9))

print("% of networks with more than 1 vendor")
print(1-ecdf(lastmonth$NumVendors)(1.9))

print("maximum # of vendors")
print(max(lastmonth$NumVendors))

print("% of networks with more than 1 model")
print(1-ecdf(lastmonth$NumModels)(1.9))

print("maximum # of model")
print(max(lastmonth$NumModels))

print("Pearson correlation between NumDevices and NumModels")
print(cor(lastmonth$NumDevices,lastmonth$NumModels,method="pearson"))

print("Pearson correlation between NumDevices and NumVendors")
print(cor(lastmonth$NumDevices,lastmonth$NumVendors,method="pearson"))

print("Pearson correlation between NumVendors and NumModels")
print(cor(lastmonth$NumVendors,lastmonth$NumModels,method="pearson"))

print("Pearson correlation between NumDevices and NumRoles")
print(cor(lastmonth$NumDevices,lastmonth$NumRoles,method="pearson"))

print("% of networks with at least one type of middlebox")
mboxroles <- lastmonth$HasRoleApplicationSwitch+lastmonth$HasRoleLoadBalancer+lastmonth$HasRoleFirewall
print(length(which(mboxroles>0))/length(lastmonth$StampName))

print("% of networks with 2 or more roles")
print(1-ecdf(lastmonth$NumRoles)(1.9))


