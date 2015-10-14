#!/usr/bin/perl

use strict;
use Date::Calc qw(Day_of_Year Mktime Add_Delta_Days);

# OUTPUT:
# all_metrics.csv, contains data for each stamp for each period

# Get directories and files
(exists $ENV{'MGMTPLANE_DATA'})
    or die("Set the MGMTPLANE_DATA environment variable");
my $datadir = "$ENV{'MGMTPLANE_DATA'}";
my $hardwareFile = "$datadir/hardware.txt";
my $architectureFile = "$datadir/architecture.txt";
my $ticketFile = "$datadir/ticket.txt";
my $changefreqFile = "$datadir/change_frequency.txt";
my $changestanzasFile = "$datadir/change_stanzas.txt";
my $stanzaautoFile = "$datadir/stanza_automation.txt";
my $vendorpresentFile = "$datadir/vendor_present.txt";
my $rolepresentFile = "$datadir/role_present.txt";
my $rolecountFile = "$datadir/role_count.txt";
my $modelpresentFile = "$datadir/model_present.txt";
my $architecturepresentFile = "$datadir/arch_present.txt";
my $firmwareFile = "$datadir/firmware_hetero.txt";
my $protocolsFile = "$datadir/protocols.txt";
my $complexityFile = "$datadir/complexity_1m.txt";
my $nodesFile = "$datadir/nodes.txt";
my $adminFile = "$datadir/admin.txt";

my $outputfile = "$datadir/all_metrics.csv";

# Get the argument that specifies whether missing values are allowed
my $allowmissing = "yes";
if ($#ARGV >= 0) {
    $allowmissing = $ARGV[0];
}
if (not ($allowmissing eq "yes" or $allowmissing eq "no")) {
    die("Specify 'yes' or 'no' for whether to allow missing values");
}
print "Allow missing? ", $allowmissing,"\n";

# Get the date range arguments
my $mindate = "";
my $maxdate = "";
if ($#ARGV >= 2) {
    $mindate = $ARGV[1];
    $maxdate = $ARGV[2];
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
    print "Limited to date range: $mindate to $maxdate\n";
}

my $hardware = {};
my $architecture = {};
my $ticket = {};
my $changefreq = {};
my $changestanzas = {};
my $stanzaauto = {};
my $vendorpresent = {};
my $rolepresent = {};
my $rolecount = {};
my $modelpresent = {};
my $architecturepresent = {};
my $firmware = {};
my $protocols = {};
my $complexity = {};
my $nodes = {};
my $admin = {};

my %periodsSeen;
my $hdr;

