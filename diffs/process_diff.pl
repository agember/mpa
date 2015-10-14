#!/usr/bin/perl

use strict;

open debug, ">/dev/null";
#open debug, ">-";

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'}) or
    die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $diffdir = "$datadir/diffs";
my $uncompdir = "$datadir/uncompcfgs";

# Get arguments
($#ARGV >= 4) or
    die("Specify the diff file, stamp name, device name, vendor, and role");
my $difffile = $ARGV[0];
my $stampname = $ARGV[1];
my $devname = $ARGV[2];
my $vendor = $ARGV[3];
my $role = $ARGV[4];

my %supportedvendors = ( 'Cisco' => 1, 'Juniper' => 1, 'F5' => 1, 
        'Arista' => 1, 'Quanta' => 1 );

if (! exists $supportedvendors{$vendor}) {
    die("Only ".join(",", (keys %supportedvendors))." configs are supported");
}

#if ($vendor eq "F5") {
#    print "Skipping F5 configs\n";
#    exit 1;
#}
#if (!($vendor eq "F5")) {
#    print "Only doing F5 configs\n";
#    exit 1;
#}

my $origfile;
my $newfile;
if ($difffile =~
        m/(\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2})-(\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2})/) {
    $origfile = "$uncompdir/$stampname/$devname/$1.cfg";
    $newfile = "$uncompdir/$stampname/$devname/$2.cfg";
}
else {
    die("Diff has non-standard name: $difffile");
}

$difffile = "$diffdir/$stampname/$devname/$difffile";
    
my $stanzasfile = $difffile;
$stanzasfile =~ s/\.diff/\.stanzas/;
my $typesfile = $difffile;
$typesfile =~ s/\.diff/\.types/;

print debug "difffile: $difffile\norigfile: $origfile\nnewfile: $newfile\n";
print "$difffile\n";

