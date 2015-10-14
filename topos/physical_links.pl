#!/usr/bin/perl

use strict;

# PREREQUSITES: MGMTPLANE_CODE/extract/device_hardware.pl has been run.

# OUTPUT:
# links.txt, contains the following for each unidirectional link between a pair
# of devices:
# - stamp name
# - first device
# - second device

each stamp and a column for every role
# that might be in the network; a cell has a value of one if the corresponding
# role exists in the corresponding stamp

# Get data directory
my $datadir = $ENV{'MGMTPLANE_DATA'};
my $uncompdir = "$datadir/uncompcfgs";
my $devsfile = "$datadir/devices.txt";
my $linksfile = "$datadir/links.txt";

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

open lfh, ">$linksfile" or die("Could not open $linksfile");

# Get network names
opendir(D, $uncompdir) or die("Could not open $uncompdir");
my @stamps = readdir(D);
closedir(D);

# Process each network
foreach my $stamp (sort(@stamps)) {
    if (($stamp =~ /^\.$/) or ($stamp =~ /^\.\.$/)) {
        next;
    }
    print "processing $stampdir\n"; 
    my $stampdir = "$uncompdir/$stamp";

    # Get device names
    opendir(D, $stampdir) or die("Could not open $stampdir");
    my @devs = readdir(D);
    closedir(D);

    # Process each device
    foreach my $devname (sort(@devs)) {
        if (($devname =~ /^\.$/) or ($devname =~ /^\.\.$/)) {
            next;
        }
        my $devdir = "$stampdir/$devname";

        my $vendor = "unknown";
        if (exists $devices{$stamp}->{$devname}) {
            $vendor = $devices{$stamp}->{$devname}->{vendor};
        }

        my $role = "unknown";
        if (exists $devices{$stamp}->{$devname}) {
            $role = $devices{$stamp}->{$devname}->{role};
        }

        if (($vendor eq "F5") or 
                ($vendor eq "Juniper" and $role eq "Firewall")) {
            print "Skip $vendor $role $stamp/$devname\n";
            next;
        }

        # Get list of configs
        opendir(D, $devdir) or die("Could not open $devdir");
        my @cfgs = sort(readdir(D));
        closedir(D);

        # Get last config
        my $lastcfg = $cfgs[scalar(@cfgs)-2];
        print "$vendor $role $stamp/$devname/$lastcfg\n"; 

        # Get interface descriptions
        my $matches = `egrep "(^interfaces? )|(^ +description )|(^})" $uncompdir/$stamp/$devname/$lastcfg`;
        chomp $matches;
        my @lines = split/\n/,$matches;
#        print "$matches\n";
        my %neighbors;

        # Parse interface descriptions
        my $iface = "";
        for my $line (@lines) {
            if ($line =~ m/^interfaces? (.+)$/) {
                $iface = $1;
            } elsif ($line =~ m/^ +description ([^ ]+).*$/) {
                if ($iface eq "") {
#                    print "Description without matching interface\n";
                    next;
                }
            
                my $descrip = lc $1;
#                print "$iface $descrip\n";
#                print "$descrip\n";
                if ($descrip =~ m/:(([a-z0-9]+-)([a-z0-9]+-)+[a-z0-9]+):/) {
                    my $neighbor = $1;
#                    print "\t $neighbor\n";
                    $neighbors{$neighbor}++;
                }
            } else {
                $iface = "";
            }
        }

        # Output links
        for my $neighbor (sort(keys %neighbors)) {
            if ($devname ne $neighbor) {
                print lfh "$stamp $devname $neighbor\n";
            }
        }
    }
}
close(lfh);
