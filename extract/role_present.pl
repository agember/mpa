#!/usr/bin/perl

use strict;

# PREREQUSITES: MGMTPLANE_CODE/extract/device_hardware.pl has been run.

# OUTPUT:
# role_present.txt, contains a line for each stamp and a column for every role
# that might be in the network; a cell has a value of one if the corresponding
# role exists in the corresponding stamp
#
# role_count.txt, contains a line for each stamp and a column for every role
# that might be in the network; a cell's value equals the number of devices
# that have the corresponding role in the corresponding cell

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $rolesfile = "$datadir/roles.txt";
my $outputfile = "$datadir/role_present.txt";
my $countfile = "$datadir/role_count.txt";

my %roles;

open(fh, "$rolesfile") or die ("Could not open $rolesfile");
while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $rolelist = $s[1];
    $rolelist =~ s/(^\s+)|(\s+$)//g;
    $rolelist =~ s/\s\s+/ /g;
    @s = split/ /, $rolelist;
    foreach my $rolecount (@s) { 
        my @r = split/=/, $rolecount;
        $roles{$r[0]} += 1; 
    }
}
close(fh);

open(fh, "$rolesfile") or die ("Could not open $rolesfile");
open(fhOut, ">$outputfile") or die ("Could not open $outputfile");
open(fhCnt, ">$countfile") or die ("Could not open $countfile");

print fhOut "StampName:";
print fhCnt "StampName:";
foreach my $role (sort(keys %roles)) {
    print fhOut " $role";
    print fhCnt " $role";
}
print fhOut "\n";
print fhCnt "\n";

while (<fh>) {
    chomp;
    my @s = split/:/, $_;
    my $stamp = $s[0];
    my $rolelist = " ".$s[1];
    print fhOut "$stamp:";
    print fhCnt "$stamp:";
    foreach my $role (sort(keys %roles)) {
        if ($rolelist =~ m/ $role=(\d+)/) {
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
