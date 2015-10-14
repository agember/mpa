#!/usr/bin/perl

use strict;
use Date::Calc qw(Day_of_Year Mktime Add_Delta_Days);

# OUTPUT:
# basic_metrics.csv, contains the following for each stamp for each period:
# - stamp name
# - period
# - number of devices
# - number of roles
# - number of models
# - number of vendors
# - entropy
# - normalized entropy
# - number of ticket
# - number of ticket with packet loss
# - sum of ticketed outage durations
# - average ticketed outage duration
# - number of events
# - number of events with packet loss
# - number of unduplicated events (group events in 1 minute windows and count 
#   number of windows with events)
# - number of unduplicated events with packet loss
# - number of unduplicated events without packet loss
# - sum of unduplicated event outage durations
# - average unduplicated event outage duration
# - number of changes (a change occurs when one or more lines of a device's 
#   configuration are added/removed/modified at a given point in time)
# - average number of days between changes
# - fraction of the stamp's devices that are changed at least once in the period
# - number of changes that are automated
# - number of changes that are manual
# - number of change events (a change event occurs when one or more changes
#   within a given time window (e.g., 5 minutes)
# - average number of days between change events
# - average number of devices changed per change event
# - average number of roles changed per change event
# - average number of models changed per change event
# - fraction of change events where all changes are automatic
# - fraction of change events where both automatic and manual changes occur
# - fraction of change events where all changes are manual
# - fraction of change events that only affect middleboxes
# - fraction of change events that only affect forwarding devices (e.g.,
#   switches, routers)
# - fraction of change events that affect both middleboxes and forwarding devs

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";

my $hardwareFile = "$datadir/hardware.txt";
my $ticketFile = "$datadir/ticket.txt";
my $changefreqFile = "$datadir/change_frequency.txt";
my $outputfile = "$datadir/basic_metrics.csv";

my $allowmissing = "yes";
if ($#ARGV >= 0) {
    $allowmissing = $ARGV[0];
}
if (not ($allowmissing eq "yes" or $allowmissing eq "no")) {
    die("Specify 'yes' or 'no' for whether to allow missing values");
}
print "Allow missing? ", $allowmissing,"\n";

my $window = 1;
my $mindate = "";
my $maxdate = "";
if ($#ARGV >= 1) {
    $window = $ARGV[1];
    if ($#ARGV >= 3) {
        $mindate = $ARGV[2];
        $maxdate = $ARGV[3];
    }
}
if (not ($window >= 1)) {
    die("Window must be >= 1 period");
}
print "Window ", $window," periods\n";

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
    print "Limited to date range: $mindate to $maxdate\n";
}


my $hardware = {};
my $ticket = {};
my $changefreq = {};

my %months;

# Load output from device_hardware.pl
open(fh, "$hardwareFile") or die("Could not open $hardwareFile");
my $hardwareHdr = "NumDevices,NumRoles,NumModels,NumVendors,"
        ."Entropy,NormalizedEntropy";
while (<fh>) {
    chomp;
    my @cols = split " ", $_;

    my $stampName = $cols[0];
    my $numDevices = $cols[1];
    my $numRoles = $cols[2];
    my $numModels = $cols[3];
    my $numVendors = $cols[4];
    my $entropy = $cols[5];
    my $normEntropy = $cols[6];

    $hardware->{$stampName} = [ $numDevices, $numRoles, $numModels, 
            $numVendors, $entropy, $normEntropy ];
}
close(fh);

# Load output from ticket_count.pl
open(fh, "$ticketFile") or die("Could not open $ticketFile");
my $ticketHdr = "NumTickets,NumLossTickets,TotalTicketDuration,"
        ."AvgTicketDuration,NumEvents,NumLossEvents,NumUndupEvents,"
        ."NumLossUndupEvents,NumNoLossUndupEvents,TotalUndupEventDuration,"
        ."AvgUndupEventDuration";
my $ticketNull = "0,0,0,0,0,0,0,0,0,0,0";
while (<fh>) {
    chomp;
    s/://g;
    my @cols = split " ", $_;

    my $stampName = $cols[0];
    my $period = $cols[1];
    my $numTickets = $cols[2];
    my $numLossTickets = $cols[3];
    my $sumTicketDur = $cols[4];
    my $avgTicketDur = $cols[5];
    my $numEvents = $cols[6];
    my $numLossEvents = $cols[7];
    my $numUndup = $cols[8];
    my $numLossUndup = $cols[9];
    my $numNoLossUndup = $cols[10];
    my $sumUndupDur = $cols[11];
    my $avgUndupDur = $cols[12];
    $months{$period} = 1;
    $ticket->{$stampName}{$period} = [ $numTickets, $numLossTickets, 
            $sumTicketDur, $avgTicketDur, $numEvents, $numLossEvents, 
            $numUndup, $numLossUndup, $numNoLossUndup, $sumUndupDur, 
            $avgUndupDur ];
}
close(fh);

