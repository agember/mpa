datapath <- Sys.getenv("MGMTPLANE_DATA")
codepath <- Sys.getenv("MGMTPLANE_CODE")
datafile <- "all_metrics_1m_nomissing_filtered.csv"

source(paste(codepath,'analyze/read_metrics.R',sep="/"))
lastmonth <- metrics[which(metrics$Month=="2014-12"),]

print("Pearson correlation between RawNumChanges and NumDevices")
print(cor(metrics$RawNumChanges,metrics$NumDevices,method="pearson"))

print("Pearson correlation between RawNumChanges and FractionAutoChanges")
print(cor(metrics$RawNumChanges,metrics$FractionAutoChanges,method="pearson"))

print("Pearson correlation between NumDevices and FractionAutoChanges")
print(cor(metrics$NumDevices,metrics$FractionAutoChanges,method="pearson"))

#print("Pearson correlation between NumDevices and NumVendors")
#print(cor(lastmonth$NumDevices,lastmonth$NumVendors,method="pearson"))
#
#print("Pearson correlation between NumVendors and NumModels")
#print(cor(lastmonth$NumVendors,lastmonth$NumModels,method="pearson"))
#
#print("Pearson correlation between NumDevices and NumRoles")
#print(cor(lastmonth$NumDevices,lastmonth$NumRoles,method="pearson"))
#
#print("% of networks with at least one type of middlebox")
#mboxroles <- lastmonth$HasRoleApplicationSwitch+lastmonth$HasRoleLoadBalancer+lastmonth$HasRoleFirewall
#print(length(which(mboxroles>0))/length(lastmonth$StampName))
#
#print("% of networks with 2 or more roles")
#print(1-ecdf(lastmonth$NumRoles)(1.9))


