#!/usr/bin/perl

# PREREQUSITES: MGMTPLANE_CODE/extract/device_hardware.pl has been run.

# OUTPUT: 
# firmware_hetero.txt, contains the following for each stamp:
# - stamp name
# - period
# - number of firmware versions
# - normalized firmware versions = # of firmware versions / # of vendors
# - firmware entropy (indicates model-firmware heterogenity)
# - normalized firmware entropy = firmware entropy / log # of devices
# - number of devices
# - number of vendors
# - number of models

use strict;
use Date::Calc qw(Day_of_Year Mktime Gmtime Add_Delta_YM Add_Delta_Days);

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or 
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $firmwarefile = "$datadir/firmware.txt";
my $resultsfile = "$datadir/firmware_hetero.txt";

# Get the split argument
my $splitperiod = "";
if (0 == $#ARGV) {
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
    print "Must split by months ('0m' to '12m') or days ('0d' to '99d')\n";
    exit 1;
}

open(fh,"$firmwarefile") or die("Could not open $firmwarefile");
open(fh2,">$resultsfile") or die("Could not open $resultsfile");

print fh2 "StampName Period NumFirmware NormalizedNumFirmware FirmwareEntropy"
        ." NormalizedFirmwareEntropy NumKnownDevices NumKnownVendors"
        ." NumKnownModels\n";

my $laststamp = "";
my $lastdev = "";
my %deviceAppeared;
my $earliestTime = 0;
my $latestTime = 0;
my %versionsOverTime;
my %binsOverTime;
my %deviceVendor;
my %deviceModel;

