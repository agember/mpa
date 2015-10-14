#!/usr/bin/perl

# PURPOSE: Computes multiple frequency-related statistics for configuration
# changes, including: how many changes, what fraction of devices are changed,
# what fraction of changes are automated, how frequently to changes occur, etc.

# PREREQUSITES: MGMTPLANE_CODE/diffs/diff_configs.pl and 
# MGMTPLANE_CODE/extract/device_hardware.pl have been run.

# OUTPUT:
# change_frequency.txt, contains the following for each stamp for each period:
# - stamp name
# - period
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

use strict;
use Date::Calc qw(Day_of_Year Mktime Days_in_Month);

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $diffsdir = "$datadir/diffs";
my $rolesfile = "$datadir/env_roles.txt";
my $hardwarefile = "$datadir/hardware.txt";
my $devsfile = "$datadir/devices.txt";
my $freqfile = "$datadir/change_frequency.txt";

# Get window argument
my $window = 5 * 60;
my $splitperiod = "";
if ($#ARGV >= 0) {
    $window = $ARGV[0];
    print "Using window size ", ($window/60), " minutes\n";
}
else {
    print "Using default window size = ", ($window/60), " minutes\n";
}

# Get the split argument
if ($#ARGV >= 1) {
    $splitperiod = $ARGV[1];
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
if ($#ARGV >= 3) {
    $mindate = $ARGV[2];
    $maxdate = $ARGV[3];
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

# Read roles list
open rfh, "$rolesfile" or die("Could not open $rolesfile");
my %allRoles = ();
while(<rfh>) {
    chomp $_;
    my @cols = split(",", $_);
    $allRoles{@cols[0]} = @cols[1];
}
close dfh;

# Read device details
open dfh, "$devsfile" or die("Could not open $devsfile");
my %devices;
my %hasmbox;
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

    if (!exists($hasmbox{$stamp})) {
        $hasmbox{$stamp} = 0;
    }
    
    if ($allRoles{$role} eq "mbox") {
        $hasmbox{$stamp}++;
    }
}
close dfh;

# Read hardware details
open hfh, "$hardwarefile" or die("Could not open $hardwarefile");
my %stampsize;
while (<hfh>) {
    chomp;
    s/://g;
    my @s = split " ", $_;
    my $st = $s[0];
    chomp($st);
    $stampsize{$st} = $s[1];
}
close hfh;

open ffh, ">$freqfile" or die("Could not open $freqfile");

# Output file headers
print ffh "StampName Period RawNumChanges RawRateOfChange"
        ." FractionDevicesChanged RawNatureAutoChanges RawNatureUnknownChanges"
        ." FracNatureAutoChanges FracNatureUnknownChanges";
for my $role (sort(keys %allRoles)) {
    print ffh " RawRole${role}Changes";
}
print ffh " NumChanges RateOfChange"
        ." MeanDevicesChanged MeanRolesChanged MeanModelsChanged"
        ." FractionAutoChanges FractionMixedChanges FractionUnknownChanges"
        ." FractionRoleMboxChanges FractionRoleForwardChanges"
        ." FractionRoleMixedChanges";
print ffh "\n";

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

    print "Processing stamp: $stamp\n"; 

    my %sawchangeat;
    my %nature;
    my %roles;
    my %models;
    my %devschanged;
    my %stanzas;
    my %stanzasAuto;
    my $maxabstime;
    my $minabstime;
    my $totdevs;
    my %stanzaNature;

    # Get list of devices
    opendir(D, "$diffsdir/$stamp") or die("Could not open $diffsdir/$stamp");
    my @devs = readdir(D);
    closedir(D);

    # Process each device
    foreach my $dev (sort(@devs)) {
        if (($dev =~ /^\.$/) or ($dev =~ /^\.\.$/)) {
            next;
        }

        $totdevs++;
        print "Processing device: $stamp/$dev\n"; 

        my $devdir = "$diffsdir/$stamp/$dev";

        opendir(D, $devdir) or die("Could not open $devdir");
        my @difffiles = readdir(D);
        closedir(D);

        # Process each diff
        foreach my $df (sort(@difffiles)) {
            if (($df =~ /^\.$/) or ($df =~ /^\.\.$/)) {
                next;
            }
            if ($df =~/.*-(20..)-(..)-(..)-(..)-(..)-(..)-(auto|unkn)\.diff$/){
                my $year = $1;
                my $month = $2;
                my $date = $3;
                my $hour = $4;
                my $minute = $5;
                my $second = $6;
                my $nature = $7;

                # Check if change is within specified date range
                my $time = Mktime($year, $month, $date, 0, 0, 0);
                if (($mintime >= 0 and $time < $mintime) or 
                        ($maxtime >= 0 and $time > $maxtime)) {
                    next;
                }

                # Group change into the appropriate change event
                my $t = ($hour*60 + $minute)*60 + $second;
                my $changetime = int ($t/$window);
                my $abstime = ((($year-2000)*365 + ($month-1)*30 + $date)
                        * 86400 + $t) / 86400;
                if (!defined($maxabstime) or ($abstime > $maxabstime)) {
                    $maxabstime = $abstime;
                }
                if (!defined($minabstime) or ($abstime < $minabstime)) {
                    $minabstime = $abstime;
                }
                if (($t % $window) > $window/2) {
                    $changetime++;
                }
                my $changets = sprintf("%04d-%02d-%02d-%03d", $year, $month,
                        $date, $changetime);
                if (!exists($sawchangeat{$changets})) {
                    my $changebefore = sprintf("%04d-%02d-%02d-%03d", $year,
                            $month, $date, $changetime-1);
                    my $changeafter = sprintf("%04d-%02d-%02d-%03d", $year,
                            $month, $date, $changetime+1);
                    if (exists($sawchangeat{$changebefore})) {
                        $changets = $changebefore;
                    } elsif (exists($sawchangeat{$changeafter})) {
                        $changets = $changeafter;
                    }
                }

                my $role = "unknown";
                if (exists($devices{$stamp}->{$dev})) {
                    $role = $devices{$stamp}->{$dev}->{role};
                }
                my $model = "unknown";
                if (exists($devices{$stamp}->{$dev})) {
                    $model = $devices{$stamp}->{$dev}->{model};
                }

                if (!exists($sawchangeat{$changets})) {
                    $sawchangeat{$changets} = 0;
                    $nature{$changets} = $nature;
                    $roles{$changets} = $role;
                    $models{$changets} = $model;
                    $devschanged{$changets} = {};
                } else {
                    $nature{$changets} = $nature{$changets}."-".$nature;
                    $roles{$changets} = $roles{$changets}."-".$role;
                    $models{$changets} = $models{$changets}.",".$model;
                }
                $sawchangeat{$changets}++;
                $devschanged{$changets}->{$dev}++;
            }
        }
    }

    my %rawChangesPerPeriod;
    my %numChangesPerPeriod;
    my %natureCntPerPeriod;
    my %rawNatureCntPerPeriod;
    my %roleCntPerPeriod;
    my %roleMixCntPerPeriod;
    my %rawRoleCntPerPeriod;
    my %modelCntPerPeriod;
    my %actionCntPerPeriod;
    my %rawActionCntPerPeriod;
    my %rawAutoActionCntPerPeriod;
    my %totdevsChangedPerPeriod;
    my %devsChangedPerPeriod;

    # Process each change timestamp
    foreach my $changets (sort(keys %sawchangeat)) {
        # Determine period
        my $periodts;
        if ($changets =~ m/^(\d+)\-(\d+)\-(\d+)\-(\d+)$/) {
            my $year = $1;
            my $month = $2;
            my $date = $3;

            my $datestamp = "all";
            if ($monthsplit >= 1) {
                my $tmpMonth = $month - (($month - 1) % $monthsplit);
                $datestamp = sprintf("%04d-%02d", $year, $tmpMonth);
            }
            elsif($daysplit >= 1) {
                my $doy = Day_of_Year($year, $month, $date);
                $doy -= ($doy - 1) % $daysplit;
                $datestamp = sprintf("%04d-%03d", $year, $doy);
            }
            $periodts = $datestamp;
        } else {
            die("Invalid date");
        }

        $numChangesPerPeriod{$periodts}++;
        $rawChangesPerPeriod{$periodts} += $sawchangeat{$changets};

        # Handle nature
        my @naturelist = sort(split "-",$nature{$changets});
        for my $nat (@naturelist) {
            $rawNatureCntPerPeriod{$periodts}{$nat}++;
        }
        if ($nature{$changets} =~ m/^auto(-auto)*$/) {
            $nature{$changets} = "auto";
        } elsif ($nature{$changets} =~ m/^unkn(-unkn)*$/) {
            $nature{$changets} = "unkn";
        } else {
            $nature{$changets} = "mixed";
        } 
        if (!exists $natureCntPerPeriod{$periodts}) {
            $natureCntPerPeriod{$periodts}{"auto"} = 0;
            $natureCntPerPeriod{$periodts}{"unkn"} = 0;
            $natureCntPerPeriod{$periodts}{"mixed"} = 0;
        }
        $natureCntPerPeriod{$periodts}{$nature{$changets}}++;

        # Handle role
        my @rolelist = sort(split "-",$roles{$changets});
        my $prevrole = "";
        my $rolemix = "";
        for my $role (@rolelist) {
            $rawRoleCntPerPeriod{$periodts}{$role}++;
            if ($role eq $prevrole) {
                next;
            }

            $roleCntPerPeriod{$periodts}{$role}++;
            $rolemix = $rolemix."-".$allRoles{$role};

            $prevrole = $role;
        }
        if ($rolemix =~ m/^-mbox(-mbox)*$/) {
            $roleMixCntPerPeriod{$periodts}{"mbox"}++;
        } elsif ($rolemix =~ m/^-fwd(-fwd)*$/) {
            $roleMixCntPerPeriod{$periodts}{"fwd"}++;
        } else {
            $roleMixCntPerPeriod{$periodts}{"mixed"}++;
        }

        # Handle model
        my @modellist = sort(split ",",$models{$changets});
        my $prevmodel = "";
        for my $model (@modellist) {
            if ($model eq $prevmodel) {
                next;
            }
            $modelCntPerPeriod{$periodts}{$model}++;
            $prevmodel = $model;
        }

        # Handle devices
        $totdevsChangedPerPeriod{$periodts} += 
                scalar(keys %{$devschanged{$changets}});
        if (!exists $devsChangedPerPeriod{$periodts}) {
            $devsChangedPerPeriod{$periodts} = {};
        }
        for my $dev (keys %{$devschanged{$changets}}) {
            $devsChangedPerPeriod{$periodts}->{$dev}++;
        }
    }

    # Process each period
    foreach my $periodts (sort(keys %numChangesPerPeriod)) {
        my $numChanges = $numChangesPerPeriod{$periodts};
        my $rawChanges = $rawChangesPerPeriod{$periodts};
        print ffh "$stamp $periodts $rawChanges";

        my $rate = -1;
        my $rawRate = -1;
        my $timespan = $monthsplit * 30 + $daysplit;
        if ($monthsplit <= 0 and $daysplit <= 0) {
            $timespan = $maxabstime - $minabstime;
        }
        if ($timespan > 0) {
            $rate = $numChanges/$timespan;
            $rawRate = $rawChanges/$timespan;
        }

        my $fracdevschanged = -1;
        if ($stampsize{$stamp} > 0) {
            $fracdevschanged = scalar(keys %{$devsChangedPerPeriod{$periodts}})
                    / $stampsize{$stamp};
        }
        
        print ffh " $rawRate $fracdevschanged";

        my $rawauto = $rawNatureCntPerPeriod{$periodts}{auto} + 0;
        my $rawunkn = $rawNatureCntPerPeriod{$periodts}{unkn} + 0;

        my $fracauto = -1;
        my $fracunkn = -1;
        if ($rawChanges > 0) {
            $fracauto = $rawauto / $rawChanges;
            $fracunkn = $rawunkn / $rawChanges;
        }

        print ffh " $rawauto $rawunkn $fracauto $fracunkn";

        my $totrolesChanged = 0;
        for my $role (sort(keys %allRoles)) {
            my $rawRoleCnt = $rawRoleCntPerPeriod{$periodts}->{$role} + 0;
            $totrolesChanged += $roleCntPerPeriod{$periodts}{$role};
            print ffh " $rawRoleCnt";
        }
        my $totmodelsChanged = 0;
        for my $model (sort(keys %{$modelCntPerPeriod{$periodts}})) {
            $totmodelsChanged += $modelCntPerPeriod{$periodts}{$model};
        }

        print ffh " $numChanges $rate";

        my $meandevsChanged = -1;
        my $meanrolesChanged = -1;
        my $meanmodelsChanged = -1;
        my $na = -1;
        my $nm = -1;
        my $nu = -1;
        my $rmb = -1;
        my $rfw = -1;
        my $rmx = -1;
        if ($numChanges > 0) {
            $meandevsChanged = $totdevsChangedPerPeriod{$periodts}/$numChanges;
            $meanrolesChanged = $totrolesChanged/$numChanges;
            $meanmodelsChanged = $totmodelsChanged/$numChanges;
            $na = $natureCntPerPeriod{$periodts}{"auto"}/$numChanges;
            $nm = $natureCntPerPeriod{$periodts}{"mixed"}/$numChanges;
            $nu = $natureCntPerPeriod{$periodts}{"unkn"}/$numChanges;
            $rmb = $roleMixCntPerPeriod{$periodts}{"mbox"}/$numChanges;
            if (0 == $hasmbox{$stamp}) {
                $rmb = -1;
            }
            $rfw = $roleMixCntPerPeriod{$periodts}{"fwd"}/$numChanges;
            $rmx = $roleMixCntPerPeriod{$periodts}{"mixed"}/$numChanges;
        }   
        print ffh " $meandevsChanged $meanrolesChanged $meanmodelsChanged"
                ." $na $nm $nu $rmb $rfw $rmx";
    
        print ffh "\n";
    }
}
close ffh;