# Load output from change_frequency.pl
open(fh, "$changefreqFile") or die("ERROR: Could not open $changefreqFile");
my $changefreqHdr = "RawNumChanges,RawRateOfChange,FracDevicesChanged,"
        ."FracNatureAutoChanges,FracNatureUnknownChanges,NumChanges,"
        ."RateOfChange,MeanDevicesChanged,MeanRolesChanged,MeanModelsChanged,"
        ."FractionAutoChanges,FractionMixedChanges,FractionUnknownChanges,"
        ."FractionRoleMboxChanges,FractionRoleFwdChanges,"
        ."FractionRoleMixedChanges";
my $changefreqNull = "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
my $cHdr = <fh>;
while (<fh>) {
    chomp;
    s/://g;
    my @cols = split " ", $_;

    my $stampName = $cols[0];
    my $period = $cols[1];
    my $rawNumChanges = $cols[2];
    my $rawRateOfChange = $cols[3];
    my $fracDevicesChanged = $cols[4];
    my $rawAutoChanges = $cols[5];
    my $rawUnknChanges = $cols[6];
    my $numChanges = $cols[7];
    my $rateOfChange = $cols[8];
    my $meanDevicesChanged = $cols[5];
    my $meanRolesChanged = $cols[6];
    my $meanModelsChanged = $cols[7];
    my $fracAutoChanges = $cols[8];
    my $fracMixedChanges = $cols[9];
    my $fracUnknownChanges = $cols[10];
    my $fracMboxRoleChanges = $cols[11];
    my $fracFwdRoleChanges = $cols[12];
    my $fracMixedRoleChanges = $cols[13];

    $months{$period} = 1;
    $changefreq->{$stampName}{$period} = [ $rawNumChanges, $rawRateOfChange, 
        $fracDevicesChanged, $rawAutoChanges, $rawUnknChanges,
        $numChanges, $rateOfChange, $meanDevicesChanged, 
        $meanRolesChanged, $meanModelsChanged, 
        $fracAutoChanges, $fracMixedChanges, $fracUnknownChanges, 
        $fracMboxRoleChanges, $fracFwdRoleChanges, $fracMixedRoleChanges ];
}
close(fh);

open(fh, ">$outputfile") or die("ERROR: Could not open $outputfile");
print fh "StampName,Month,$hardwareHdr,$ticketHdr,$changefreqHdr\n";

# Filter periods
my @periods;
if ($mintime > 0 and $maxtime > 0 and (scalar(keys %months) > 1)) {
    for my $period (sort(keys %months)) {
        my $periodtime = -1;
        if ($period =~ m/^(\d{4})-(\d{2})$/) {
            my $year = $1;
            my $month = $2;
            $periodtime = Mktime($year, $month, 1, 0, 0, 0);
        } elsif ($period =~ m/^(\d{4})-(\d{3})$/) {
            my $year = $1;
            my $doy = $2;
            ($year, my $month, my $day) = Add_Delta_Days($year,1,1, $doy - 1);
            $periodtime = Mktime($year, $month, $day, 0, 0, 0);
        }
        if ($periodtime > $mintime and $periodtime < $maxtime) {
            push(@periods, $period);
        }
    }
} else {
    @periods = sort(keys %months);
}

my @starts;
for (my $i = 0; $i < scalar(@periods)-($window-1); $i++) {
    @starts[$i] = @periods[$i];
}

for (sort(keys %$hardware)) {
    my $stampName = $_;

    # Skip stamps without ticket data
    if (!exists $ticket->{$stampName}) {
        next;
    }

    for (my $i = 0; $i < scalar(@starts); $i++) {
        my $month = @starts[$i];

        print fh "$stampName,$month,";
        print fh join(",",@{$hardware->{$stampName}});
        print fh ",";

        my @t;
        for (my $j = $i; $j < $i + $window; $j++) {
            if (exists $ticket->{$stampName}{@periods[$j]})
            {
                my $data = $ticket->{$stampName}{@periods[$j]};
                for (my $k = 0; $k < scalar(@{$data}); $k++) {
                    @t[$k] += @{$data}[$k];
                }
            }
        }
        if (scalar(@t) > 0) {
            print fh join(",",@t);
        }
        else {
            print fh "$ticketNull";
        }
        print fh ",";

        my @c;
        for (my $j = $i; $j < $i + $window; $j++) {
            if (exists $changefreq->{$stampName}{@periods[$j]})
            {
                my $data = $changefreq->{$stampName}{@periods[$j]};
                for (my $k = 0; $k < scalar(@{$data}); $k++) {
                    if (!(@{$data}[$k] =~ m/^-?[0-9]/)) {
                        @c[$k] = @{$data}[$k];
                    } else {
                        @c[$k] += @{$data}[$k];
                    }
                }
            }
        }
        if (scalar(@c) > 0) {
            print fh join(",",@c);
        }
        else {
            print fh "$changefreqNull";
        }
        print fh "\n";
    }
}
close(fh);
