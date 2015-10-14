#!/usr/bin/perl

use strict;
use Date::Calc qw(Day_of_Year Mktime);

# OUTPUT:
# config_list.txt, contains the following for each relevant config:
# - stamp name
# - device name
# - config name
# - device vendor
# - device role
# - device model

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $cfgsdir = "$datadir/uncompcfgs/";
my $listfile = "$datadir/config_list.txt";
my $devsfile = "$datadir/devices.txt";

# Get arguments
my $splitperiod = "";
if ($#ARGV >= 0) {
    $splitperiod = $ARGV[0];
    if ($splitperiod eq "all") {
        $splitperiod = "";
    }
}
my $monthsplit = 0;
my $daysplit = 0;
if ($splitperiod eq "") {
    print "Not splitting by day(s) or month(s)\n";
}
elsif ($splitperiod =~m/^((1[0-2])|[0-9])m$/) {
    $monthsplit = $1;
    print "Splitting by $monthsplit month(s)\n";
}
elsif ($splitperiod =~m/^([1-9]?[0-9])d$/) {
    $daysplit = $1;
    print "Splitting by $daysplit day(s)\n";
}
else {
    die("Must split by months ('0m' to '12m') or days ('0d' to '99d')");
}

my $mindate = "";
my $maxdate = "";
if ($#ARGV >= 2) {
    $mindate = $ARGV[1];
    $maxdate = $ARGV[2];
}
my $mintime = -1;
my $maxtime = -1;
if ($mindate eq "" or $maxdate eq "") {
    print "Not limited by date range\n";
}
else {
    if ($mindate =~ m/^(\d{4})-(\d{2})-(\d{2})$/) {
        $mintime = Mktime($1, $2, $3, 0, 0, 0);
        $mintime -= 1;
    } else {
        die("Invalid starting date; must specify starting date as YYYY-MM-DD");
    }
    if ($maxdate =~ m/^(\d{4})-(\d{2})-(\d{2})$/) {
        $maxtime = Mktime($1, $2, $3, 23, 59, 59);
        $maxtime += 1;
    } else {
        die("Invalid ending date; must specify ending date as YYYY-MM-DD");
    }
    if ($mintime >=0 and $maxtime >= 0 and $maxtime <= $mintime) {
        die("Ending date must be after starting date");
    }
    print "Limited to date range: $mindate to $maxdate\n";
}

# Read device details
open dfh, "$devsfile" or die("Could not open $devsfile");
my %devices;
while(<dfh>) {
    chomp $_;
    my @cols = split(" ", $_);

    if (scalar(@cols) < 5) {
        die("Invalid line of data: $_");
    }

    my $dev = $cols[0];
    my $stamp = $cols[1];
    my $role = $cols[2];
    my $vendor = $cols[3];
    my $model = $cols[4];
    if (!exists $devices{$stamp}) {
        $devices{$stamp} = {};
    }
    $devices{$stamp}->{$dev} = {'role' => $role, 'vendor' => $vendor, 
        'model' => $model};
}
close dfh;

open(fh, ">$listfile") or die("Could not open $listfile");

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

    # Get device names
    my $stampdir = "$cfgsdir/$stampname";
    opendir(D, "$stampdir") or die("Could not open $stampdir");
    my @devs = readdir(D);
    closedir(D);

    # Process each device
    foreach my $devname (sort(@devs)) {
        if (($devname =~ /^\.$/) or ($devname =~ /^\.\.$/)) {
            next;
        }
        print "Processing $devname\n";

        # Get device details
        my $vendor = $devices{$stampname}->{$devname}->{vendor};
        my $role = $devices{$stampname}->{$devname}->{role};
        my $model = $devices{$stampname}->{$devname}->{model};

        # Get list of configs
        my $devdir = "$stampdir/$devname";
        opendir(D, $devdir) or die("Could not open $devdir");
        my @conffiles = readdir(D);
        closedir(D);

        # Process each config
        my %latestConfigs;
        foreach my $cf (sort(@conffiles)) {
            if (($cf =~ /^\.$/) or ($cf =~ /^\.\.$/) or !($cf =~ /\.cfg$/)) {
                next;
            }

            if ($cf =~ /(20..)-(..)-(..)-(..)-(..)-(..)\.cfg$/) {
                my $year = $1;
                my $month = $2;
                my $day = $3;

                # Check if config file is outside date range
                my $time = Mktime($year, $month, $day, 0, 0, 0);
                if (($mintime >= 0 and $time < $mintime) 
                        or ($maxtime >= 0 and $time > $maxtime)) {
                    print "$cf is outside date range\n";
                    next;
                }

                my $datestamp = "all";
                if ($monthsplit >= 1) {
                    $month -= ($month - 1) % $monthsplit;
                    $datestamp = sprintf("%04d-%02d", $year, $month);
                }
                elsif($daysplit >= 1) {
                    my $doy = Day_of_Year($year, $month, $day);
                    $doy -= ($doy - 1) % $daysplit;
                    $datestamp = sprintf("%04d-%03d", $year, $doy);
                }
                $latestConfigs{$datestamp} = $cf;
            }
        }

        foreach my $period (sort(keys(%latestConfigs))) {
            print fh "$stampname,$devname,$latestConfigs{$period},"
                ."$vendor,$role,$model\n";
        }

    }
}

close(fh);
