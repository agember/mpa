#!/usr/bin/perl

use Parallel::ForkManager;
use strict;

# Get data directory and files
(exists $ENV{'MGMTPLANE_DATA'}) or
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = $ENV{'MGMTPLANE_DATA'};
my $diffsdir = "$datadir/diffs";
my $uncompdir = "$datadir/uncompcfgs";
my $devsfile = "$datadir/devices.txt";

# Get code directory
(exists $ENV{'MGMTPLANE_CODE'}) or
    die("Set the MGMTPLANE_CODE environment variable");
my $codedir = $ENV{'MGMTPLANE_CODE'};

my $pm = Parallel::ForkManager->new(3);

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

# Get list of stamps
opendir(D, $diffsdir) or die("Could not open $diffsdir");
my @stamps = readdir(D);
closedir(D);

# Process each stamp
foreach my $stamp (sort(@stamps)) {
    if (($stamp =~ /^\.$/) or ($stamp =~ /^\.\.$/)) {
        next;
    }
    print "Processing stamp $stamp\n"; 

    # Get list of devices
    my $stampdir = "$diffsdir/$stamp";
    opendir(D, $stampdir) or die("Could not open $stampdir");
    my @devs = readdir(D);
    closedir(D);

    # Process each device
    foreach my $dev (sort(@devs)) {
        if (($dev =~ /^\.$/) or ($dev =~ /^\.\.$/)) {
            next;
        }

        my $vendor = "unknown";
        if (exists $devices{$stamp}->{$dev}) {
            $vendor = $devices{$stamp}->{$dev}->{vendor};
        }

        my $role = "unknown";
        if (exists $devices{$stamp}->{$dev}) {
            $role = $devices{$stamp}->{$dev}->{role};
        }

        my $devicedir = "$diffsdir/$stamp/$dev";
        print "Processing $vendor configs for device $stamp/$dev\n"; 

        # Get list of config diffs
        opendir(D, $devicedir) or die("Could not open $devicedir");
        my @conffiles = readdir(D);
        closedir(D);

        # Process each config diff
        foreach my $cf (sort(@conffiles)) {
            if (($cf =~ /^\.$/) or ($cf =~ /^\.\.$/) or !($cf =~ /\.diff$/)) {
                next;
            }

            my $pid = $pm->start and next;
            print "Running $codedir/diffs/process_diff.pl $cf $stamp $dev $vendor $role\n";
            system("perl $codedir/diffs/process_diff.pl $cf $stamp $dev $vendor $role");
            $pm->finish; # Terminates the child process
        }
    }
}
$pm->wait_all_children;
