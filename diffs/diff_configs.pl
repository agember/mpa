#!/usr/bin/perl

# PURPOSE: Computes the difference between successive configuration snapshots
# for each device and infers whether the differences between the two snapshots
# were due to an automated change 

# PREREQUISITES: MGMTPLANE_DATA/uncompcfgs directory contains configuration
# snapshots for each device (see README for the structure of this directory)

# OUTPUT: MGMTPLANE_DATA/diffs directory contains the output of 'diff' for each
# pair of succesive device configurations for each device in each network; files
# are named using the following format NATURE_ORIGTIMESTAMP_NEWTIMESTAMP.diff
# where NATURE is "auto" or "unkn" (unknown) and ORIGTIMESTAMP and NEWTIMESTAMP
# are the date and time of the original (earlier) and new (later) configuration
# in the format YYYY-MM-DD-HH-MM-SS

use strict;

# Get data directory
my $datadir;
(exists $ENV{'MGMTPLANE_DATA'}) or 
    die("Set the MGMTPLANE_DATA environment variable");
$datadir = $ENV{'MGMTPLANE_DATA'};

my $diffsdir = "$datadir/diffs/";
my $uncompcfgs = "$datadir/uncompcfgs/";
my $autousersfile = "$datadir/env_autousers.txt";

# Read automated users list
open aufh, "$autousersfile" or die("Could not open $autousersfile");
my @autousers = ();
while(<aufh>) {
    chomp $_;
    push @autousers, $_;
}
close dfh;

# Get list of networks
opendir(D, $uncompcfgs) or die("Could not open $uncompcfgs");
my @stamps = readdir(D);
closedir(D);

# Process configurations for each network
foreach my $stamp (sort(@stamps)) {
    if (($stamp =~ /^\.$/) or ($stamp =~ /^\.\.$/)) {
        next;
    }

    # Get list of devices
    opendir(D, "$uncompcfgs/$stamp") or 
        die("Could not open $uncompcfgs/$stamp");
    my @devs = readdir(D);
    #shift @files;
    #shift @files;
    closedir(D);

    # Process configurations for each device
    foreach my $device (sort(@devs)) {
        if (($device =~ /^\.$/) or ($device =~ /^\.\.$/)) {
            next;
        }

        opendir(D,"$uncompcfgs/$stamp/$device");
        my @cfgs = readdir(D);
        closedir(D);
        print "Processing device: $stamp/$device\n"; 
        
        my %time;
        
        `mkdir -p $diffsdir/$stamp/$device`;

        foreach my $cfg (@cfgs) {
            if (($cfg =~ /^\.$/) or ($cfg =~ /^\.\.$/)) {
                next;
            }
            if ($cfg =~ /(20..)-(..)-(..)-(..)-(..)-(..)\.cfg$/) {
                my $year = $1;
                my $month = $2;
                my $date = $3;
                my $hour = $4;
                my $minute = $5;
                my $second = $6;
                my $t = ($hour*60+$minute)*60+$second;
                my $abstime = ((($year - 2000)*365+($month-1)*30+$date)*86400+$t)/86400;
                $time{$cfg} = $abstime;
            }
        }
        
        my $i = 0;
        my $currfile;
        my $prevfile;
        
        foreach my $cfg ( sort {$time{$a} <=> $time{$b}} keys %time ) {
            $i++;
            if ($i > 1) {
                $currfile = $cfg;

                print "Processing $prevfile $currfile\n";
                my $user = `grep "\!User" $uncompcfgs/$stamp/$device/$currfile`;
                my $nature = 'unkn';

                foreach my $autouser (@autousers) {
                    if ($user =~ /$autouser/) {
                        $nature = 'auto';
                        next;
                    }
                }

                my $prevDatetime = $prevfile;
                $prevDatetime =~ s/.cfg//;
                my $currDatetime = $currfile;
                $currDatetime =~ s/.cfg//;

                `diff $uncompcfgs/$stamp/$device/$prevfile $uncompcfgs/$stamp/$device/$currfile > $diffsdir/$stamp/$device/$prevDatetime-$currDatetime-$nature.diff`;
                print "Diff'd $i $prevfile $currfile $nature\n";
            }
            $prevfile = $cfg;
        }
    }
}