# Get lines from original config
open ofh, "<$origfile";
my @origlines = <ofh>;
map { $_ =~ s/\r?\n//g } @origlines;
close ofh;

# Get lines from new config
open nfh, "<$newfile";
my @newlines = <nfh>;
map { $_ =~ s/\r?\n//g } @newlines;
close nfh;

open dfh, "<$difffile";

my %dstanzas;
my %astanzas;
my %dcstanzas;
my %acstanzas;
my %cdstanzas;
my %castanzas;

my $laststanzaline = -1;
my $lastorigstart = -1;
my $lastorigend = -1;
my $lastorigstanza = "";
my $lastorigaccum = "";
my $lastnewstart = -1;
my $lastnewend = -1;
my $lastnewstanza = "";
my $lastnewaccum = "";
while (<dfh>) {
    chomp;

    # Skip lines that separate stanzas or indicate a special line
    if (m/^(<|>)\s!./) {
        #print "skipping $_\n";
        next;
    }

    # Skip comments
    if (m/^(<|>)\s##\s./) {
        #print "skipping $_\n";
        next;
    } 

    # Deleted lines
    if (m/^(\d+)(\,(\d+))*d(\d+)$/) {
        my $origstart = $1-1;
        my $origend = ($3 eq "" ? $1 : $3)-1;
        my $newmark = $4-1;
        print debug "delete origstart:$origstart origend:$origend newmark:$newmark\n";

        # If we're within the same stanza as last time, then we can shortcut
        if ($origstart >= $lastorigstart and $origend <= $lastorigend) {
            print debug "\tshortcut $lastorigaccum\n";
            print debug "\td change: $lastorigstanza\n";
            if (exists $dcstanzas{$lastorigaccum}) {
                push(@{$dcstanzas{$lastorigaccum}->{regions}},
                        "orig:$origstart:$origend");
            } else {
                $dcstanzas{$lastorigaccum} = {'type' => $lastorigstanza, 
                    'start' => $lastorigstart, 'end' => $lastorigend, 
                    'diff' => 'd', 'regions' => ["orig:$origstart:$origend"]};
            }
            next;
        }

        # Skip over uninteresting lines
        my $i = $origstart;
        while (skipLine($origlines[$i]) and ($i <= $origend)) {
            $i++;
        }
        if ($i > $origend) {
            print debug "\tdelete not interesting\n";
        } else {
            my $accum = ""; 
            $origlines[$i] =~ m/^(\s+)/;
            my $ident = length($1);
            # Find start of first stanza covered by delete
            while (!stanzaStart($origlines[$i]) and $i >= 0) {
                print debug "\t\tnot $i\t$origlines[$i]\n";
                if (accumLine($origlines[$i])) {
                    $origlines[$i] =~ m/^(\s+)/;
                    if (length($1) < $ident) {
                        $accum = "$origlines[$i] $accum";
                        $ident = length($1);
                    }
                }
                $i--;
            }
            print debug "\t\t$i\t$origlines[$i]\n";
            my $stanzastart = $i;
            $accum = "$origlines[$i] $accum";
            $accum =~ s/\s\s+/ /g;
            
            # Find every stanza covered by delete
            $i = $stanzastart+1;
            my $stanzaend = $i;
            do {
                # Find end of stanza
                while (!stanzaEnd($origlines[$i]) and $i < scalar(@origlines)) {
                    print debug "\t\tnot $i\t$origlines[$i]\n";
                    $i++;
                }
                $stanzaend = $i-1;
                print debug "\tstart: $stanzastart\tend: $stanzaend\taccum: $accum\n";

                # Get type of stanza
                if (!groupingStart($origlines[$stanzastart])) {
                    my $j = $stanzastart-1;
                    while (!groupingStart($origlines[$j]) and $j > 0) {
                        $j--;
                    }
                    $accum = "$origlines[$j] $accum";
                    print debug "\tupdated accum: $accum\n";
                }
                my $stanza = stanzaType($accum);

                # Determine if an entire stanza or part of a stanza was del
                if ($stanzastart >= $origstart and $stanzaend <= $origend) {
                    print debug "\td delete: $stanza\n";
                    $dstanzas{$accum} = {'type' => $stanza, 
                        'start' => $stanzastart, 'end' => $stanzaend, 
                        'diff' => 'd', 
                        'regions' => ["orig:$stanzastart:$stanzaend"]};
                }
                else {
                    my $regionstart = $origstart;
                    my $regionend = $origend;
                    if ($stanzastart > $origstart) {
                        $regionstart = $stanzastart;
                    }
                    if ($stanzaend < $origend) {
                        $regionend = $stanzaend; 
                    }
                    print debug "\td change: $stanza\n";
                    if (exists $dcstanzas{$accum}) {
                        push(@{$dcstanzas{$accum}->{regions}},
                                "orig:$regionstart:$regionend");
                    } else {
                        $dcstanzas{$accum} = {'type' => $stanza, 
                            'start' => $stanzastart, 'end' => $stanzaend, 
                            'diff' => 'd', 
                            'regions' => ["orig:$regionstart:$regionend"]};
                    }
                }
                $lastorigstart = $stanzastart;
                $lastorigend = $stanzaend;
                $lastorigstanza = $stanza;
                $lastorigaccum = $accum;

                # Set start of next stanza
                while (skipLine($origlines[$i]) and ($i <= $origend)) {
                    $i++;
                }
                $stanzastart = $i;
                $stanzaend = $i;
                $accum = "$origlines[$i]";
                $ident = 0;
                $i++;
            } while ($stanzaend <= $origend);
        }
    } 
    # Added lines
    elsif (m/^(\d+)a(\d+)(\,(\d+))*$/) {
        my $origmark = $1-1;
        my $newstart = $2-1;
        my $newend = ($4 eq "" ? $2 : $4)-1;
        print debug "add origmark:$origmark newstart:$newstart newend:$newend\n";

        # If we're within the same stanza as last time, then we can shortcut
        if ($newstart >= $lastnewstart and $newend <= $lastnewend) {
            print debug "\tshortcut $lastnewaccum\n";
            print debug "\ta change: $lastnewstanza\n";
            if (exists $acstanzas{$lastnewaccum}) {
                push(@{$acstanzas{$lastnewaccum}->{regions}},
                        "new:$newstart:$newend");
            } else {
                $acstanzas{$lastnewaccum} = {'type' => $lastnewstanza, 
                    'start' => $lastnewstart, 'end' => $lastnewend, 
                    'diff' => 'a', 'regions' => ["new:$newstart:$newend"]};
            }
            next;
        }

        # Skip over uninteresting lines
        my $i = $newstart;
        while (skipLine($newlines[$i]) and ($i <= $newend)) {
            $i++;
        }
        if ($i > $newend) {
            print debug "\tadd not interesting\n";
        }
        else {
            my $accum = ""; 
            $newlines[$i] =~ m/^(\s+)/;
            my $ident = length($1);
            # Find start of first stanza covered by add
            while (!stanzaStart($newlines[$i]) and $i >= 0) {
                print debug "\t\tnot $i\t$newlines[$i]\n";
                if (accumLine($newlines[$i])) {
                    $newlines[$i] =~ m/^(\s+)/;
                    if (length($1) < $ident) {
                        $accum = "$newlines[$i] $accum";
                        $ident = length($1);
                    }
                }
                $i--;
            }
            print debug "\t\t$i\t$newlines[$i]\n";
            my $stanzastart = $i;
            $accum = "$newlines[$i] $accum";
            $accum =~ s/\s\s+/ /g;

            # Find every stanza covered by add
            $i = $stanzastart+1;
            my $stanzaend = $i;
            do {
                # Find end of stanza
                while (!stanzaEnd($newlines[$i]) and $i < scalar(@newlines)) {
                    print debug "\t\tnot $i\t$newlines[$i]\n";
                    $i++;
                }
                $stanzaend = $i-1;
                print debug "\tstart: $stanzastart\tend: $stanzaend\taccum: $accum\n";

                # Get type of stanza
                if (!groupingStart($newlines[$stanzastart])) {
                    my $j = $stanzastart-1;
                    while (!groupingStart($newlines[$j]) and $j > 0) {
                        $j--;
                    }
                    $accum = "$newlines[$j] $accum";
                    print debug "\tupdated accum: $accum\n";
                }
                my $stanza = stanzaType($accum);

                # Determine if an entire stanza or part of a stanza was added
                if ($stanzastart >= $newstart and $stanzaend <= $newend) {
                    print debug "\ta add: $stanza\n";
                    $astanzas{$accum} = {'type' => $stanza, 
                        'start' => $stanzastart, 'end' => $stanzaend, 
                        'diff' => 'a', 
                        'regions' => ["new:$stanzastart:$stanzaend"]};
                }
                else {
                    my $regionstart = $newstart;
                    my $regionend = $newend;
                    if ($stanzastart > $newstart) {
                        $regionstart = $stanzastart;
                    }
                    if ($stanzaend < $newend) {
                        $regionend = $stanzaend; 
                    }
                    print debug "\ta change: $stanza\n";
                    if (exists $acstanzas{$accum}) {
                        push(@{$acstanzas{$accum}->{regions}},
                                "new:$regionstart:$regionend");
                    } else {
                        $acstanzas{$accum} = {'type' => $stanza, 
                            'start' => $stanzastart, 'end' => $stanzaend, 
                            'diff' => 'a', 
                            'regions' => ["new:$regionstart:$regionend"]};
                    }
                }
                $lastnewstart = $stanzastart;
                $lastnewend = $stanzaend;
                $lastnewstanza = $stanza;
                $lastnewaccum = $accum;

                # Set start of next stanza
                while (skipLine($newlines[$i]) and ($i <= $newend)) {
                    $i++;
                }
                $stanzastart = $i;
                $stanzaend = $i;
                $accum = "$newlines[$i]";
                $ident = 0;
                $i++;
            } while ($stanzaend <= $newend);
        }
    } 
    # Changed lines
    elsif (m/^(\d+)(\,(\d+))*c(\d+)(\,(\d+))*$/) {
        my $origstart = $1 - 1;
        my $origend = ($3 eq "" ? $1 : $3)-1;
        my $newstart = $4-1;
        my $newend = ($6 eq "" ? $4 : $6)-1;
        print debug "change origstart:$origstart origend:$origend newstart:$newstart newend:$newend\n";

        # If we're within the same stanza as last time, then we can shortcut
        if (($origstart >= $lastorigstart and $origend <= $lastorigend)
            and  ($newstart >= $lastnewstart and $newend <= $lastnewend)) {
            print debug "\tshortcut $lastorigaccum | $lastnewaccum\n";
            print debug "\tc change: $lastorigstanza\n";
            if (exists $cdstanzas{$lastorigaccum}) {
                push(@{$cdstanzas{$lastorigaccum}->{regions}},
                        "orig:$origstart:$origend");
            } else {
                $cdstanzas{$lastorigaccum} = {'type' => $lastorigstanza, 
                    'start' => $lastorigstart, 'end' => $lastorigend, 
                    'diff' => 'c', 'regions' => ["orig:$origstart:$origend"]};
            }
            print debug "\tc change: $lastnewstanza\n";
            if (exists $castanzas{$lastnewaccum}) {
                push(@{$castanzas{$lastnewaccum}->{regions}},
                        "new:$newstart:$newend");
            } else {
                $castanzas{$lastnewaccum} = {'type' => $lastnewstanza, 
                    'start' => $lastnewstart, 'end' => $lastnewend, 
                    'diff' => 'c', 'regions' => ["new:$newstart:$newend"]};
            }
            next;
        }

        my %dcstanzas;
        my $i = $origstart;

        # Skip over uninteresting lines
        while (skipLine($origlines[$i]) and ($i <= $origend)) {
            $i++;
        }
        if ($i > $origend) {
            print debug "\tchange not interesting\n";
        }
        else {
            my $accum = ""; 
            $origlines[$i] =~ m/^(\s+)/;
            my $ident = length($1);
            # Find start of first stanza covered by deleted lines
            while (!stanzaStart($origlines[$i]) and $i >= 0) {
                print debug "\t\tnot $i\t$origlines[$i]\n";
                if (accumLine($origlines[$i])) {
                    $origlines[$i] =~ m/^(\s+)/;
                    if (length($1) < $ident) {
                        $accum = "$origlines[$i] $accum";
                        $ident = length($1);
                    }
                }
                $i--;
            }
            print debug "\t\t$i\t$origlines[$i]\n";
            my $stanzastart = $i;
            $accum = "$origlines[$i] $accum";
            $accum =~ s/\s\s+/ /g;

            # Find every stanza covered by deleted lines
            $i = $stanzastart+1;
            my $stanzaend = $i;
            do {
                # Find end of stanza
                while (!stanzaEnd($origlines[$i]) and $i < scalar(@origlines)) {
                    print debug "\t\tnot $i\t$origlines[$i]\n";
                    $i++;
                }
                $stanzaend = $i-1;
                print debug "\tstart: $stanzastart\tend: $stanzaend\taccum: $accum\n";

                # Get type of stanza
                if (!groupingStart($origlines[$stanzastart])) {
                    my $j = $stanzastart-1;
                    while (!groupingStart($origlines[$j]) and $j > 0) {
                        $j--;
                    }
                    $accum = "$origlines[$j] $accum";
                    print debug "\tupdated accum: $accum\n";
                }
                my $stanza = stanzaType($accum);

                # Determine if an entire stanza or part of a stanza was del
                if ($stanzastart >= $origstart and $stanzaend <= $origend) {
                    print debug "\tc delete: $stanza\n";
                    $dstanzas{accumFilter($accum)} = {'type' => $stanza, 
                        'start' => $stanzastart, 'end' => $stanzaend, 
                        'diff' => 'c', 
                        'regions' => ["orig:$stanzastart:$stanzaend"]};
                }
                else {
                    my $regionstart = $origstart;
                    my $regionend = $origend;
                    if ($stanzastart > $origstart) {
                        $regionstart = $stanzastart;
                    }
                    if ($stanzaend < $origend) {
                        $regionend = $stanzaend; 
                    }
                    print debug "\tc change: $stanza\n";
                    if (exists $cdstanzas{$accum}) {
                        push(@{$cdstanzas{$accum}->{regions}},
                                "orig:$regionstart:$regionend");
                    } else {
                        $cdstanzas{$accum} = {'type' => $stanza, 
                            'start' => $stanzastart, 'end' => $stanzaend, 
                            'diff' => 'c', 
                            'regions' => ["orig:$regionstart:$regionend"]};
                    }
                }
                $lastorigstart = $stanzastart;
                $lastorigend = $stanzaend;
                $lastorigstanza = $stanza;
                $lastorigaccum = $accum;

                # Set start of next stanza
                while (skipLine($origlines[$i]) and ($i <= $origend)) {
                    $i++;
                }
                $stanzastart = $i;
                $stanzaend = $i;
                $accum = "$origlines[$i]";
                $ident = 0;
                $i++;
            } while ($stanzaend <= $origend);
        }

        my %acstanzas;
        $i = $newstart;

        # Skip over uninteresting lines
        while (skipLine($newlines[$i]) and ($i <= $newend)) {
            $i++;
        }
        if ($i > $newend) {
            print debug "\tchange not interesting\n";
        }
        else {
            my $accum = ""; 
            $newlines[$i] =~ m/^(\s+)/;
            my $ident = length($1);
            # Find start of first stanza covered by added lines
            while (!stanzaStart($newlines[$i]) and $i >= 0) {
                print debug "\t\tnot $i\t$newlines[$i]\n";
                if (accumLine($newlines[$i])) {
                    $newlines[$i] =~ m/^(\s+)/;
                    if (length($1) < $ident) {
                        $accum = "$newlines[$i] $accum";
                        $ident = length($1);
                    }
                }
                $i--;
            }
            print debug "\t\t$i\t$newlines[$i]\n";
            my $stanzastart = $i;
            $accum = "$newlines[$i] $accum";
            $accum =~ s/\s\s+/ /g;

            # Find every stanza covered by added lines
            $i = $stanzastart+1;
            my $stanzaend = $i;
            do {
                # Find end of stanza
                while (!stanzaEnd($newlines[$i]) and $i < scalar(@newlines)) {
                    print debug "\t\tnot $i\t$newlines[$i]\n";
                    $i++;
                }
                $stanzaend = $i-1;
                print debug "\tstart: $stanzastart\tend: $stanzaend\taccum: $accum\n";

                # Get type of stanza
                if (!groupingStart($newlines[$stanzastart])) {
                    my $j = $stanzastart-1;
                    while (!groupingStart($newlines[$j]) and $j > 0) {
                        $j--;
                    }
                    $accum = "$newlines[$j] $accum";
                    print debug "\tupdated accum: $accum\n";
                }
                my $stanza = stanzaType($accum);

                # Determine if an entire stanza or part of a stanza was added
                if ($stanzastart >= $newstart and $stanzaend <= $newend) {
                    print debug "\tc add: $stanza\n";
                    $astanzas{accumFilter($accum)} = {'type' => $stanza, 
                        'start' => $stanzastart, 'end' => $stanzaend, 
                        'diff' => 'c', 
                        'regions' => ["new:$stanzastart:$stanzaend"]};
                }
                else {
                    my $regionstart = $newstart;
                    my $regionend = $newend;
                    if ($stanzastart > $newstart) {
                        $regionstart = $stanzastart;
                    }
                    if ($stanzaend < $newend) {
                        $regionend = $stanzaend; 
                    }
                    print debug "\tc change: $stanza\n";
                    if (exists $castanzas{$accum}) {
                        push(@{$castanzas{$accum}->{regions}},
                                "new:$regionstart:$regionend");
                    } else {
                        $castanzas{$accum} = {'type' => $stanza, 
                            'start' => $stanzastart, 'end' => $stanzaend, 
                            'diff' => 'c', 
                            'regions' => ["new:$regionstart:$regionend"]};
                    }
                }
                $lastnewstart = $stanzastart;
                $lastnewend = $stanzaend;
                $lastnewstanza = $stanza;
                $lastnewaccum = $accum;

                # Set start of next stanza
                while (skipLine($newlines[$i]) and ($i <= $newend)) {
                    $i++;
                }
                $stanzastart = $i;
                $stanzaend = $i;
                $accum = "$newlines[$i]";
                $ident = 0;
                $i++;
            } while ($stanzaend <= $newend); 
        }
    }
}
close dfh;

# Remove duplicates
my %cstanzas;
for my $key (keys %dcstanzas) {
    print debug "Change (d) $key\n";
    if (!exists $cstanzas{$key}) {
        $cstanzas{$key} = $dcstanzas{$key};
    } else {
        for my $region (@{$dcstanzas{$key}->{regions}}) {
            if (!grep {$_ eq $region} @{$cstanzas{$key}->{regions}}) {
                push(@{$cstanzas{$key}->{regions}}, $region);
            }
        }
    }
}
for my $key (keys %acstanzas) {
    print debug "Change (a) $key\n";
    if (!exists $cstanzas{$key}) {
        $cstanzas{$key} = $acstanzas{$key};
    } else {
        for my $region (@{$acstanzas{$key}->{regions}}) {
            if (!grep {$_ eq $region} @{$cstanzas{$key}->{regions}}) {
                push(@{$cstanzas{$key}->{regions}}, $region);
            }
        }
    }
}
for my $key (keys %cdstanzas) {
    print debug "Change (cd) $key\n";
    if (!exists $cstanzas{$key}) {
        $cstanzas{$key} = $cdstanzas{$key};
    } else {
        for my $region (@{$cdstanzas{$key}->{regions}}) {
            if (!grep {$_ eq $region} @{$cstanzas{$key}->{regions}}) {
                push(@{$cstanzas{$key}->{regions}}, $region);
            }
        }
    }
}
for my $key (keys %castanzas) {
    print debug "Change (ca) $key\n";
    if (!exists $cstanzas{$key}) {
        $cstanzas{$key} = $castanzas{$key};
    } else {
        for my $region (@{$castanzas{$key}->{regions}}) {
            if (!grep {$_ eq $region} @{$cstanzas{$key}->{regions}}) {
                push(@{$cstanzas{$key}->{regions}}, $region);
            }
        }
    }
}

for my $key (keys %dstanzas) {
    if (!exists $astanzas{$key}) {
        next;
    }

    # If stanzas have different lengths, then something must have changed
    my $dstart = $dstanzas{$key}->{start};
    my $astart = $astanzas{$key}->{start};
    my $dlen = $dstanzas{$key}->{end} - $dstart;
    my $alen = $astanzas{$key}->{end} - $astart;
    if ($dlen != $alen) {
        $cstanzas{$key} = $dstanzas{$key};
        delete $dstanzas{$key};
        delete $astanzas{$key};
        print debug "Change (d+a) $key\n";
        next;
    }

    # Check line by line to see if something changed
    my $i = 0;
    my $perfect = 1;
    for ($i = 0; $i <= $dlen; $i++) {
#        print debug "\t'$origlines[$i+$dstart]' ==? '$newlines[$i+$astart]'\n";
        if ($origlines[$i+$dstart] ne $newlines[$i+$astart]) {
            $perfect = 0;
            last;
        }
    }
    if ($perfect) {
        print debug "Moved (d+a) $key\n";
    } else {
        $cstanzas{$key} = $dstanzas{$key};
        print debug "Change (d+a) $key\n";
    }
    delete $dstanzas{$key};
    delete $astanzas{$key};
}

# Print stanzas
open sf, ">$stanzasfile" or die("ERROR: Could not open $stanzasfile");
my %types;
outputStanzas("Delete",\%dstanzas);
outputStanzas("Add",\%astanzas);
outputStanzas("Change",\%cstanzas);
close sf;

# Print types
open tf, ">$typesfile" or die("ERROR: Could not open $typesfile");
for my $type (keys %types) {
#    print "Type $type $types{$type}\n";
    print tf "$type $types{$type}\n";
}
close tf;

# If we didn't actually write anything, then remove the stanza and type files
if (0 == scalar(keys %types)) {
    `rm $stanzasfile`;
    `rm $typesfile`;
}

# Supporting subroutines
sub stanzaStart {
    my $line = shift;
    if ($vendor eq "Cisco") {
        return (!($line =~ m/^\s/));
    } elsif ($vendor eq "Juniper") {
        return ($line =~ m/^\s{4}[^\s]+\s({|;)$/);
    } elsif ($vendor eq "F5") {
        return (!($line =~ m/^\s/));
    } elsif ($vendor eq "Arista") {
        return (!($line =~ m/^\s/) and !($line =~ m/:$/));
    } elsif ($vendor eq "Quanta") {
        return (!($line =~ m/^\s/));
    }
    die("ERROR: Unhandled vendor");
}
sub stanzaEnd {
    my $line = shift;
    if ($vendor eq "Cisco") {
        return (!($line =~ m/^\s/));
    } elsif ($vendor eq "Juniper" and $role eq "Firewall") {
        return (!($line =~ m/^\s/));
    } elsif ($vendor eq "Juniper") {
        return ($line =~ m/^\s{4}}$/);
    } elsif ($vendor eq "F5") {
        return (!($line =~ m/^\s/));
    } elsif ($vendor eq "Arista") {
        return (!($line =~ m/^\s/) and !($line =~ m/:$/));
    } elsif ($vendor eq "Quanta") {
        return (!($line =~ m/^\s/));
    }
    die("ERROR: Unhandled vendor");
}
sub groupingStart {
    my $line = shift;
    if ($vendor eq "Cisco") {
        return ($line =~m/^[a-z]/);
    } elsif ($vendor eq "Juniper" and $role eq "Firewall") {
        return ($line =~ m/^[a-z]/);
    } elsif ($vendor eq "Juniper") {
        return ($line =~ m/^[a-z]/);
    } elsif ($vendor eq "F5") {
        return ($line =~m/^[a-z]/);
    } elsif ($vendor eq "Arista") {
        return ($line =~m/^[a-z]/);
    } elsif ($vendor eq "Quanta") {
        return ($line =~m/^[a-z]/);
    }
    die("ERROR: Unhandled vendor");
}
sub stanzaType {
    my $line = shift;
    $line =~ s/^\s+//;
    $line =~ s/\s\s+/ /;
    $line = "$line ";
    if ($vendor eq "Cisco") {
        #if ($line =~ m/^(no )?(([a-z\-]+ )|([a-z\-]+$)|([a-z\-]+ [a-z\-]+ )|([a-z\-]+ [a-z\-]+$))/) {
        if ($line =~ m/^(no )?([a-z\-]+ )([a-z\-]+ )?/) {
            my $type = "$2$3";
            $type =~ s/\s+$//;
            $type =~ s/\s/_/;
            return $type;
        }
        return "unknown";
    } elsif ($vendor eq "Juniper" and $role eq "Firewall") {
         if ($line =~ m/^(un)?set ([a-z\-]+ )({ [a-z\-]+ )?/) {
            my $type = "$2$3";
            $type =~ s/\s+$//;
            $type =~ s/\s/_/;
            return $type;
        }
        return "unknown";
    } elsif ($vendor eq "Juniper") {
        #if ($line =~ m/^(no )?([a-z\-]+)($| )(([a-z\-]+)|({ [a-z\-]+ ))?/) {
         if ($line =~ m/^([a-z\-]+ )({ [a-z\-]+ )?/) {
            my $type = "$1$2";
            $type =~ s/\s+$//;
            $type =~ s/( { )| /_/;
            return $type;
        }
        return "unknown";
    } elsif ($vendor eq "F5") {
        if ($line =~ m/^([a-z\-]+ )([a-z\-]+ )?/) {
            my $type = "$1$2";
            $type =~ s/\s+$//;
            $type =~ s/\s/_/;
            return $type;
        }
        return "unknown";
    } elsif ($vendor eq "Arista") {
        if ($line =~ m/^(no )?([a-z\-]+ )([a-z\-]+ )?/) {
            my $type = "$2$3";
            $type =~ s/\s+$//;
            $type =~ s/\s/_/;
            return $type;
        }
        return "unknown";
    } elsif ($vendor eq "Quanta") {
        if ($line =~ m/^(no )?([a-z\-]+ )([a-z\-]+ )?/) {
            my $type = "$2$3";
            $type =~ s/\s+$//;
            $type =~ s/\s/_/;
            return $type;
        }
        return "unknown";
    }
    die("ERROR: Unhandled vendor");
}
sub skipLine {
    my $line = shift;
    if ($vendor eq "Cisco") {
        return ($line =~ m/(^\s?!$)|(^$)|(^!)/);
    } elsif ($vendor eq "Juniper" and $role eq "Firewall") {
        return ($line =~ m/^(!|(exit))/);
    } elsif ($vendor eq "Juniper") {
        return ($line =~ m/^(!|#|[a-z])|}/);        
    } elsif ($vendor eq "F5") {
        return ($line =~ m/^(!|#|}|<|"|[A-Z])/);
    } elsif ($vendor eq "Arista") {
        return ($line =~ m/^!/);
    } elsif ($vendor eq "Quanta") {
        return ($line =~ m/^(!|(exit))/);
    }
}
sub accumLine {
    my $line = shift;
    if ($vendor eq "Cisco") {
        return 0;
    } elsif ($vendor eq "Juniper" and $role eq "Firewall") {
        return 0;
    } elsif ($vendor eq "Juniper") {
        return ($line =~ m/{$/);        
    } elsif ($vendor eq "F5") {
        return 0;
    } elsif ($vendor eq "Arista") {
        return 0;
    } elsif ($vendor eq "Quanta") {
        return 0;
    }
}
sub accumFilter {
    my $accum = shift;
    $accum =~ s/(^\s+)|(\s+$)//g;
    $accum =~ s/\s\s+/ /;
    if ($vendor eq "Cisco") {
        if ($accum =~ m/^(enable secret \d+) /) {
            return $1;
        } elsif ($accum =~ m/^(ntp clock-period) \d+$/) {
            return $1;
        } elsif ($accum =~ m/^(enable passwd encrypted) /) {
            return $1;
        } elsif ($accum =~ m/^(username "[^"]+" password) /) {
            return $1;
        } elsif ($accum =~ m/^(users passwd "[^"]+" encrypted) /) {
            return $1;
        } elsif ($accum =~ m/^(sflow receiver [^\s]+ owner gnsops timeout) /) {
            return $1;
        }    
        return $accum;
    } elsif ($vendor eq "Juniper" and $role eq "Firewall") {
        return $accum;
    } elsif ($vendor eq "Juniper") {
        return $accum;
    } elsif ($vendor eq "F5") {
        return $accum;
    } elsif ($vendor eq "Arista") {
        if ($accum =~ m/^(enable secret \d+) /) {
            return $1;
        } elsif ($accum =~ m/^(ntp clock-period) \d+$/) {
            return $1;
        } elsif ($accum =~ m/^(enable passwd encrypted) /) {
            return $1;
        } elsif ($accum =~ m/^(username "[^"]+" password) /) {
            return $1;
        } elsif ($accum =~ m/^(users passwd "[^"]+" encrypted) /) {
            return $1;
        } elsif ($accum =~ m/^(sflow receiver [^\s]+ owner gnsops timeout) /) {
            return $1;
        }
        return $accum;
    } elsif ($vendor eq "Quanta") {
        if ($accum =~ m/^(enable secret \d+) /) {
            return $1;
        } elsif ($accum =~ m/^(ntp clock-period) \d+$/) {
            return $1;
        } elsif ($accum =~ m/^(enable password) /) {
            return $1;
        } elsif ($accum =~ m/^(enable passwd encrypted) /) {
            return $1;
        } elsif ($accum =~ m/^(username "[^"]+" password) /) {
            return $1;
        } elsif ($accum =~ m/^(users passwd "[^"]+" encrypted) /) {
            return $1;
        } elsif ($accum =~ m/^(sflow receiver [^\s]+ owner gnsops timeout) /) {
            return $1;
        }
        return $accum;
    }
    die("ERROR: Unhandled vendor");
}
sub outputStanzas {
    my $action = shift;
    my $stanzasRef = shift;
    my %stanzas = %$stanzasRef;

    for my $key (sort(keys %stanzas)) {
#        print "$key\n";
        my $stanza = $key;
        $stanza =~ s/(^\s+)|(\s+$)//g;
        $stanza =~ s/ /_/g;
        my %lines;
        for my $region (@{$stanzas{$key}->{regions}}) {
#            print "\t$region\n";
            my @r = split ":", $region;
            for (my $i = $r[1]; $i <= $r[2]; $i++) {
                my $line;
                if ($r[0] eq "orig") {
                    $line = $origlines[$i];
                } else {
                    $line = $newlines[$i];
                }
                $lines{stanzaType($line)}++;
            }
        }
        my $type = $stanzas{$key}->{type};
#        print "$action $stanza\n";
        print sf "$action $stanza $type ".join(",",sort(keys %lines))."\n";
        $types{$type}++;
    }
}
