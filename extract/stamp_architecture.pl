#!/usr/bin/perl

use strict;

# Creates file architecture.txt, which contains the following for each stamp 
# (one stamp per line):
# - stamp name
# - architecture

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $devicesxml = "$datadir/device_details.xml";
my $archsfile = "$datadir/architecture.txt";

my %stampstoarch;

open(fh, "$devicesxml") or die("Could not open $devicesxml");
while (<fh>) {
    chomp($_);
    $_ =~ s/\s+//g;
    if ($_ =~ /^.*StampStampName=\"(.*)\"StampArch=\"(.*)\"/) {
        my $stampname = $1;
        my $archname = $2;
        $archname =~ s/,/+/g;
	    $stampstoarch{$stampname} = $archname;
    }
}
close(fh);

open(fh, ">$archsfile") or die("Could not open $archsfile");
print fh "StampName Architecture\n";
foreach my $stamp (sort(keys %stampstoarch)) {
    print fh "$stamp $stampstoarch{$stamp}\n";
}
close(fh);
