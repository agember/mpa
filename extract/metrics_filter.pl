#!/usr/bin/perl

# PREREQUSITES: MGMTPLANE_CODE/extract/metrics_combine_all.pl and
# MGMTPLANE_CODE/extract/metrics_range.pl have been run.

use strict;
use Date::Calc qw(Day_of_Year Mktime Days_in_Month Localtime);

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $rangefile = "$datadir/metrics_range.csv";

($#ARGV >= 0) or die("Must specify metrics file to filter");
my $metricsfile = "$datadir/$ARGV[0]";

my $outputfile = $metricsfile;
$outputfile =~ s/\.csv$/_filtered\.csv/;

# Get the date range arguments
my $mindate = "";
my $maxdate = "";
if ($#ARGV >= 2) {
    $mindate = $ARGV[1];
    $maxdate = $ARGV[2];
}
my $mintime = -1;
my $maxtime = -1;
if ($mindate eq "" or $maxdate eq "") {
    die("Must specify date range for filtering");
}
else {
    if ($mindate =~ m/^(\d{4})-(\d{2})-(\d{2})$/) {
        $mintime = Mktime($1, $2, $3, 0, 0, 0);
    } else {
        die("Invalid starting date; must specify starting date as YYYY-MM-DD");
    }
    if ($maxdate =~ m/^(\d{4})-(\d{2})-(\d{2})$/) {
        $maxtime = Mktime($1, $2, $3, 23, 59, 59);
    } else {
        die("Invalid ending date; must specify ending date as YYYY-MM-DD");
    }
    if ($mintime >=0 and $maxtime >= 0 and $maxtime <= $mintime) {
        die("Ending date must be after starting date");
    }
    print "Limited to date range: $mindate to $maxdate\n";
}

# Determine whether to only include stamps for which we have data for the
# entire date range
my $onlyall = "no";
if ($#ARGV >= 3) {
    $onlyall = $ARGV[3];
}
if ($onlyall eq "yes") {
    print "Only including stamps with full range of data\n";
    $outputfile =~ s/\.csv$/_fullrange\.csv/;
}

open(fh, "$rangefile") or die("Could not open $rangefile");
my $earliesthdr = <fh>;
my %earliest;
my %earlieststr;
my %latest;
my %lateststr;
while (<fh>) {
    chomp $_;
    my @cols = split /,/,$_;
    my $stamp = $cols[0];
    my $firstboth = $cols[3];
    my $firsteither = $cols[4];
    my $lastboth = $cols[7];
    my $lasteither = $cols[8];

    if ($firstboth =~ m/(20\d\d)-(\d\d)/) {
        $earliest{$stamp} = Mktime($1, $2, 1, 0, 0, 0);
        $earlieststr{$stamp} = "$1-$2-01";
        if ($onlyall eq "yes") {
            if ($lastboth =~ m/(20\d\d)-(\d\d)/) {
                $latest{$stamp} = Mktime($1, $2, Days_in_Month($1, $2), 23, 59, 59);
                $lateststr{$stamp} = "$1-$2-".Days_in_Month($1,$2);
            }
        } else {
            if ($lasteither =~ m/(20\d\d)-(\d\d)/) {
                $latest{$stamp} = Mktime($1, $2, Days_in_Month($1, $2), 23, 59, 59);
                $lateststr{$stamp} = "$1-$2-".Days_in_Month($1,$2);
            }
        }
    }
}
close(fh);

my %stamps;
open(fh, "$metricsfile") or die("Could not open $metricsfile");
open(ofh, ">$outputfile") or die("Could not open $outputfile");
my $metricshdr = <fh>;
print ofh $metricshdr;
while (<fh>) {
    chomp $_;
    my @cols = split /,/,$_;
    my $stamp = $cols[0];
    my $period = $cols[1];
    my $numdevices = $cols[2];

    if ($numdevices <= 2) {
        next;
    }

    if ((!exists $earliest{$stamp}) or (!exists $latest{$stamp})) {
        next;
    }

    if ($onlyall eq "yes") {
        if ($earliest{$stamp} > $mintime or $latest{$stamp} < $maxtime) {
            next;
        }
    }

    if ($period =~ m/(20\d\d)-(\d\d)/) {
        my $time = Mktime($1, $2, 1, 0, 0, 0);
        if ($mintime >= 0 and $time < $mintime) {
            next;
        }
        if ($maxtime >= 0 and $time > $maxtime) {
            next;
        }
        if ($time < $earliest{$stamp} or $time > $latest{$stamp}) {
            next;
        }
        $stamps{$stamp}++;
        print ofh "$_\n";
    }
}
close(fh);
close(ofh);

print scalar(keys %stamps)."\n";
