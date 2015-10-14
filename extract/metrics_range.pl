#!/usr/bin/perl

# PREREQUSITES: MGMTPLANE_CODE/diffs/diff_configs.pl and 
# MGMTPLANE_CODE/extract/device_hardware.pl have been run.

# OUTPUT:
# earliest.csv, contains the following for each stamp:
# - stamp name
# - date of earliest change
# - date of earliest ticket
# - date after which both change and ticket have occurred (i.e., the later of 
#   earliest change and earliest ticket)
# - date after which either change and ticket has occurred (i.e., the earlier 
#   of earliest change and earliest ticket)
# - date of latest change
# - date of latest ticket
# - date after which only changes or tickets occur (i.e., the earlier of latest
#   change and latest ticket)
# - date after which neither changes or tickets occur (i.e., the later of
#   latest change and latest ticket)

use strict;
use Date::Calc qw(Day_of_Year Mktime Days_in_Month Localtime);

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $diffsdir = "$datadir/diffs";
my $devicesfile = "$datadir/devices.txt";
my $ticketscsv = "$datadir/events.csv";
my $rangefile = "$datadir/metrics_range.csv";

# Get the date range arguments
my $mindate = "";
my $maxdate = "";
if ($#ARGV >= 1) {
    $mindate = $ARGV[0];
    $maxdate = $ARGV[1];
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

# Get timestamp for earliest and latest change for each stamp
my %earliestchange;
my %latestchange;

# Get list of stamps
opendir(D, $diffsdir) or die("Could not open $diffsdir");
my @stamps = readdir(D);
shift @stamps;
shift @stamps;
closedir(D);

# Process each stamp
foreach my $stamp (sort(@stamps)) {
    if (($stamp =~ /^\.$/) or ($stamp =~ /^\.\.$/)) {
	    next;
    }
    my $stampdir = "$diffsdir/$stamp";

    # Get list of devices
    opendir(D, $stampdir) or die("Could not open $stampdir");
    my @devs = readdir(D);
    closedir(D);

    # Process each device
    foreach my $fd (sort(@devs)) {
        if (($fd =~ /^\.$/) or ($fd =~ /^\.\.$/)) {
            next;
        }
        my $devicedir = "$stampdir/$fd";

        # Get list of diffs
        opendir(D, $devicedir) or die("Could not open $devicedir");
        my @difffiles = readdir(D);
        closedir(D);

        # Proces each diff
        foreach my $df (sort(@difffiles)) {
            if (($df =~ /^\.$/) or ($df =~ /^\.\.$/)) {
                next;
            }
            if ($df =~/.*-(20..)-(..)-(..)-(..)-(..)-(..)-.+\.diff$/){
                my $year = $1;
                my $month = $2;
                my $date = $3;
                my $hour = $4;
                my $minute = $5;
                my $second = $6;

                my $time = Mktime($year, $month, $date, 0, 0, 0);
                if (($mintime >= 0 and $time < $mintime) 
                        or ($maxtime >= 0 and $time > $maxtime)) {
                    next;
                }

                $time = Mktime($year, $month, $date, $hour, $minute, $second);
                if (!exists($earliestchange{$stamp})) {
                    $earliestchange{$stamp} = $time;
                } elsif ($time < $earliestchange{$stamp}) {
                    $earliestchange{$stamp} = $time;
                }
                if (!exists($latestchange{$stamp})) {
                    $latestchange{$stamp} = $time;
                } elsif ($time > $latestchange{$stamp}) {
                    $latestchange{$stamp} = $time;
                }
            }
        }
    }
}

my %devicestostamps;

# Read device details
open(dfh, "$devicesfile") or die("Could not open $devicesfile");
my $devicename;
while (<dfh>) {
    chomp $_;
    my @cols = split(" ", $_);

    my $dev = $cols[0];
    my $stamp = $cols[1];
    $devicestostamps{$dev} = $stamp;
}
close(dfh);

# Get timestamp for earliest and latest ticket for each stamp
my %earliestticket;
my %latestticket;

open(fh, "$ticketscsv") or die("Could not open $ticketscsv");
while (<fh>) {
    chomp;
    my @s = split /\,/, $_;
    # The fields are device, startdate, duration, packet loss, ticketId, 
    # ticketDesc, IfMaintenance
    if (scalar(@s) != 7) {
        next;
    }
    my $dev = $s[0];
    my $timestamp = $s[1];
    my $ticket = $s[4];
    my $ifmaint = $s[6];

    #5/31/2014 7:18:28 AM
    my @dt = split /\s/, $timestamp;
    my @d = split /\//, $dt[0];
    my $year = $d[2];
    my $day = $d[1];
    my $month = $d[0];
    my @t = split /:/, $dt[1];
    my $hour = $t[0];
    my $minute = $t[1];
    my $second = $t[2];
    my $time = Mktime($year, $month, $day, 0, 0, 0);
    if (($mintime >= 0 and $time < $mintime) 
            or ($maxtime >= 0 and $time > $maxtime)) {
        next;
    }

    my $stamp = $devicestostamps{$dev};
    if (!defined($stamp)) {
        $stamp = "UNDEF";
    }

    $time = Mktime($year, $month, $day, $hour, $minute, $second);
    if (!exists($earliestticket{$stamp})) {
        $earliestticket{$stamp} = $time;
    } elsif ($time < $earliestticket{$stamp}) {
        $earliestticket{$stamp} = $time;
    }
    if (!exists($latestticket{$stamp})) {
        $latestticket{$stamp} = $time;
    } elsif ($time > $latestticket{$stamp}) {
        $latestticket{$stamp} = $time;
    }
}
close(fh);

open fh, ">$rangefile" or die("Could not open $rangefile");
print fh "Stamp,FirstChange,FirstTicket,FirstBoth,FirstEither,LastChange,"
        ."LastTicket,LastBoth,LastEither\n";
foreach my $stamp (sort(keys %earliestchange)) {
    my $firstchangetime = $earliestchange{$stamp};
    my ($year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst) = 
            Localtime($firstchangetime);
    my $firstchangestr = sprintf("%04d-%02d-%02d",$year,$month,$day);
    if ($firstchangetime <= 0) {
        $firstchangestr = "";
    }

    my $firsttickettime = $earliestticket{$stamp};
    ($year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst) = 
            Localtime($firsttickettime);
    my $firstticketstr = sprintf("%04d-%02d-%02d",$year,$month,$day);
    if ($firsttickettime <= 0) {
        $firstticketstr = "";
    }

    my $firstbothstr;
    my $firsteitherstr;
    if ($firstchangetime <= 0) {
        $firstbothstr="No Changes";
        $firsteitherstr = $firstticketstr;
    } elsif ($firsttickettime <= 0) {
        $firstbothstr="No Tickets";
        $firsteitherstr = $firstchangestr;
    } elsif ($firsttickettime < $firstchangetime) {
        $firstbothstr = $firstchangestr;
        $firsteitherstr = $firstticketstr;
    } else {
        $firstbothstr = $firstticketstr;
        $firsteitherstr = $firstchangestr;
    }
    
    my $lastchangetime = $latestchange{$stamp};
    ($year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst) = 
            Localtime($lastchangetime);
    my $lastchangestr = sprintf("%04d-%02d-%02d",$year,$month,$day);
    if ($lastchangetime <= 0) {
        $lastchangestr = "";
    }

    my $lasttickettime = $latestticket{$stamp};
    ($year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst) = 
            Localtime($lasttickettime);
    my $lastticketstr = sprintf("%04d-%02d-%02d",$year,$month,$day);
    if ($lasttickettime <= 0) {
        $lastticketstr = "";
    }

    my $lastbothstr;
    my $lasteitherstr;
    if ($lastchangetime <= 0) {
        $lastbothstr="No Changes";
        $lasteitherstr = $lastticketstr;
    } elsif ($lasttickettime <= 0) {
        $lastbothstr="No Tickets";
        $lasteitherstr = $lastchangestr;
    } elsif ($lasttickettime > $lastchangetime) {
        $lastbothstr = $lastchangestr;
        $lasteitherstr = $lastticketstr;
    } else {
        $lastbothstr = $lastticketstr;
        $lasteitherstr = $lastchangestr;
    }

    print fh "$stamp,$firstchangestr,$firstticketstr,$firstbothstr,"
        ."$firsteitherstr,$lastchangestr,$lastticketstr,$lastbothstr,"
        ."$lasteitherstr\n";
}
close fh;
