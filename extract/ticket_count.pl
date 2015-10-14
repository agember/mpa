#!/usr/bin/perl

# PREREQUSITES: MGMTPLANE_CODE/extract/device_hardware.pl has been run.

# OUTPUT:
# tickets.txt, contains the following for each stamp for each period:
# - stamp name
# - period
# - number of tickets
# - number of tickets with packet loss
# - sum of ticketed outage durations
# - average ticketed outage duration
# - number of events
# - number of events with packet loss
# - number of unduplicated events (group events in 1 minute windows and count number of windows with events)
# - number of unduplicated events with packet loss
# - number of unduplicated events without packet loss
# - sum of unduplicated event outage durations
# - average unduplicated event outage duration
# - sum of ticketed packet loss

use strict;
use Date::Calc qw(Day_of_Year Mktime);

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or 
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $devicesfile = "$datadir/devices.txt";
my $ticketscsv = "$datadir/events.csv";
my $ticketsfile = "$datadir/ticket.txt";

# Get the split argument
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

my %devicestostamps;
my %numDevices;

# Read device details
open(dfh, "$devicesfile") or die("Could not open $devicesfile");
my $devicename;
while (<dfh>) {
    chomp $_;
    my @cols = split(" ", $_);

    my $dev = $cols[0];
    my $stamp = $cols[1];
    $devicestostamps{$dev} = $stamp;
    $numDevices{$stamp}++;
}
close(dfh);

my %ticketseen;
my %issues;
my %issuesDuration;
my %events;
my %eventseen;
my %undupevents;
my %undupDuration;
my %issuesWithPktLoss;
my %eventsWithPktLoss;
my %undupWithPktLoss;
my %undupNoPktLoss;
my %undupMixedPktLoss;
my %issuesPktLoss;