# Load output from device_hardware.pl
open(fh, "$hardwareFile") or die("Could not open $hardwareFile");
$hdr = <fh>;
chomp $hdr;
my @hardwareCols = split " ", $hdr;
@hardwareCols = @hardwareCols[1..(scalar(@hardwareCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    $hardware->{$stampName} = [];
    push @{$hardware->{$stampName}}, @cols[1..(scalar(@cols)-1)];
}
close(fh);

# Load output from stamp_architecture.pl
open(fh, "$architectureFile") or die("Could not open $architectureFile");
$hdr = <fh>;
chomp $hdr;
my @architectureCols = split " ", $hdr;
@architectureCols = @architectureCols[1..(scalar(@architectureCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    $architecture->{$stampName} = [];
    push @{$architecture->{$stampName}}, @cols[1..(scalar(@cols)-1)];
}
close(fh);

# Load output from ticket_count.pl
open(fh, "$ticketFile") or die("Could not open $ticketFile");
$hdr = <fh>;
chomp $hdr;
my @ticketCols = split " ", $hdr;
@ticketCols = @ticketCols[2..(scalar(@ticketCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    my $period = $cols[1];
    $periodsSeen{$period} = 1;
    $ticket->{$stampName}{$period} = [];
    # FIXME: re-run fixed ticket count script
    push @{$ticket->{$stampName}{$period}}, @cols[2..(scalar(@cols)-2)];
#    push @{$ticket->{$stampName}{$period}}, @cols[2..(scalar(@cols)-1)];
}
close(fh);

# Load output from change_frequency.pl
open(fh, "$changefreqFile") or die("Could not open $changefreqFile");
$hdr = <fh>;
chomp $hdr;
my @changefreqCols = split " ", $hdr;
@changefreqCols = @changefreqCols[2..(scalar(@changefreqCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    my $period = $cols[1];
    if (scalar(keys %periodsSeen) > 1 and $period eq "all") {
        die("Period mismatch for $changefreqFile");
    }
    $periodsSeen{$period} = 1;
    $changefreq->{$stampName}{$period} = [];
    push @{$changefreq->{$stampName}{$period}}, @cols[2..(scalar(@cols)-1)];
}
close(fh);

# Load output from change_stanzas.pl
open(fh, "$changestanzasFile") or die("Could not open $changestanzasFile");
$hdr = <fh>;
chomp $hdr;
my @changestanzasCols = split " ", $hdr;
@changestanzasCols = @changestanzasCols[2..(scalar(@changestanzasCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    my $period = $cols[1];
    if (scalar(keys %periodsSeen) > 1 and $period eq "all") {
        die("Period mismatch for $changestanzasFile");
    }
    $periodsSeen{$period} = 1;
    $changestanzas->{$stampName}{$period} = [];
    push @{$changestanzas->{$stampName}{$period}}, @cols[2..(scalar(@cols)-1)];
}
close(fh);

# Load output from change_stanza_automation.pl
open(fh, "$stanzaautoFile") or die("Could not open $stanzaautoFile");
$hdr = <fh>;
chomp $hdr;
my @stanzaautoCols = split " ", $hdr;
@stanzaautoCols = @stanzaautoCols[1..(scalar(@stanzaautoCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    $stanzaauto->{$stampName} = [];
    push @{$stanzaauto->{$stampName}}, @cols[1..(scalar(@cols)-1)];
}
close(fh);

# Load output from vendor_present.pl
open(fh, "$vendorpresentFile") or die("Could not open $vendorpresentFile");
$hdr = <fh>;
chomp $hdr;
$hdr =~ s/^[^:]+://;
$hdr =~ s/ / HasVendor/g;
$hdr =~ s/(^ +)|( +$)//;
my @vendorpresentCols = split " ", $hdr;
while (<fh>) {
    chomp;
    my @cols = split /:?\s+/, $_;
    my $stampName = $cols[0];
    $vendorpresent->{$stampName} = [];
    push @{$vendorpresent->{$stampName}}, @cols[1..(scalar(@cols)-1)];
}
close(fh);

# Load output from role_present.pl
open(fh, "$rolepresentFile") or die("Could not open $rolepresentFile");
$hdr = <fh>;
chomp $hdr;
$hdr =~ s/^[^:]+://;
$hdr =~ s/ / HasRole/g;
$hdr =~ s/(^ +)|( +$)//;
my @rolepresentCols = split " ", $hdr;
while (<fh>) {
    chomp;
    my @cols = split /:?\s+/, $_;
    my $stampName = $cols[0];
    $rolepresent->{$stampName} = [];
    push @{$rolepresent->{$stampName}}, @cols[1..(scalar(@cols)-1)];
}
close(fh);

open(fh, "$rolecountFile") or die("Could not open $rolecountFile");
$hdr = <fh>;
chomp $hdr;
$hdr =~ s/^[^:]+://;
$hdr =~ s/ / NumRole/g;
$hdr =~ s/(^ +)|( +$)//;
my @rolecountCols = split " ", $hdr;
while (<fh>) {
    chomp;
    my @cols = split /:?\s+/, $_;
    my $stampName = $cols[0];
    $rolecount->{$stampName} = [];
    push @{$rolecount->{$stampName}}, @cols[1..(scalar(@cols)-1)];
}
close(fh);

# Load output from model_present.pl
open(fh, "$modelpresentFile") or die("Could not open $modelpresentFile");
$hdr = <fh>;
chomp $hdr;
$hdr =~ s/^[^:]+://;
$hdr =~ s/ / HasModel/g;
$hdr =~ s/(^ +)|( +$)//;
my @modelpresentCols = split " ", $hdr;
while (<fh>) {
    chomp;
    my @cols = split /:?\s+/, $_;
    my $stampName = $cols[0];
    $modelpresent->{$stampName} = [];
    push @{$modelpresent->{$stampName}}, @cols[1..(scalar(@cols)-1)];
}
close(fh);

# Load output from arch_present.pl
open(fh, "$architecturepresentFile") or 
        die("Could not open $architecturepresentFile");
$hdr = <fh>;
chomp $hdr;
$hdr =~ s/^[^:]+://;
$hdr =~ s/ / HasModel/g;
$hdr =~ s/(^ +)|( +$)//;
my @architecturepresentCols = split " ", $hdr;
while (<fh>) {
    chomp;
    my @cols = split /:?\s+/, $_;
    my $stampName = $cols[0];
    $architecturepresent->{$stampName} = [];
    push @{$architecturepresent->{$stampName}}, @cols[1..(scalar(@cols)-1)];
}
close(fh);

# Load output from firmware_hetero.pl
open(fh, "$firmwareFile") or die("Could not open $firmwareFile");
$hdr = <fh>;
chomp $hdr;
my @firmwareCols = split " ", $hdr;
@firmwareCols = @firmwareCols[2..(scalar(@firmwareCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    my $period = $cols[1];
    if (scalar(keys %periodsSeen) > 1 and $period eq "all") {
        die("Period mismatch for $firmwareFile");
    }
    $periodsSeen{$period} = 1;
    $firmware->{$stampName}{$period} = [];
    push @{$firmware->{$stampName}{$period}}, @cols[2..(scalar(@cols)-1)];
}

close(fh);

# Load output from device_protocols.pl
open(fh, "$protocolsFile") or die("Could not open $protocolsFile");
$hdr = <fh>;
chomp $hdr;
my @protocolsCols = split " ", $hdr;
@protocolsCols = @protocolsCols[2..(scalar(@protocolsCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    my $period = $cols[1];
    if (scalar(keys %periodsSeen) > 1 and $period eq "all") {
        die("Period mismatch for $protocolsFile");
    }
    $periodsSeen{$period} = 1;
    $protocols->{$stampName}{$period} = [];
    push @{$protocols->{$stampName}{$period}}, @cols[2..(scalar(@cols)-1)];
}
close(fh);

# Load complexity output
open(fh, "$complexityFile") or die("Could not open $complexityFile");
$hdr = <fh>;
chomp $hdr;
my @complexityCols = split ",", $hdr;
@complexityCols = @complexityCols[3..(scalar(@complexityCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split ",", $_;
    my $stampName = $cols[0];
    my $period = $cols[1];
    if (scalar(keys %periodsSeen) > 1 and $period eq "all") {
        die("Period mismatch for $complexityFile");
    }
    $periodsSeen{$period} = 1;
    $complexity->{$stampName}{$period} = [];
    push @{$complexity->{$stampName}{$period}}, @cols[3..(scalar(@cols)-1)];
}
close(fh);

# Load output from ../topo/graphs.pl
open(fh, "$nodesFile") or die("Could not open $nodesFile");
$hdr = <fh>;
chomp $hdr;
my @nodesCols = split " ", $hdr;
@nodesCols = @nodesCols[1..(scalar(@nodesCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    $nodes->{$stampName} = [];
    push @{$nodes->{$stampName}}, @cols[1..(scalar(@cols)-1)];
}
close(fh);

# Load output from admin_count.pl
open(fh, "$adminFile") or die("Could not open $adminFile");
$hdr = <fh>;
chomp $hdr;
my @adminCols = split " ", $hdr;
@adminCols = @adminCols[2..(scalar(@adminCols)-1)];
while (<fh>) {
    chomp;
    my @cols = split " ", $_;
    my $stampName = $cols[0];
    my $period = $cols[1];
    if (scalar(keys %periodsSeen) > 1 and $period eq "all") {
        die("Period mismatch for $adminFile");
    }
    $periodsSeen{$period} = 1;
    $admin->{$stampName}{$period} = [];
    push @{$admin->{$stampName}{$period}}, @cols[2..(scalar(@cols)-1)];
}
close(fh);


open(fh, ">$outputfile") or die("ERROR: Could not open $outputfile");
print fh "StampName,Month"
        .",".join(",",@hardwareCols)
        .",".join(",",@architectureCols)
        .",".join(",",@ticketCols)
        .",".join(",",@changefreqCols)
        .",".join(",",@changestanzasCols)
        .",".join(",",@stanzaautoCols)
        .",".join(",",@vendorpresentCols)
        .",".join(",",@rolepresentCols)
        .",".join(",",@rolecountCols)
##        .",".join(",",@modelpresentCols)
##        .",".join(",",@architecturepresentCols)
        .",".join(",",@firmwareCols)
        .",".join(",",@protocolsCols)
        .",".join(",",@complexityCols)
        .",".join(",",@nodesCols)
        .",".join(",",@adminCols)
        ."\n";

# Filter periods
my @periods;
if ($mintime > 0 and $maxtime > 0 and (scalar(keys %periodsSeen) > 1)) {
    for my $period (sort(keys %periodsSeen)) {
        my $periodtime = -1;
        if ($period =~ m/^(\d{4})-(\d{2})$/) {
            my $year = $1;
            my $month = $2;
            $periodtime = Mktime($year, $month, 1, 0, 0, 0);
        } elsif ($period =~ m/^(\d{4})-(\d{3})$/) {
            my $year = $1;
            my $doy = $2;
            ($year, my $month, my $day) = Add_Delta_Days($year,1,1, $doy - 1);
            $periodtime = Mktime($year, $month, $day, 0, 0, 0);
        }
        if ($periodtime > $mintime and $periodtime < $maxtime) {
            push(@periods, $period);
        }
    }
} else {
    @periods = sort(keys %periodsSeen);
}

for my $stampName (sort(keys %$hardware)) {
    print "$stampName\n";
    # Skip stamps without ticket data
    if (!exists $ticket->{$stampName}) {
        next;
    }

    for my $period (@periods) {
        print fh "$stampName,$period";

        print fh ",".join(",",@{$hardware->{$stampName}});

        if (exists $architecture->{$stampName}) {
            print fh ",".join(",",@{$architecture->{$stampName}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "unknown";
            }
            print fh ",".join(",",($missing) x scalar(@architectureCols));
        }

        if (exists $ticket->{$stampName}{$period}) {
            print fh ",".join(",",@{$ticket->{$stampName}{$period}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "0";
            }
            print fh ",".join(",",($missing) x scalar(@ticketCols));
        }

        if (exists $changefreq->{$stampName}{$period}) {
            print fh ",".join(",",@{$changefreq->{$stampName}{$period}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "0";
            }
            print fh ",".join(",",($missing) x scalar(@changefreqCols));
        }

        if (exists $changestanzas->{$stampName}{$period}) {
            print fh ",".join(",",@{$changestanzas->{$stampName}{$period}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "0";
            }
            print fh ",".join(",",($missing) x scalar(@changestanzasCols));
        }

        if (exists $stanzaauto->{$stampName}) {
            print fh ",".join(",",@{$stanzaauto->{$stampName}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "0";
            }
            print fh ",".join(",",($missing) x scalar(@stanzaautoCols));
        }

        if (exists $vendorpresent->{$stampName}) {
            print fh ",".join(",",@{$vendorpresent->{$stampName}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "-1";
            }
            print fh ",".join(",",($missing) x scalar(@vendorpresentCols));
        }

        if (exists $rolepresent->{$stampName}) {
            print fh ",".join(",",@{$rolepresent->{$stampName}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "-1";
            }
            print fh ",".join(",",($missing) x scalar(@rolepresentCols));
        }

        if (exists $rolecount->{$stampName}) {
            print fh ",".join(",",@{$rolecount->{$stampName}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "-1";
            }
            print fh ",".join(",",($missing) x scalar(@rolecountCols));
        }

##        if (exists $modelpresent->{$stampName}) {
##            print fh ",".join(",",@{$modelpresent->{$stampName}});
##        } else {
##            my $missing = "";
##            if ($allowmissing eq "no") {
##                $missing = "-1";
##            }
##            print fh ",".join(",",($missing) x scalar(@modelpresentCols));
##        }

##        if (exists $architecturepresent->{$stampName}) {
##            print fh ",".join(",",@{$architecturepresent->{$stampName}});
##        } else {
##            my $missing = "";
##            if ($allowmissing eq "no") {
##                $missing = "-1";
##            }
##            print fh ",".join(",",($missing) x scalar(@architecturepresentCols));
##        }

        if (exists $firmware->{$stampName}{$period}) {
            print fh ",".join(",",@{$firmware->{$stampName}{$period}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "0";
            }
            print fh ",".join(",",($missing) x scalar(@firmwareCols));
        }

        if (exists $protocols->{$stampName}{$period}) {
            print fh ",".join(",",@{$protocols->{$stampName}{$period}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "-1";
            }
            print fh ",".join(",",($missing) x scalar(@protocolsCols));
        }

        if (exists $complexity->{$stampName}{$period}) {
            print fh ",".join(",",@{$complexity->{$stampName}{$period}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "-1";
            }
            print fh ",".join(",",($missing) x scalar(@complexityCols));
        }

        if (exists $nodes->{$stampName}) {
            print fh ",".join(",",@{$nodes->{$stampName}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "-1";
            }
            print fh ",".join(",",($missing) x scalar(@nodesCols));
        }

        if (exists $admin->{$stampName}{$period}) {
            print fh ",".join(",",@{$admin->{$stampName}{$period}});
        } else {
            my $missing = "";
            if ($allowmissing eq "no") {
                $missing = "0";
            }
            print fh ",".join(",",($missing) x scalar(@adminCols));
        }
        
        print fh "\n";
    }
}
close(fh);
