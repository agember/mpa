#!/usr/bin/perl

use strict;

# PURPOSE: Determines the number of types of stanzas that always changed
# automatically or manually for each stamp.

# PREREQUISITES: MGMTPLANE_CODE/extract/change_stanzas.pl has been run.

# OUTPUT:
# stanza_automation.txt, contains the following for each stamp:
# - stamp name
# - number of types of stanzas changed
# - number of types of stanzas that are always changed automatically
# - number of types of stanzas that are always changed manually

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $naturefile = "$datadir/stanza_nature.txt";
my $automationfile = "$datadir/stanza_automation.txt";

open nfh, "$naturefile" or die("Could not open $naturefile");
my %typesByStamp;
<nfh>; # Skip first line
while(<nfh>) {
    chomp $_;
    my @cols = split(" ", $_);

    if (scalar(@cols) < 5) {
        die("Invalid line of data: $_");
    }

    my $stamp = $cols[0];
    my $type = $cols[1];
    my $rawAuto = $cols[2];
    my $rawUnkn = $cols[3];
    my $fracRawAuto = $cols[4];

    $typesByStamp{$stamp}{$type} = {"rawauto" => $rawAuto, 
        "rawunkn" => $rawUnkn, "fracrawauto" => $fracRawAuto};
}
close nfh;

open afh, ">$automationfile" or die("Could not open $automationfile");
print afh "StampName RawNumTypes RawNumFullAutoTypes RawNumFullUnknTypes\n";

# Process each stamp
for my $stamp (sort(keys %typesByStamp)) {
    my $typeCnt = 0;
    my $fullAutoTypeCnt = 0;
    my $fullUnknTypeCnt = 0;
    for my $type (sort(keys $typesByStamp{$stamp})) {
        $typeCnt++;
        if ($typesByStamp{$stamp}{$type}->{fracrawauto} == 1) {
            $fullAutoTypeCnt++;
        } elsif ($typesByStamp{$stamp}{$type}->{fracrawauto} == 0) {
            $fullUnknTypeCnt++;
        }
    }
    print afh "$stamp $typeCnt $fullAutoTypeCnt $fullUnknTypeCnt\n";
}
close afh;
