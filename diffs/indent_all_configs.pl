#!/usr/bin/perl

use strict;

# Get data directory
(exists $ENV{'MGMTPLANE_DATA'}) or
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = $ENV{'MGMTPLANE_DATA'};
my $uncompdir = "$datadir/uncompcfgs";
my $devsfile = "$datadir/devices.txt";

(exists $ENV{'MGMTPLANE_CODE'}) or
    die("Set the MGMTPLANE_CODE environment variable");
my $codedir = $ENV{'MGMTPLANE_CODE'};

# Read device details
open dfh, "$devsfile" or die("ERROR: Could not open $devsfile");
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

opendir(D, $uncompdir) or die("Could not open $uncompdir");
my @stamps = readdir(D);
closedir(D);

foreach my $stamp (sort(@stamps)) {
    if (($stamp =~ /^\.$/) or ($stamp =~ /^\.\.$/)) {
        next;
    }

    print "processing $stamp\n"; 
    my $stampdir = "$uncompdir/$stamp";
    opendir(D, $stampdir) or die("Could not open $stampdir");
    my @devs = readdir(D);
    closedir(D);
    foreach my $device (sort(@devs)) {
        if (($device =~ /^\.$/) or ($device =~ /^\.\.$/)) {
            next;
        }

        my $devicedir = "$stampdir/$device";

        my $vendor = "unknown";
        if (exists $devices{$stamp}->{$device}) {
            $vendor = $devices{$stamp}->{$device}->{vendor};
        }

        my $role = "unknown";
        if (exists $devices{$stamp}->{$device}) {
            $role = $devices{$stamp}->{$device}->{role};
        }

        print "processing $device ($vendor)\n"; 
#        if ($vendor ne "Quanta") {
        if (not ($vendor eq "Juniper" and $role eq "Firewall")) {
            print "Not indenting $vendor $role configs\n";
            next;
        }

        opendir(D, $devicedir) or die("Could not open $devicedir");
        my @cfgs = readdir(D);
        closedir(D);
        foreach my $cfg (sort(@cfgs)) {
            if (($cfg =~ /^\.$/) or ($cfg =~ /^\.\.$/) or !($cfg =~ /\.cfg$/)) {
                next;
            }
            print "running $codedir/diffs/indent_config.pl"
                    ." $cfg $stamp $device $vendor $role\n";
            system("perl $codedir/diffs/indent_config.pl"
                    ." $cfg $stamp $device $vendor $role");
        }
    }
}

