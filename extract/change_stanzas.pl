#!/usr/bin/perl

# PURPOSE: Computes statistics about stanza changes.

# PREREQUSITES: MGMTPLANE_CODE/diffs/process_all_diffs.pl and 
# MGMTPLANE_CODE/extract/device_hardware.pl have been run.

# OUTPUT:
# change_stanzas.txt, contains the following for each stamp for each period:
# - stamp name
# - period
# - most frequent stanza type changed (based on total number of times an
#   instance of given type is changed)
# - second most frequent stanza type changed (based on total number of times an
#   instance of given type is changed)
# - most frequest stanza type changed (based on number of events where
#   stanza of given type is changed)
# - second most frequest stanza type changed (based on number of events where
#   stanza of given type is changed)
# - number of changes that involve adding/removing/modifying a particular 
#   stanza type
# - number of changes that are automated and involve adding/removing/modifying
#   a particular stanza type
# - fraction of change events that involve adding/removing/modifying a 
#   particular stanza type
# - average number of days between change events that involve 
#   adding/removing/modifying a particular stanza type
#
# change_events.txt, contains the following for each change event:
# - stamp name
# - period
# - change event timestamp
# - names of devices changed (comma-seperated list)
# - types of stanzas changed (comma-separated list)
# - nature of changes (hyphen-separated list)
# - role of changed devices (hyphen-separated list)
# - number of individual device changes in the change event
#
# stanza_nature.txt, contains the following for each stamp for each stanza:
# - stamp name
# - stanza type
# - number of instances of the stanza type that are changed automatically
# - number of instances of the stanza type that are changed manually
# - fraction of the changes to instances of the stanza type that are automatic

use strict;
use Date::Calc qw(Day_of_Year Mktime Days_in_Month);

my @interestingActions = ("interface", "vlan", "router", "acl", "pool", "user");

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $diffsdir = "$datadir/diffs";
my $rolesfile = "$datadir/env_roles.txt";
my $hardwarefile = "$datadir/hardware.txt";
my $devsfile = "$datadir/devices.txt";
my $stanzasfile = "$datadir/change_stanzas.txt";
my $eventsfile = "$datadir/change_events.txt";
my $stanzanaturefile = "$datadir/stanza_nature.txt";

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
my %haslb;
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
        $haslb{$stamp} = 0;
    }
    
    if ($allRoles{$role} eq "mbox") {
        $hasmbox{$stamp}++;
    }
    if ($role eq "LoadBalancer") { #FIXME: make independent
        $haslb{$stamp}++;
    }
}
close dfh;

# Read stamp details
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

open sfh, ">$stanzasfile" or die("Could not open $stanzasfile");
open nfh, ">$stanzanaturefile" or die("Could not open $stanzanaturefile");
open efh, ">$eventsfile" or die("Could not open $eventsfile");

# Output file headers
print sfh "StampName Period"
    ." RawFirstPlaceChangeAction RawSecondPlaceChangeAction"
    ." FirstPlaceChangeAction SecondPlaceChangeAction";
for my $action (@interestingActions) {
    print sfh " RawStanza".ucfirst($action)."Changes"
            ." RawAutoStanza".ucfirst($action)."Changes"
            ." FractionStanza".ucfirst($action)."Change"
            ." RateStanza".ucfirst($action)."Change";
}
print sfh "\n";
print nfh "StampName Stanza RawAutoStanzaChanges RawUnknStanzaChanges"
        ." FracAutoStanzaChanges\n";
