#!/usr/bin/perl

# OUTPUT:
# protocols.txt, contains the following for each stamp for each period:
# - stamp name
# - period
# - number of layer 2 protocols in use
# - number of layer 3 protocols in use
# - sum of number of VLANs declared across all devices (i.e., total number of
#   VLAN stanzas across all configs)
# - number of interfaces with a VLAN configured
# - number of interfaces configured to use UDLD
# - number of interfaces configured to use LACP
# - number of interfaces configured to use VLANs
# - number of interfaces configured to use DHCP
# - number of interfaces configured to use HSRP
# - number of interfaces configured to use MST
# - number of interfaces configured to use LLDP
# - number of interfaces configured to use VRRP
# - number of interfaces configured to use NSRP
# - number of OSPF routing processes across all devices
# - average number of OSPF routing processes per device
# - number of BGP routing processes across all devices
# - average number of BGP routing processes per device
# - average intra-device referential complexity


use strict;
use List::Util qw(first);
use Date::Calc qw(Day_of_Year Mktime);

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or 
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $statisticsFile = "$datadir/batfish/statistics.csv";
my $sortedstatisticsFile = "$datadir/batfish/sorted_statistics.csv";
my $protocolsFile = "$datadir/protocols.txt";

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
    die("Must specify split period");
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
my $lastPeriod ="";
my $mindate = "";
my $maxdate = "";
if ($#ARGV >= 2) {
    $mindate = $ARGV[1];
    $maxdate = $ARGV[2];
}
my $mintime = -1;
my $maxtime = -1;
if ($mindate eq "" or $maxdate eq "") {
    die("Must specify date range\n");
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

        if ($monthsplit >= 1) {
            $lastPeriod = sprintf("%04d-%02d", $1, $2);
        }
        elsif($daysplit >= 1) {
            my $doy = Day_of_Year($1, $2, $3);
            $lastPeriod = sprintf("%04d-%03d", $1, $doy);
        }

    } else {
        die("Invalid ending date; must specify ending date as YYYY-MM-DD");
    }
    if ($mintime >=0 and $maxtime >= 0 and $maxtime <= $mintime) {
        die("Ending date must be after starting date");
    }
    print "Limited to date range: $mindate to $maxdate\n";
}

print "LastPeriod=$lastPeriod\n";

`head -n 1 $statisticsFile > $sortedstatisticsFile`;
`tail -n +2 $statisticsFile | sort >> $sortedstatisticsFile`;

open(sfh, "$sortedstatisticsFile") or 
        die ("Could not open $sortedstatisticsFile");
open(pfh, ">$protocolsFile") or die ("Could not open $protocolsFile");

print pfh "StampName Period NumL2Protocols NumL3Protocols NumVlans"
        ." VlansIfaces NumUdld NumLacpInst NumDot1q NumDhcp NumHsrp NumMstp"
        ." NumLldp NumVrrp NumNsrp AvgOspfSize NumOspfInst NumOspfProcesses"
        ." AvgBgpSize NumBgpInst NumBgpProcesses IntraRefComplex\n";

my $lastStamp = "";
my %statistics;
my %periods;
my $hdr = <sfh>;
chomp $hdr;
my @hdrCols = split/,/, $hdr;
my $numCols =  scalar(@hdrCols) - 6;
my %offsets;
for my $i (0..scalar(@hdrCols)) {
    $offsets{$hdrCols[$i]} = $i-6;
}