while (<fh>) {
    my $data = $_;
    chomp $data;
    $data =~ s/://g;
    my @cols = split(" ", $data);

    my $stampname = $cols[0];
    my $devname = $cols[1];
    my $vendor = $cols[2];
    my $model = $cols[3];
    my $date = $cols[4];
    my $time = $cols[5];
    my $epochTime = $cols[6];
    my $version = $cols[7];
    # Rest of columns are bins
    my $bins = {};
    for (my $i=8; $i < scalar(@cols); $i++) {
        $bins->{$cols[$i]}++;
    }

    if ($stampname ne $laststamp) {
        if ($laststamp ne "") {
        # Get first period
        my $year;
        my $month;
        my $day;
        my $hour;
        my $min;
        my $sec;
        my $doy;
        my $dow;
        my $dst;
        my $epochTime; 
        my $datestamp = "";
        if (($monthsplit <= 0) and ($daysplit <= 0)) {
            $epochTime = $latestTime;
        }
        else {
            $epochTime = $earliestTime;
        }
        ($year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst) =  
                Gmtime($epochTime);
        if ($monthsplit >= 1) {
            $month -= ($month - 1) % $monthsplit;
            $epochTime = Mktime($year, $month, $day, 0, 0, 0);
            $datestamp = sprintf("%04d-%02d", $year, $month);
        }
        elsif($daysplit >= 1) {
            $doy -= ($doy - 1) % $daysplit;
            ($year,$month,$day) = Add_Delta_Days($year, 1, 1, $doy - 1);
            $epochTime = Mktime($year, $month, $day, 0, 0, 0);
            $datestamp = sprintf("%04d-%03d", $year, $doy);
        }
        else {
            $datestamp = "all";
        }

        # Get a list of all epochTimes and datestamps
        my @datestamps;
        my @epochTimes;
        while ($epochTime <= $latestTime) {
            push(@datestamps, $datestamp);
            push(@epochTimes, $epochTime);

            # Get next period
            if ($monthsplit >= 1) {
                ($year, $month, $day) = Add_Delta_YM($year, $month, $day, 0, 
                        $monthsplit);
                $epochTime = Mktime($year, $month, $day, 0, 0, 0);
                $datestamp = sprintf("%04d-%02d", $year, $month);
            }
            elsif($daysplit >= 1) {
                ($year, $month, $day) = Add_Delta_Days($year, $month, $day, 
                        $daysplit);
                $epochTime = Mktime($year, $month, $day, 0, 0, 0);
                $doy = Day_of_Year($year, $month, $day);
                $datestamp = sprintf("%04d-%03d", $year, $doy);
            }
            else {
                last;
            }
        }


        # Determine version for each device for each period
        my %versionsOverPeriods;
        my %binsOverPeriods;
        my %devicesOverPeriods;
        foreach my $devname (sort(keys %deviceAppeared)) {
            my @versionTimes = sort(keys %{$versionsOverTime{$devname}});
            my $timeIndex = scalar(@versionTimes) - 1;
            my $periodIndex = scalar(@epochTimes) - 1;
            while ($timeIndex >= 0) {
                $epochTime = $versionTimes[$timeIndex];
                while (($periodIndex > 0) 
                        and ($epochTimes[$periodIndex] > $epochTime)) {
                    $datestamp = $datestamps[$periodIndex];
                    $versionsOverPeriods{$devname}{$datestamp} = 
                            $versionsOverTime{$devname}{$epochTime};
                    $binsOverPeriods{$devname}{$datestamp} = 
                            $binsOverTime{$devname}{$epochTime};
                    $devicesOverPeriods{$devname}{$datestamp} = 1;
                    $periodIndex--;
                }

                $datestamp = $datestamps[$periodIndex];
                $versionsOverPeriods{$devname}{$datestamp} = 
                        $versionsOverTime{$devname}{$epochTime};
                $binsOverPeriods{$devname}{$datestamp} = 
                        $binsOverTime{$devname}{$epochTime};
                $devicesOverPeriods{$devname}{$datestamp} = 1;

                $timeIndex--;
                while (($timeIndex >= 0) and 
                      ($versionTimes[$timeIndex] > $epochTimes[$periodIndex])) {
                    $epochTime = $versionTimes[$timeIndex];
                    $timeIndex--;
                }
                $periodIndex--;
            }
        }

        # Output data for each period
        foreach $datestamp (@datestamps) {
            my $numdevs = 0;
            my %versionseen;
            my %modelseen;
            my %binseen;
            my %devsperversionmodel;
            my %vendorseen;

            foreach my $devname (sort(keys %devicesOverPeriods)) {
                my $model = $deviceModel{$devname};
                my $vendor = $deviceVendor{$devname};
                if (exists $devicesOverPeriods{$devname}{$datestamp}) {
                    $numdevs++;
                    my $version = $versionsOverPeriods{$devname}{$datestamp};
                    my $bins = $binsOverPeriods{$devname}{$datestamp};
                    $versionseen{"$version"}++;
                    $devsperversionmodel{"$version-$model"}++;
                    $vendorseen{$vendor}++;
                    $modelseen{$model}++;
                    for my $bin (keys %{$bins}) {
                        $binseen{$bin}++;
                    }
                }
            }

            my $modelcount = keys %modelseen;
            my $versioncount = keys %versionseen;
            my $vendorcount = keys %vendorseen;
            if (0 == $vendorcount) {
                print "$laststamp $versioncount ";
            }
            my $normcount = $versioncount/$vendorcount;
            print fh2 "$laststamp $datestamp $versioncount $normcount ";

            # Calculate version-model entropy
            if ($numdevs > 0) {
                my $entropy = 0;
                my $p = 0;

                foreach my $versionmodel (keys %devsperversionmodel) {
                    $p = $devsperversionmodel{$versionmodel}/$numdevs;
                    if (($p == 0) or ($p > 1)) {
                        die("Unable to calculate version-model entropy");
                    }
                    my $f = (log $p)/(log 2);
                    my $incr = (-1 * $p * $f);
                    $entropy += $incr;
                }
                my $normentropy = $entropy;
                if ($numdevs > 1) {
                    $normentropy = $entropy / ((log $numdevs)/(log 2));
                }
                print fh2 "$entropy $normentropy ";
            }
            else {
                print fh2 "0 0 ";
            }
            print fh2 "$numdevs $vendorcount $modelcount\n";
        }
        }

        undef %deviceAppeared;
        $earliestTime = 0;
        $latestTime = 0;
        undef %versionsOverTime;
        undef %binsOverTime;
        undef %deviceVendor;
        undef %deviceModel;
        $laststamp = $stampname;
        $lastdev = "";
    }

    if ($devname ne $lastdev) {
        $deviceVendor{$devname} = $vendor;
        $deviceModel{$devname} = $model;
        $deviceAppeared{$devname} = $epochTime;
        if (($earliestTime <= 0) or ($epochTime < $earliestTime)) {
            $earliestTime = $epochTime;
        }
    }

    if ($epochTime > $latestTime) {
        $latestTime = $epochTime; 
    }
        
    $versionsOverTime{$devname}{$epochTime} = $version;
    $binsOverTime{$devname}{$epochTime} = $bins;
}
close(fh);
close(fh2);