print efh "StampName Period ChangeTimestamp DevicesChanged StanzasChanged"
        ." RawNatures RolesChanged NumRawChanges\n";

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
    my %devschanged;
    my %stanzas;
    my %stanzasAuto;
    my $maxabstime;
    my $minabstime;
    my %stanzaNature;

    # Get list of devices
    opendir(D, "$diffsdir/$stamp") or die("Could not open $diffsdir/$stamp");
    my @devs = readdir(D);
    closedir(D);

    # Process each device
    foreach my $fd (sort(@devs)) {
        if (($fd =~ /^\.$/) or ($fd =~ /^\.\.$/)) {
            next;
        }

        print "Processing device: $stamp/$fd\n"; 

        my $devdir = "$diffsdir/$stamp/$fd";

        opendir(D, $devdir) or die("Could not open $devdir");
        my @typefiles = readdir(D);
        closedir(D);

        # Process each type file
        foreach my $tf (sort(@typefiles)) {
            if (($tf =~ /^\.$/) or ($tf =~ /^\.\.$/)) {
                next;
            }
            if ($tf =~ /.*-(20..)-(..)-(..)-(..)-(..)-(..)-(auto|unkn)\.types$/){
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
                if (exists($devices{$stamp}->{$fd})) {
                    $role = $devices{$stamp}->{$fd}->{role};
                }

                if (!exists($sawchangeat{$changets})) {
                    $sawchangeat{$changets} = 0;
                    $nature{$changets} = $nature;
                    $roles{$changets} = $role;
                    $stanzas{$changets} = {};
                    $devschanged{$changets} = {};
                } else {
                    $nature{$changets} = $nature{$changets}."-".$nature;
                    $roles{$changets} = $roles{$changets}."-".$role;
                }
                $sawchangeat{$changets}++;
                $devschanged{$changets}->{$fd}++;

                open fh, "$devdir/$tf" or die("Could not open $devdir/$tf");
                my %changeStanzas;
                while(<fh>) {
                    chomp $_;
                    my @cols = split(" ", $_);
                    my $stanza = $cols[0];

                    # Clean-up from heuristic that figures out what is a 
                    # command and what is a parameter in a config line
                    $stanza =~ s/^hostname_.+$/hostname/;
                    $stanza =~ s/^monitor_.+$/monitor/;
                    $stanza =~ s/^policy-map_.+$/policy-map/;
                    $stanza =~ s/^pool_.+$/pool/;
                    $stanza =~ s/^snatpool_.+$/snatpool/;
                    $stanza =~ s/^virtual_.+$/virtual/;
                    $stanza =~ s/^vdc_.+$/vdc/;
                    $stanza =~ s/^username_.+$/username/;
                    $stanza =~ s/^user_.+$/user/;
                    $stanza =~ s/^interface_cmp-mgmt$/interface/;
                    $stanza =~ s/^interface_mgmt$/interface/;
                    $stanza =~ s/^line_con$/line_console/;
                    $stanza =~ s/^class-map_.+$/class-map/;

                    # Heuristic to combine some things within a vendor
                    $stanza =~ s/^((ltm_pool)|(gtm_pool))$/pool/; # F5
                    $stanza =~ s/^stp_instance$/net_stp/; # F5 upgrade to v10.2.1 syntax
                    $stanza =~ s/^stp$/net_stp-globals/; # F5 upgrade to v10.2.1 syntax

                    # Heuristic to make some things vendor-independent
                    $stanza =~ s/^((interfaces)|(net_interface))$/interface/; # Juniper, F5 -> Cisco
                    $stanza =~ s/^routing-instances$/router/; # Juniper -> Cisco
                    $stanza =~ s/^router_.+$/router/;
                    $stanza =~ s/^((feature_sflow)|(sflow(_.+)?))$/sflow/; # Juniper -> Cisco
                    $stanza =~ s/^((firewall_filter)|(ip_access-list)|(access-list))$/acl/; # Juniper, Cisco, Cisco -> Generic
                    $stanza =~ s/^((firewall_policer)|(policy-map))$/shaping/; # Juniper, Cisco -> Generic
                    $stanza =~ s/^((policy-options_prefix-list)|(ip_prefix-list))$/prefix-list/; # Juniper, Cisco -> Generic
                    $stanza =~ s/^((system_ntp)|(ntp_.+))$/ntp/; # Juniper, Cisco -> Generic
                    $stanza =~ s/^((system_name-server)|(ip_name-server))$/name-server/; # Juniper, Cisco -> Generic
                    $stanza =~ s/^((system_domain-name)|(ip_domain-name))$/domain-name/; # Juniper, Cisco -> Generic
                    $stanza =~ s/^system_hostname$/hostname/; # Juniper -> Cisco
                    $stanza =~ s/^((system_login)|(username)|(password))$/user/; # Juniper, Cisco, Cisco, Cisco, Cisco -> Generic

                    $changeStanzas{$stanza}++;
                }
                close fh;
                for my $stanza (sort(keys %changeStanzas)) {
                    $stanzas{$changets}->{$stanza}++;
                    if ($nature eq "auto") {
                        $stanzasAuto{$changets}->{$stanza}++;
                    }
                    $stanzaNature{$stanza}{$nature}++;
                }
            }
        }
    }

    # Output each stanza nature for stamp
    foreach my $stanza (sort(keys %stanzaNature)) {
        my $autoCnt = $stanzaNature{$stanza}{auto} + 0;
        my $unknCnt = $stanzaNature{$stanza}{unkn} + 0;
        my $fracAuto = $autoCnt/($autoCnt+$unknCnt);
        print nfh "$stamp $stanza $autoCnt $unknCnt $fracAuto\n";
    }

    my %numChangesPerPeriod;
    my %rawActionCntPerPeriod;
    my %rawAutoActionCntPerPeriod;
    my %actionCntPerPeriod;

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

        # Output change event
        my $dvs = join(",",sort(keys %{$devschanged{$changets}}));
        my $stnzs = join(",",sort(keys %{$stanzas{$changets}}));
        my $changecnt  = $sawchangeat{$changets};
        print efh "$stamp $periodts $changets $dvs $stnzs $nature{$changets}"
                ." $roles{$changets} $changecnt\n";
        