while (<sfh>) {
    chomp;
    my @cols = split/,/, $_;
    my $stamp = $cols[0];
    if ($stamp ne $lastStamp and $lastStamp ne "") {
        my $firstPeriod = (sort(keys %periods))[0];
        print "$stamp\n";

        if ($firstPeriod ne "") {

        # Make sure we have all periods from first to last
        my $period = $firstPeriod;
        while ($period ne $lastPeriod) {
            $period =~ /^(\d+)-(\d+)$/;
            if ($monthsplit >= 1) {
                my $year = $1;
                my $month = $2 + $monthsplit;
                if ($month > 12) {
                    $month -= 12;
                    $year++;
                }
                $period = sprintf("%04d-%02d", $year, $month);
            }
            elsif($daysplit >= 1) {
                my $year = $1;
                my $doy = $2 + $daysplit;
                if ($doy > 365) {
                    $doy -= 365;
                    $year++;
                }
                $period = sprintf("%04d-%03d", $year, $doy);
            }
            $periods{$period} = 1;
        }

        foreach my $period (sort(keys %periods)) {
#            print "$period\n";
            my @sums = (0) x ($numCols-1);
            my $numDevices = 0;
            my %vlans;
            foreach my $device (sort(keys %statistics)) {
                my $usePeriod = $period;
                while (!exists $statistics{$device}{$usePeriod} and
                        $usePeriod ne $firstPeriod) {
                    $usePeriod =~ /^(\d+)-(\d+)$/;
                    if ($monthsplit >= 1) {
                        my $year = $1;
                        my $month = $2 - $monthsplit;
                        if ($month < 1) {
                            $month += 12;
                            $year--;
                        }
                        $usePeriod = sprintf("%04d-%02d", $year, $month);
                    }
                    elsif($daysplit >= 1) {
                        my $year = $1;
                        my $doy = $2 - $daysplit;
                        if ($doy < 1) {
                            $doy += 365;
                            $year--;
                        }
                        $usePeriod = sprintf("%04d-%03d", $year, $doy);
                    }
                }
                if (!exists $statistics{$device}{$usePeriod}) {
                    next;
                }
#                print "\t$device $usePeriod\n";

                my @deviceVlans = split /-/, 
                        $statistics{$device}{$usePeriod}[$offsets{Vlans}];
                for my $vlan (@deviceVlans) {
                    $vlans{$vlan}++;
                }

                for my $index ($offsets{VlansIfaces}..$numCols-1) {
                    $sums[$index] += $statistics{$device}{$usePeriod}[$index];
                }
                $numDevices++;
            }

            $sums[$offsets{NumVlans}] = scalar(keys %vlans);

            my $numL2 = 0;
            for my $index ($offsets{UDLD}..$offsets{NSRP}) {
                if ($sums[$index] > 0) {
                    $numL2++;
                }
            }

            my $numL3 = 0;
            if ($sums[$offsets{OspfProcesses}] > 0) {
                $numL3++;
            }
            if ($sums[$offsets{BgpProcesses}] > 0) {
                $numL3++;
            }

            $sums[$offsets{IntraRefComplex}] = 
                    $sums[$offsets{IntraRefComplex}]/$numDevices;

            my $avgOspf = $sums[$offsets{OspfInst}]/$numDevices;
            my $avgBgp = $sums[$offsets{BgpInst}]/$numDevices;
            splice @sums, $offsets{OspfInst}, 0, $avgOspf;
            splice @sums, $offsets{BgpInst}, 0, $avgBgp;

            $sums[$offsets{Vlans}] = $numL3;
            splice @sums, $offsets{Vlans}, 0, $numL2;

            print pfh "$lastStamp $period @sums\n";
        }
        }

        %statistics = ();
        %periods = ();
    }

    my $device = $cols[1];
    my $config = $cols[2];
    my $period = "all";
    if ($config =~ /^(\d+)-(\d+)-(\d+)/) {
        my $year = $1;
        my $month = $2;
        my $day = $3;
        my $time = Mktime($year, $month, $day, 0, 0, 0);
        if ($time < $mintime or $time > $maxtime) {
            next;
        }

        if ($monthsplit >= 1) {
            $month -= ($month - 1) % $monthsplit;
            $period = sprintf("%04d-%02d", $year, $month);
        }
        elsif($daysplit >= 1) {
            my $doy = Day_of_Year($year, $month, $day);
            $doy -= ($doy - 1) % $daysplit;
            $period = sprintf("%04d-%03d", $year, $doy);
        }
    }
    else {
        die("Invalid config name: $config");
    }

    if (!exists $statistics{$device}) {
        $statistics{$device} = {};
    }
    
    $statistics{$device}{$period} = [];
    push @{$statistics{$device}{$period}}, @cols[6..(scalar(@cols)-1)];

    $periods{$period} = 1;
    $lastStamp = $stamp;
}
close(sfh);
close(pfh);
