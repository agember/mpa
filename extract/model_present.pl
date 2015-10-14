#!/usr/bin/perl

use strict;

# PREREQUSITES: MGMTPLANE_CODE/extract/device_hardware.pl has been run.

# OUTPUT:
# model_present.txt, contains a line for each stamp and a column for every 
# model that might be in the network; a cell has a value of one if the 
# corresponding model exists in the corresponding stamp

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $modelsfile = "$datadir/models.txt";
my $outputfile = "$datadir/model_present.txt";

my %models;

open(fh, "$modelsfile") or die ("Could not open $modelsfile");
while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $modellist = $s[1];
    $modellist =~ s/(^\s+)|(\s+$)//g;
    $modellist =~ s/\s\s+/ /g;
    @s = split/ /, $modellist;
    foreach my $model (@s) { 
        $models{$model} += 1; 
    }
}
close(fh);

open(fh, "$modelsfile") or die ("Could not open $modelsfile");
open(fhOut, ">$outputfile") or die ("Could not open $outputfile");

print fhOut "StampName:";
foreach my $model (keys %models) {
    print fhOut " $model";
}
print fhOut "\n";

while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $stamp = $s[0];
    my $modellist = $s[1];
    print fhOut "$stamp:";
    foreach my $model (keys %models) {
        if ($modellist =~ m/$model/) {
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