#        # Ignore anything that just as an ntp_clock-period time change
#        if ($stnzs =~ m/^ntp$/) {
#            next;
#        }

        $numChangesPerPeriod{$periodts}++;

        # Handle actions
        for my $action (sort(keys %{$stanzas{$changets}})) {
             $rawActionCntPerPeriod{$periodts}{$action} +=
                    $stanzas{$changets}->{$action};
             $rawAutoActionCntPerPeriod{$periodts}{$action} += 
                    $stanzasAuto{$changets}->{$action};
             $actionCntPerPeriod{$periodts}{$action}++;
        }
    }

    # Process each period
    foreach my $periodts (sort(keys %numChangesPerPeriod)) {
        my $numChanges = $numChangesPerPeriod{$periodts}; # KEEP
        print sfh "$stamp $periodts";

        my $timespan = $monthsplit * 30 + $daysplit;
        if ($monthsplit <= 0 and $daysplit <= 0) {
            $timespan = $maxabstime - $minabstime;
        }
        
        # Determine first and second place actions based on number of events
        # with the action; determine raw first and raw second place actions
        # based on number of times the action occurred
        my $firstAction = "none";
        my $firstCount = -1;
        my $secondAction = "none";
        my $secondCount = -1;
        my $firstRawAction = "none";
        my $firstRawCount = -1;
        my $secondRawAction = "none";
        my $secondRawCount = -1;
        for my $action (sort(keys $actionCntPerPeriod{$periodts})) {
#            if ($action =~ m/^ntp$/) {
#                next;
#            }

            # Update first and second place actions based on number of events 
            # with action
            if ($actionCntPerPeriod{$periodts}{$action} > $firstCount) {
                $secondAction = $firstAction;
                $secondCount = $firstCount;
                $firstAction = $action;
                $firstCount = $actionCntPerPeriod{$periodts}{$action};
            } elsif ($actionCntPerPeriod{$periodts}{$action} > $secondCount) {
                $secondAction = $action;
                $secondCount = $actionCntPerPeriod{$periodts}{$action};
            }

            # Update raw first and raw second place actions based on number of 
            # times the action occurred
            if ($rawActionCntPerPeriod{$periodts}{$action} > $firstRawCount) {
                $secondRawAction = $firstRawAction;
                $secondRawCount = $firstRawCount;
                $firstRawAction = $action;
                $firstRawCount = $rawActionCntPerPeriod{$periodts}{$action};
            } elsif ($rawActionCntPerPeriod{$periodts}{$action} > $secondRawCount) {
                $secondRawAction = $action;
                $secondRawCount = $rawActionCntPerPeriod{$periodts}{$action};
            }

        }
        print sfh " $firstRawAction $secondRawAction";
        print sfh " $firstAction $secondAction";

        # Output statistics for interesting actions
        for my $action (@interestingActions) {
            my $fracaction = -1;
            if ($numChanges > 0) {
                $fracaction=$actionCntPerPeriod{$periodts}{$action}/$numChanges;
                if ((0 == $haslb{$stamp}) and ($action eq "pool")) {
                    $fracaction = -1;
                }
            }
            my $rateaction = -1;
            if ($timespan > 0) {
                $rateaction = $actionCntPerPeriod{$periodts}{$action}/$timespan;
            }
            my $rawCnt = $rawActionCntPerPeriod{$periodts}{$action} + 0;
            my $rawAutoCnt = $rawAutoActionCntPerPeriod{$periodts}{$action} + 0;
            print sfh " $rawCnt $rawAutoCnt";
            print sfh " $fracaction $rateaction";
        }

        print sfh "\n";
    }
}
close sfh;
close nfh;
close efh;
