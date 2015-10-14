#!/usr/bin/perl

# PURPOSE: Determine when devices' firmware changes and which version of
# firmware is used.

# PREREQUSITES: MGMTPLANE_CODE/extract/device_hardware.pl has been run.

# OUTPUT: 
# firmware.txt, contains the following for each firmware change:
# - stamp name
# - device name
# - vendor
# - model
# - date firmware changed
# - time firmware changed
# - time since the epoch when the firmware changed
# - firmware version in latest config file
# - firmware file(s) in latest config file

use strict;
use Date::Calc qw(Mktime);

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or 
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $uncompdir = "$datadir/uncompcfgs";
my $devsfile = "$datadir/devices.txt";
my $resultsfile = "$datadir/firmware.txt";

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
shift @stamps;
shift @stamps;
closedir(D);

open(fh,">$resultsfile") or die("Could not open $resultsfile");

# Process each stamp
foreach my $stamp (sort(@stamps)) {
    if (($stamp =~ /^\.$/) or ($stamp =~ /^\.\.$/)) {
	    next;
    }

    # Get list of devices
    my $stampdir = "$uncompdir/$stamp";
    opendir(D, $stampdir) or die("ERROR: Could not open $stampdir");
    my @devs = readdir(D);
    closedir(D);

    # Process each device
    foreach my $fd (@devs) {
        if (($fd =~ /^\.$/) or ($fd =~ /^\.\.$/)) {
            next;
        }

        my $role = $devices{$stamp}->{$fd}->{role};
        my $model = $devices{$stamp}->{$fd}->{model};
        my $vendor = $devices{$stamp}->{$fd}->{vendor};

        # Get list of configs
        my $devdir = "$stampdir/$fd";
        opendir(D, $devdir) or die("ERROR: Could not open $devdir");
        my @cfgs = readdir(D);
        closedir(D);

        my $lastFirmware = "";

        # Process each config
        foreach my $cfg (sort(@cfgs)) {
            if (($cfg =~ /^\.$/) or ($cfg =~ /^\.\.$/) 
                    or ($cfg =~ /^metadata.txt$/)) {
                next;
            }

            $cfg =~ m/^(\d+)\-(\d+)\-(\d+)\-(\d+)\-(\d+)\-(\d+).cfg$/;
            my $year = $1;
            my $month = $2;
            my $day = $3;
            my $hour = $4;
            my $minute = $5;
            my $second = $6;
            my $datestamp = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, 
                    $month, $day, $hour, $minute, $second);
            my $epochTime = Mktime($year, $month, $day, $hour, $minute,$second);
        
            my $cfgfile = "$devdir/$cfg";
            my $version = "UnknownVersion";
            my $bins = {};

            # Look for Cisco config syntax
            if ($vendor eq "Cisco") {
                my $cfglines = `grep "^version" $cfgfile`;
                my @lines = split(/\n/,$cfglines);
                if (scalar(@lines) > 0) {
                    chomp($lines[0]);
                    my @parts = split(/ /,$lines[0]);
                    $version = $parts[1];
                }
                
                my $cfglines = `grep "boot system" $cfgfile`;
                my @lines = split(/\n/,$cfglines);
                foreach my $line (@lines) {
                    chomp($line);
#                    print "\t$line\n";
                    if ($line =~ m/:\/?([^:]+\.bin)/) {
                        my $bin = $1;
#                        print "\t\t$bin\n";
                        $bins->{$bin}++;
                    }
                }
            }
            # Look for Juniper config syntax
            elsif ($vendor eq "Juniper") {
                my $cfglines = `grep "^version" $cfgfile`;
                my @lines = split(/\n/,$cfglines);
                if (scalar(@lines) > 0) {
                    chomp($lines[0]);
                    $lines[0] =~ s/;$//;
                    my @parts = split(/ /,$lines[0]);
                    $version = $parts[1];
                }

#                my $cfglines = `grep "firmware" $cfgfile`;
#                my @lines = split(/\n/,$cfglines);
#                foreach my $line (@lines) {
#                    chomp($line);
#                    print "\t$line\n";
#                    if ($line =~ m/:([^:]+\.bin)$/) {
#                        my $bin = $1;
#                       print "\t\t$bin\n";
#                        $bins{$bin}++;
#                    }
#                }
            }
            # Look for Arista config syntax
            elsif ($vendor eq "Arista") {
                my $cfglines = `grep "^! device:" $cfgfile`;
                my @lines = split(/\n/,$cfglines);
                if (scalar(@lines) > 0) {
                    chomp($lines[0]);
                    my @parts = split(/,/,$lines[0]);
                    $version = $parts[1];
                    $version =~ s/\s|\)//g;
                }

                my $cfglines = `grep "^! boot system" $cfgfile`;
                my @lines = split(/\n/,$cfglines);
                foreach my $line (@lines) {
                    chomp($line);
                    if ($line =~ m/:\/?([^:]+\.swi)/) {
                        my $bin = $1;
                        $bins->{$bin}++;
                    }
                }
            }
            # Look for Quanta config syntax
            elsif ($vendor eq "Quanta") {
                my $cfglines = `grep "!System Software Version" $cfgfile`;
                my @lines = split(/\n/,$cfglines);
                if (scalar(@lines) > 0) {
                    chomp($lines[0]);
                    $lines[0] =~ s/\"//g;
                    my @parts = split(/ /,$lines[0]);
                    $version = $parts[3];
                }
            }
            # Look for F5 config syntax
            elsif ($vendor eq "F5") {
                my $cfglines = `egrep "(sys software)|(default-boot-location)|(version)|(build)" $cfgfile`;
#                print "$cfgfile $vendor $role\n";
                if ($cfglines ne "") {
                    my @lines = split(/\n/,$cfglines);
                    my $iso = "";
                    my $vol = "";
                    my $defaultvol = "";
                    my %isos;
                    my %volbuild;
                    my %volbasebuild;
                    foreach my $line (@lines) {
                        chomp($line);
                        if ($line =~ m/^sys software (image|hotfix) ([^ ]+\.iso)/) {
                            $iso = $2;
                            $vol = "";
                        }
                        elsif ($line =~ m/^sys software volume ([^\s]+)\s/) {
                            $vol = $1;
                            $iso = "";
                        }
                        elsif ($line =~ m/^\s+build\s(\d+\.\d+)/) {
                            my $build = $1;
                            if ($iso ne "") {
                                $isos{$build} = $iso;
#                                print "\timage $iso build $build\n";
                            }
                            elsif ($vol ne "") {
                                $volbuild{$vol} = $build;
#                                print "\tvol $vol build $build\n";
                            }
                        }
                        elsif ($line =~ m/^\s+basebuild\s(\d+\.\d+)/) {
                            my $basebuild = $1;
                            if ($vol ne "") {
                                $volbasebuild{$vol} = $basebuild;
#                                print "\tvol $vol basebuild $basebuild\n";
                            }
                        }

                        elsif ($line =~ m/default-boot-location/) {
                            if ($vol ne "") {
                                $defaultvol = $vol;
#                                print "\tdefault-vol $vol\n";
                            }
                        }
                    }

                    if ($defaultvol ne "") {
                        $version = $volbuild{$defaultvol};
                        my $hotfix = $isos{$version};
                        $bins->{$hotfix}++;
                        my $image = $isos{$volbasebuild{$defaultvol}}++;
                        $bins->{$image}++;
#                        print "\tversion $version base $image hotfix $hotfix\n";
                    }
                }
            }
            # Look for Citrix config syntax
            elsif ($vendor eq "Citrix") {
            }
            else {
                print "$cfgfile\tUnhandled $vendor\n";
            }

            if ($version eq "UnknownVersion") {
                print "$cfgfile\tNoVersion $vendor $role\n"; 
                $version = "$vendor$version";
            }
            if (0 == (keys %{$bins})) {
                $bins->{$vendor."UnknownBinary"} = 1;
            }

#            $numdevs++;
#            $versionseen{"$version"}++;
#            $devsperversionmodel{"$version-$model"}++;
#
#            for my $bin (keys %bins) {
#                $binseen{$bin}++;
#            }

            my $curFirmware = "$version ".join(" ",(sort(keys %{$bins})));
            if ($curFirmware ne $lastFirmware) {
                print fh "$stamp $fd $vendor $model $datestamp $epochTime"
                        ." $version ", join(" ",(keys %{$bins})), "\n";
            }
            $lastFirmware = $curFirmware;
        }
    }
}
close(fh);