open(fh, "$ticketscsv") or die("Could not open $ticketscsv");
while (<fh>) {
    chomp;
    my @s = split /\,/, $_;
    # The fields are device, startdate, duration, packet loss, ticketId, ticketDesc, IfMaintenance
    if (scalar(@s) != 7) {
        next;
    }
    my $dev = $s[0];
    my $timestamp = $s[1];
    my $duration = $s[2];
    my $packetLoss = $s[3];
    my $ticket = $s[4];
    my $ifmaint = $s[6];

    #5/31/2014 7:18:28 AM
    my @dt = split /\s/, $timestamp;
    my @d = split /\//, $dt[0];
    my $year = $d[2];
    my $day = $d[1];
    my $month = $d[0];
    my $time = Mktime($year, $month, $day, 0, 0, 0);
    if (($mintime >= 0 and $time < $mintime) or ($maxtime >= 0 and $time > $maxtime)) {
#        print("Skipping $timestamp which is outside $mindate to $maxdate\n");
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

    my $stamp = $devicestostamps{$dev};
    if (!defined($stamp)) {
        $stamp = "UNDEF";
#                print "Stamp for $dev is not known\n";
    }

    if (!exists $issues{$stamp}{$datestamp}) {
        $issues{$stamp}{$datestamp} = 0;
        $issuesWithPktLoss{$stamp}{$datestamp} = 0; 
        $issuesDuration{$stamp}{$datestamp} = 0; 
        $events{$stamp}{$datestamp} = 0;
        $eventsWithPktLoss{$stamp}{$datestamp} = 0;
        $undupevents{$stamp}{$datestamp} = 0;
        $undupWithPktLoss{$stamp}{$datestamp} = 0;
        $undupNoPktLoss{$stamp}{$datestamp} = 0;
        $undupMixedPktLoss{$stamp}{$datestamp} = 0;
        $undupDuration{$stamp}{$datestamp} = 0;
        $issuesPktLoss{$stamp}{$datestamp} = 0;
    }

    # Count non-maintenance tickets 
    if (($ticket =~ m/\d+/) and ($ifmaint =~ m/NO/)) {
        if (!$ticketseen{$ticket}) {
            $ticketseen{$ticket} = 1;
            $issues{$stamp}{$datestamp}++;
            if (!($packetLoss =~ m/N\/A/) and ($packetLoss > 0)) {
                $issuesWithPktLoss{$stamp}{$datestamp}++;
                $issuesPktLoss{$stamp}{$datestamp} += $packetLoss;
                if ($packetLoss > 100) {
                    print "$_\n";
                }
            }
            #printf "$dev $stamp $year $month $ticket\n";
            $issuesDuration{$stamp}{$datestamp} += $duration;
        }
    }

    # Count non-maintenance events
    if ($ifmaint =~ m/NO/) {
        $events{$stamp}{$datestamp}++;
        my @t = split/:/, $dt[1];
        my $minute = "$dt[0] $t[0]:$t[1] $dt[2]";
        my $event = "$stamp-$minute";
        if (! exists $eventseen{$event}) {
            $undupevents{$stamp}{$datestamp}++;
            $undupDuration{$stamp}{$datestamp} += $duration;
            if (!($packetLoss =~ m/N\/A/) and ($packetLoss > 0)) {
                $eventseen{$event} = 1;
                $undupWithPktLoss{$stamp}{$datestamp}++;
            }
            else {
                $eventseen{$event} = -1;
                $undupNoPktLoss{$stamp}{$datestamp}++;
            }
        }
        else {
            if (!($packetLoss =~ m/N\/A/) and ($packetLoss > 0)) {
                if (-1 == $eventseen{$event}) {
                    $undupNoPktLoss{$stamp}{$datestamp}--;
                    $undupMixedPktLoss{$stamp}{$datestamp}++;
                    $eventseen{$event} = 0;
                }
            }
            else {
                if (1 == $eventseen{$event}) {
                    $undupWithPktLoss{$stamp}{$datestamp}--;
                    $undupMixedPktLoss{$stamp}{$datestamp}++;
                    $eventseen{$event} = 0;
                }
            }
        }
        if (!($packetLoss =~ m/N\/A/) and ($packetLoss > 0)) {
            $eventsWithPktLoss{$stamp}{$datestamp}++;
        }
    }
}
close(fh);

open(fh, ">$ticketsfile") or die("Could not open $ticketsfile");
print fh "StampName Period NumTickets NormalizedNumTickets NumLossTickets"
        ." NormalizedNumLossTickets TotalTicketDuration AvgTicketDuration"
        ." NumEvents NumLossEvents NumUndupEvents NumLossUndupEvents"
        ." NumNoLossUndupEvents TotalUndupEventDuration AvgUndupEventDuration\n";
foreach my $stamp (sort(keys %issues)) {
    for my $datestamp (sort(keys %{$issues{$stamp}})) {
        my $normNumIssues = -1;
        my $normNumLossIssues = -1;
        if (exists $numDevices{$stamp}) {
            $normNumIssues = $issues{$stamp}{$datestamp} / 
                    $numDevices{$stamp};
            $normNumLossIssues = $issuesWithPktLoss{$stamp}{$datestamp} / 
                    $numDevices{$stamp};
        }

        my $issuesDurationAvg = -1;
        if ($issues{$stamp}{$datestamp} > 0) {
            $issuesDurationAvg = $issuesDuration{$stamp}{$datestamp} / 
                    $issues{$stamp}{$datestamp};
        }

        my $undupDurationAvg = -1;
        if ($undupevents{$stamp}{$datestamp} > 0) {
            $undupDurationAvg = $undupDuration{$stamp}{$datestamp} / 
                    $undupevents{$stamp}{$datestamp};    
        }

        print fh "$stamp $datestamp"
                ." $issues{$stamp}{$datestamp} $normNumIssues"
                ." $issuesWithPktLoss{$stamp}{$datestamp} $normNumLossIssues"
                ." $issuesDuration{$stamp}{$datestamp} $issuesDurationAvg"
                ." $events{$stamp}{$datestamp}"
                ." $eventsWithPktLoss{$stamp}{$datestamp}"
                ." $undupevents{$stamp}{$datestamp}"
                ." $undupWithPktLoss{$stamp}{$datestamp}"
                ." $undupNoPktLoss{$stamp}{$datestamp}"
                ." $undupDuration{$stamp}{$datestamp} $undupDurationAvg"
#                ." $issuesPktLoss{$stamp}{$datestamp}"
                ."\n";
    }
}
close(fh);
