#!/usr/bin/perl

use strict;

# PREREQUSITES: MGMTPLANE_CODE/extract/stamp_architecture.pl has been run.

# OUTPUT:
# arch_present.txt, contains a line for each stamp and a column for every
# architecture that the network might follow; a cell has a value of one if the 
# corresponding architecture is used for the corresponding stamp

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $archsfile = "$datadir/archs.txt";
my $outputfile = "$datadir/arch_present.txt";

my %archs;

open(fh, "$archsfile") or die ("Could not open $archsfile");
while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $archlist = $s[1];
    $archlist =~ s/(^\s+)|(\s+$)//g;
    $archlist =~ s/\s\s+/ /g;
    @s = split/\+/, $archlist;
    foreach my $arch (@s) { 
        $archs{$arch} += 1; 
        if ($arch =~ m/.\d./) {
            $arch =~ m/^([a-zA-Z]+)(\d\d)?/;
            my $basearch = "$1$2";
            $archs{$basearch} += 1;
        }    
    }
}
close(fh);

open(fh, "$archsfile") or die ("Could not open $archsfile");
open(fhOut, ">$outputfile") or die ("Could not open $outputfile");

print fhOut "StampName:";
foreach my $arch (keys %archs) {
    print fhOut " $arch";
}
print fhOut "\n";

while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $stamp = $s[0];
    my $archlist = $s[1];
    print fhOut "$stamp:";
    foreach my $arch (keys %archs) {
        if ($archlist =~ m/$arch/) {
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
