#!/usr/bin/perl

# PURPOSE: Determines connectivity within/outside networks and generates graphs
# of each network and the connectivity between networks (if requested).

# PREREQUISITES: MGMTPLANE_CODE/topos/physical_links.pl and 
# MGMTPLANE_CODE/extract/device_hardware.pl have been run.

# OUTPUT:
# nodes.txt, contains the following for each stamp:
# - stamp name
# - number of nodes linked within/from the stamp
# - number of linked nodes within the stamp
# - number of linked nodes outside the stamp
# - number of other linked nodes
# - number of nodes in the stamp without any links within/outside the stamp
# - number of connected stamps

use strict;

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $devsfile = "$datadir/devices.txt";
my $linksfile = "$datadir/links.txt";
my $nodesfile = "$datadir/nodes.txt";
my $toposdir = "$datadir/topos";

# Get arguments
my $gengraphs = "no";
if ($#ARGV >= 0) {
    $gengraphs = $ARGV[0];
}
if ($gengraphs eq "yes") {
    print "Generating graphs\n";
}

my $removeext = "no";
if ($#ARGV >= 1) {
    $removeext = $ARGV[1];
}
if ($removeext eq "yes") {
    print "Excluding external devices\n";
}

my $removeoth = "no";
if ($#ARGV >= 2) {
    $removeoth = $ARGV[2];
}
if ($removeoth eq "yes") {
    print "Excluding cross-stamp devices\n";
}

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
    $dev =~ s/-/_/g;
    my $stamp = $cols[1];
    my $role = $cols[2];
    my $vendor = $cols[3];
    my $model = $cols[4];
    $devices{$dev} = {'stamp' => $stamp, 'role' => $role, 
            'vendor' => $vendor, 'model' => $model};
}
close dfh;

my $curstamp = "";
my %links;
my %internal;
my %external;
my %other;
my %nodes;
my %stamplinks;

open lfh, "$linksfile" or die("Could not open $linksfile");
open nfh, ">$nodesfile" or die("Could not open $nodesfile");
`mkdir $toposdir`;

print nfh "StampName NumLinkedNodes NumInternalNodes NumExternalNodes"
        ." NumOtherNodes NumIsolatedNodes NumConnectedStamps\n";

while (<lfh>) {
    chomp $_;
    my @cols = split/ /, $_;
    my $stamp = $cols[0];
    my $src = $cols[1];
    my $dst = $cols[2];

    $src =~ s/-/_/g;
    $dst =~ s/-/_/g;

    if ($stamp ne $curstamp) {
        if ($curstamp ne "") {
            my $isolated = 0;

            open gfh, ">$toposdir/$curstamp.gv" 
                    or die("Could not open $toposdir/$curstamp.gv");
            print gfh "graph {\n";
            for my $src (sort(keys %links)) {
                for my $dst (sort(keys %{$links{$src}})) {
                    print gfh "\t\"$src\" -- \"$dst\"\n";
                }
            }
            for my $node (sort(keys %nodes)) {
                my $shape = "oval";
                if (exists($devices{$node})) {
                    my $role = $devices{$node}->{role};
                    if ($role eq "LoadBalancer" or $role eq "Firewall" or 
                            $role eq "ApplicationSwitch") {
                        $shape = "rect";
                    }
                }
                if (exists($internal{$node})) {
                    print gfh "\t\"$node\" [shape=$shape, style=filled,"
                            ." fillcolor=yellow]\n";
                }
                if (exists($external{$node})) {
                    print gfh "\t\"$node\" [shape=$shape, style=filled,"
                            ." fillcolor=red]\n";
                }
                if (!exists($internal{$node}) and !exists($external{$node})) {
                    print gfh "\t\"$node\" [shape=$shape, style=filled,"
                            ." fillcolor=blue]\n";
#                    $other{$node}++;
                }
                if ($nodes{$node} == 0) {
                    $isolated++;
                }
            }
            print gfh "}\n";
            close(gfh);
            if ($gengraphs eq "yes" and scalar(keys %nodes) < 200) {
                `dot -Tpng -o $toposdir/$curstamp.png $toposdir/$curstamp.gv`;
            }

            my $icnt = scalar(keys %internal);
            my $ecnt = scalar(keys %external);
            my $ncnt = scalar(keys %nodes);
            my $ocnt = scalar(keys %other);

            my %otherstamps;
            if ($ocnt > 0) {
                for my $node (sort(keys %other)) {
                    my $ostamp = $devices{$node}->{stamp};
                    $otherstamps{$ostamp}++;
#                    print "\t$node $ostamp\n";
                    if (!exists($stamplinks{$curstamp}{$ostamp})
                            and !exists($stamplinks{$ostamp}{$curstamp})) {
                        $stamplinks{$curstamp}{$ostamp}++;
                    }
                }
            }
            my $numOtherStamps = scalar(keys %otherstamps);
            print nfh "$curstamp $ncnt $icnt $ecnt $ocnt $isolated"
                    ." $numOtherStamps\n";
        }
        undef %links;
        undef %internal;
        undef %external;
        undef %other;
        undef %nodes;
        $curstamp = $stamp;
    }

    if (exists($devices{$src})) {
        if ($devices{$src}->{stamp} eq $stamp) {
            $internal{$src}++;
            if (!exists($nodes{$src})) {
                $nodes{$src} = 0;
            }
        } else {
            if ($removeoth eq "yes") {
                next;
            }
            $other{$src}++;
        }
    } else {
        if ($removeext eq "yes") {
            next;
        }
        $external{$src}++;
    }


    if (exists($devices{$dst})) {
        if ($devices{$dst}->{stamp} eq $stamp) {
            $internal{$dst}++;
            if (!exists($nodes{$dst})) {
                $nodes{$dst} = 0;
            }
        } else {
            if ($removeoth eq "yes") {
                next;
            }
            $other{$dst}++;
        }
    } else {
        if ($removeext eq "yes") {
            next;
        }
        $external{$dst}++;
    }


#    $internal{$src}++;
#    if (!exists($nodes{$src})) {
#        $nodes{$src} = 0;
#    }
#
#    if (!exists($devices{$dst})) {
#        if ($removeext eq "yes") {
#            next;
#        }
#        $external{$dst}++;
#    }
#    if ($removeoth eq "yes") {
#        if ($devices{$dst}->{stamp} ne $stamp) {
#            next;
#        }
#    }

    $nodes{$src}++;
    $nodes{$dst}++;

    if (!exists($links{$src}{$dst}) and !exists($links{$dst}{$src})) {
        $links{$src}{$dst} = 1;
    }
}
close(lfh);
close(nfh);

open gfh, ">$toposdir/stamps.gv" or die("Could not open $toposdir/stamps.gv");
print gfh "graph {\n";
for my $src (sort(keys %stamplinks)) {
    for my $dst (sort(keys %{$stamplinks{$src}})) {
        print gfh "\t\"$src\" -- \"$dst\"\n";
    }
}
print gfh "}\n";
close(gfh);
if ($gengraphs eq "yes") {
#    `dot -Tpng -o $toposdir/stamps.png $toposdir/stamps.gv`;
}
