#!/usr/bin/perl

use strict;

# Creates file property_present.txt, which contains a line for each stamp and a column for every property that might be
# in the network. A column has a value of one for a given stamp if the property exists in this stamp.

# Get directories and files
my $datadir;
my $propertiesfile = "properties.txt";
my $outputfile = "property_present.txt";
my $countfile = "property_count.txt";
if (exists $ENV{'MGMTPLANE_DATA'}) {
    $datadir = "$ENV{'MGMTPLANE_DATA'}";
    $propertiesfile = "$datadir/$propertiesfile";
    $outputfile = "$datadir/$outputfile";
    $countfile = "$datadir/$countfile";
}
else {
    print "Set the MGMTPLANE_DATA environment variable to the path for reading/writing data\n";
    exit 1;
}

my %properties;

open(fh, "$propertiesfile") or die ("ERROR: Could not open $propertiesfile");
while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $propertylist = $s[1];
    $propertylist =~ s/(^\s+)|(\s+$)//g;
    $propertylist =~ s/\s\s+/ /g;
    @s = split/ /, $propertylist;
    foreach my $propertycount (@s) { 
        my @r = split/=/, $propertycount;
        $properties{$r[0]} += 1; 
    }
}
close(fh);

open(fh, "$propertiesfile") or die ("ERROR: Could not open $propertiesfile");
open(fhOut, ">$outputfile") or die ("ERROR: Could not open $outputfile");
open(fhCnt, ">$countfile") or die ("ERROR: Could not open $countfile");

print fhOut "StampName:";
print fhCnt "StampName:";
foreach my $property (sort(keys %properties)) {
    print fhOut " $property";
    print fhCnt " $property";
}
print fhOut "\n";
print fhCnt "\n";

while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $stamp = $s[0];
    my $propertylist = " ".$s[1];
    print fhOut "$stamp:";
    print fhCnt "$stamp:";
    foreach my $property (sort(keys %properties)) {
        if ($propertylist =~ m/ $property=(\d+)/) {
            print fhOut " 1";
            print fhCnt " $1";
        }
        else {
            print fhOut " 0";
            print fhCnt " 0";
        }
    }
    print fhOut "\n";
    print fhCnt "\n";
}
close(fh);
close(fhOut);
close(fhCnt);
