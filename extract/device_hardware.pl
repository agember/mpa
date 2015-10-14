#!/usr/bin/perl

use strict;

# PURPOSE: Summarizes information about device hardware (e.g., vendor, model, 
# role).

# PREREQUISITES: None

# OUTPUT:
# hardware.txt, contains the following for each stamp:
# - stamp name
# - number of devices
# - number of roles
# - number of models
# - number of vendors
# - entropy
# - normalized entropy
# - property
# - number properties
# - has device with unspecified property
#
# vendors.txt, contains the following for each stamp:
# - stamp name
# - list of vendors and count of devices for each vendor
#
# roles.txt, contains the following for each stamp:
# - stamp name
# - list of roles and count of devices for each role
#
# models.txt, contains the following for each stamp:
# - stamp name
# - list of models
#
# properties.txt, contains the following for each stamp:
# - stamp name
# - list of properties (i.e., organizational units) that use the stamp
#
# devices.txt, contains the following for each device:
# - device name
# - stamp name
# - device role
# - device vendor
# - device model

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $cfgsdir = "$datadir/uncompcfgs/";
my $hardwarefile = "$datadir/hardware.txt";
my $vendorsfile = "$datadir/vendors.txt";
my $rolesfile = "$datadir/roles.txt";
my $modelsfile = "$datadir/models.txt";
my $propertiesfile = "$datadir/properties.txt";
my $devicesfile = "$datadir/devices.txt";

open(fh, ">$hardwarefile") or die("Could not open $hardwarefile");
open(fhVendors, ">$vendorsfile") or die("Could not open $vendorsfile");
open(fhRoles, ">$rolesfile") or die("Could not open $rolesfile");
open(fhModels, ">$modelsfile") or die("Could not open $modelsfile");
open(fhProperties, ">$propertiesfile") or die("Could not open $propertiesfile");
open(fhDevs, ">$devicesfile") or die("Could not open $devicesfile");

# Output file headers
print fh "StampName NumDevices NumRoles NumModels NumVendors"
        ." Entropy NormalizedEntropy"
        ." StampProperty NumProperties HasUnspecifiedProperty\n";

# Get network names
opendir(D, $cfgsdir) or die("Could not open $cfgsdir");
my @stamps = readdir(D);
closedir(D);

# Process each network
foreach my $stampname (sort(@stamps)) {
    if (($stampname =~ /^\.$/) or ($stampname =~ /^\.\.$/)) {
    	next;
    }
    print "Processing $stampname\n";

    # Extract property from network name
    my $stampproperty = "unspecified";
    if ($stampname =~ m/^[^-]+-[^-]+-([a-zA-Z]+)(-[^-]+)+$/) {
        $stampproperty = $1;
    }

    print fh "$stampname ";
    print fhVendors "$stampname: ";
    print fhRoles "$stampname: ";
    print fhModels "$stampname: ";
    print fhProperties "$stampname: ";

    my %roleseen;
    my %modelseen;
    my %vendorseen;
    my %propertyseen;
    my %modelroleseen;
    my $numdevs = 0;

    # Get device names
    opendir(D, "$cfgsdir/$stampname") or 
        die("Could not open $cfgsdir/$stampname");
    my @devs = readdir(D);
    closedir(D);

    # Process each device
    foreach my $devname (sort(@devs)) {
        if (($devname =~ /^\.$/) or ($devname =~ /^\.\.$/)) {
            next;
        }

        $numdevs++;

        # Parse device inventory information
        open ft, "$cfgsdir/$stampname/$devname/metadata.txt" or 
            (print("Could not open $cfgsdir/$stampname/$devname/metadata.txt") 
             and next);
#            die("Could not open $cfgsdir/$stampname/$devname/metadata.txt");
        my $role;
        my $model;
        my $vendor;
        while (<ft>) {
            chomp;
            if (m/DeviceType:\s(.*)$/) {
                $role = $1;
                $role =~ s/\s+//g;
                if ($role eq "") {
                    $role = "Unknown";
                }
                $roleseen{$role}++;
            } elsif (m/Vendor:\s(.*)$/) {
                $vendor = $1;
                if ($vendor eq "") {
                    $vendor = "Unknown";
                }
                $vendorseen{$vendor}++;
            } elsif (m/Model:\s(.*)$/) {
                $model = $1;
                $model =~ s/\s/_/g;
                if ($model eq "") {
                    $model = "Unknown";
                }
                $modelseen{$model}++;

                if (!defined($modelroleseen{$role}{$model})) {
                    $modelroleseen{$role}{$model} = 0;
                }
                $modelroleseen{$role}{$model}++;
            }
        }
        close(ft);

        # Extract property from device name
        my $devproperty = "unspecified";
        if ($devname =~ m/^[^-]+-[^-]+-([a-zA-Z]+)(-[^-]+)+$/) {
            $devproperty = $1;
        }
        $propertyseen{$devproperty}++;
        
        # Output device details
        print fhDevs "$devname $stampname $role $vendor $model $devproperty\n";
    }

    # Output device, role, model, and vendor counts
    my $numRoles = scalar(keys %roleseen);
    my $numModels = scalar(keys %modelseen);
    my $numVendors = scalar(keys %vendorseen);
    print fh "$numdevs $numRoles $numModels $numVendors";

    # Output heterogeneity
    if ($numdevs > 0) {
        my $entropy = 0; 
        my $p;

        foreach my $role (keys %modelroleseen) {
            foreach my $model (keys %{$modelroleseen{$role}}) {
                $p = $modelroleseen{$role}{$model}/$numdevs;
                !(($p == 0) or ($p > 1)) or die("$role-$model entroy error");
                #my $f = (log $p)/(log $numdevs);
                my $f = (log $p)/(log 2);
                my $incr = -1 * $p * $f;
                $entropy += $incr;
            }
        }
        my $normEntropy = $entropy/((log $numdevs)/(log 2));
        
        print fh " $entropy $normEntropy";
    } else {
    	print fh " 0 1";
    }

    # Output property and property count
    my $numProperties = scalar(keys %propertyseen);
    my $hasunspec = 0;
    if (exists($propertyseen{"unspecified"})) {
        $hasunspec = 1;
    }
    print fh " $stampproperty $numProperties $hasunspec";

#    # Output number of models for each role
#    if ($numdevs > 0) {
#        foreach my $role (keys %modelroleseen) {
#            $numModels = scalar(keys %{$modelroleseen{$role}});
#            print fh " $role=$numModels";
#        }
#    }
    print fh "\n";

    # Output vendor list for stamp
    my $vendorlist = "";
    for my $vendor (sort(keys %vendorseen)) {
        $vendorlist .= " $vendor=$vendorseen{$vendor}";
    }
    print fhVendors "$vendorlist\n";

    # Output role list for stamp
    my $rolelist = "";
    for my $role (sort(keys %roleseen)) {
        $rolelist .= " $role=$roleseen{$role}";
    }
    print fhRoles "$rolelist\n";

    # Output model list for stamp
    my $modellist = "";
    for my $model (sort(keys %modelseen)) {
        $modellist .= " $model=$modelseen{$model}";
    }
    print fhModels "$modellist\n";

    # Output propety list for stamp
    my $propertylist = "";
    for my $property (sort(keys %propertyseen)) {
        $propertylist .= " $property=$propertyseen{$property}";
    }
    print fhProperties "$propertylist\n";
}

close(fh);
close(fhVendors);
close(fhRoles);
close(fhModels);
close(fhProperties);
close(fhDevs);
