#!/usr/bin/perl

use strict;

open debug, ">/dev/null";
#open debug, ">-";

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $uncompdir = "$datadir/uncompcfgs";

# Get arguments
($#ARGV >= 4) or
    die("Specify the config file, stamp name, device name, vendor, and role");
my $configfile = $ARGV[0];
my $stampname = $ARGV[1];
my $devname = $ARGV[2];
my $vendor = $ARGV[3];
my $role = $ARGV[4];
$configfile = "$uncompdir/$stampname/$devname/$configfile";
my $newconfigfile = "$configfile.indent";

my %supportedvendors = ( 'Quanta' => 1, 'Juniper' => 1 );

if (! exists $supportedvendors{$vendor}) {
    die("Only ".join(",", (keys %supportedvendors))." configs are supported");
}

print debug "configfile: $configfile\n";

open cfh, "<$configfile" or die("Could not open $configfile");
open nfh, ">$newconfigfile" or die("Could not open $newconfigfile");

my $instanza = 0;
while (<cfh>) {
    chomp;
    my $line = $_;

    if (stanzaStart($line)) {
        $instanza = 1;
    } elsif (stanzaEnd($line)) {
#        if (!$instanza) {
#            print debug "DOUBLE EXIT\n";
#        }
        $instanza = 0;
    } else {
        if ($instanza) {
            $line = " $line";
        }
    }
    print nfh "$line\n";
}
close cfh;
close nfh;

`mv $configfile $configfile.orig`;
`mv $newconfigfile $configfile`;

# Supporting subroutines
sub stanzaStart {
    my $line = shift;
    if ($vendor eq "Quanta") {
        return ($line =~ m/^(interface|class-map|policy-map|management access-list|tacacs-server|line )/);
    } elsif ($vendor eq "Juniper" and $role eq "Firewall") {
        return ($line =~ m/^(un)?set ((vrouter ")|(policy id [0-9]+ from))/);
    }
    die("Unhandled vendor/role");
}
sub stanzaEnd {
    my $line = shift;
    if ($vendor eq "Quanta") {
        return ($line =~ m/^exit$/);
    } elsif ($vendor eq "Juniper" and $role eq "Firewall") {
        return ($line =~ m/^exit$/);
    }
    die("Unhandled vendor/role");
}
