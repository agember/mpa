#!/usr/bin/perl

use strict;

# PREREQUSITES: MGMTPLANE_CODE/extract/device_hardware.pl has been run.

# OUTPUT:
# vendor_present.txt, contains a line for each stamp and a column for every 
# vendor that might be in the network; a cell has a value of one if the 
# corresponding vendor exists in the corresponding stamp

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $vendorsfile = "$datadir/vendors.txt";
my $outputfile = "$datadir/vendor_present.txt";

my %vendors;

open(fh, "$vendorsfile") or die ("Could not open $vendorsfile");
while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $vendorlist = $s[1];
    $vendorlist =~ s/(^\s+)|(\s+$)//g;
    $vendorlist =~ s/\s\s+/ /g;
    @s = split/ /, $vendorlist;
    foreach my $vendorcount (@s) { 
        my @v = split/=/, $vendorcount;
        $vendors{$v[0]} += 1; 
    }
}
close(fh);

open(fh, "$vendorsfile") or die ("Could not open $vendorsfile");
open(fhOut, ">$outputfile") or die ("Could not open $outputfile");

print fhOut "StampName:";
foreach my $vendor (sort(keys %vendors)) {
    print fhOut " $vendor";
}
print fhOut "\n";

while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $stamp = $s[0];
    my $vendorlist = $s[1];
    print fhOut "$stamp:";
    foreach my $vendor (sort(keys %vendors)) {
        if ($vendorlist =~ m/$vendor=(\d+)/) {
            print fhOut " 1";
        }
        else {
            print fhOut " 0";
        }
    }
    print fhOut "\n";
}
close(fh);
close(fhOut);
