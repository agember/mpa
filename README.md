Management Plane Analytics (MPA)

== ENVIRONMENT SETUP ==========================================================
MPA uses a combination of tools to conduct its analysis. To use MPA, you must
have the following installed:
- Perl
- R (http://www.r-project.org)

You can install these tools in Ubuntu by running the following command:

    sudo apt-get install perl r-base gnuplot

Before running any analysis, you must set two environment variables:
- MGMTPLANE_DATA: set this to the directory where all data will be stored; see
  the DATA section for details on the format and layout of the raw data
- MGMTPLANE_CODE: set this to the directory where the MPA scripts reside; in
  other words, the directory containing this README

== DATA ======================================================================
MPA uses four forms of raw data to conduct its analysis: device configuration
snapshots, inventory information, ticket logs, and a list of user accounts
associated with automated scripts.

=== CONFIGURATION SNAPSHOTS ===
Device configuration snapshots are the raw configurations for each device in
each network at different points in time. The snapshots should be organized in
a heirarchical directory structure as follows:

    MGMTPLANE_DATA
        uncompcfgs
            network1
                device1a
                    metadata.txt
                    YYYY-MM-DD-HH-MM-SS.cfg
                    ...
                device1b
                    metadata.txt
                    YYYY-MM-DD-HH-MM-SS.cfg
                    ...
                ...
            network2
                device 2a
                    metadata.txt
                    YYYY-MM-DD-HH-MM-SS.cfg
                    ...
                device 2b
                    metadata.txt
                    YYYY-MM-DD-HH-MM-SS.cfg
                    ...
                ...
            ...

The top level directory should be the directory referenced by the 
MGMTPLANE_DATA environment variable. The second level directory should be a
directory named "uncompcfgs," which stands for uncompressed configurations; 
depending on how device configurations are archived, they may need to be 
uncompressed in some way in order to conform to the directory structure MPA
expects.

Within uncompcfgs, there should be a directory for each network. Any naming 
convention can be used for these directories. Within each network directory,
there should be a directory for each device. Again, any naming convention can
be used for these directories. However, device names must be globally unique.

Each device directory should contain the raw configuration snapshots for that 
device. Each snapshot should be in its own file. Files should be named based on
the date and time the snapshots was taken, using the format YYYY-MM-DD-HH-MM-SS
(year-month-day-hour-minute-second). The files should end with the extension
".cfg". 

=== INVENTORY INFORMATION ===
Each device directory should also contain a file called metadata.txt that
contains inventory information pertaining to that device. The file must contain at least three lines:

    DeviceType: TYPE
    Vendor: VENDOR
    Model: MODEL

TYPE specifies the device's primary function: e.g., switch, router, firewall,
load balancer. VENDOR specifies the device manufacturer: e.g., Cisco, Juniper,
Arista. MODEL specifies the device model: e.g., Nexus 3K, Nexus 5K, MX5, MX10. 

The metadata file may optionally contain additonal lines with other inventory
information, where each line follows the format:

    KEY: VALUE

=== TICKET LOG ===
The ticket log should be a comma separated variable (CSV) file containing the
following columns:
- Device name: this should match the name used for the directory containing the
  device's configuration snapshots and inventory information
- Start date and time: the date and time the problem started (or the ticket was
  created); data must following the format: MM/DD/YYYY HH:MM:SS ?M
  (month/day/year hour:minute:second AM/PM)
- Duration: how long it took to resolve the problem (or close the ticket);
  should be specified (as an integer) in minutes
- Packet loss: the percent packet loss, if applicable; packet loss is specified
  as a decimal value between 0 and 100; if not applicable, then use "N/A"
- Ticket id: a unique integer identifier for the ticket
- Ticket description: a description of the problem and solution, if available
- Is maintenance: indicates if the ticket was opened for scheduled maintenance;
  the value should be "YES" or "NO"

The file should be called "events.csv" and be located in the directory
specified in the MGMTPLANE_DATA environment variable.

=== USER ACCOUNTS FOR AUTOMATED CHANGES ===
A list of usernames for accounts that perform automated configuration changes
should be named "env_autousers.txt" and placed in MGMTPLANE_DATA. There should
be one username per line.

=== ROLES ===
A list of device roles and their category (middlebox or forwarding) should 
be named "env_roles.txt" and placed in MGMTPLANE_DATA. There should be one role
per line:
    DeviceRole,Category
DeviceRole should be the roles specified in the metadata.txt files mentioned
above; there should not be any spaces in the role. Category should be 'mbox' 
or 'fwd'.

== EXTRACTING BASIC METRICS ===================================================
MPA provides many scripts to extract metrics from the raw data. All scripts
should be stored in the directory specified in the MGMTPLANE_CODE environment
variable. Scripts should be run as follows:

1) Summarize device hardware information from inventory information:

        cd MGMTPLANE_CODE/extract/
        perl device_hardware.pl

2) Generate diffs of successive device configuration snapshots:

        cd MGMTPLANE_CODE/diffs/
        perl indent_all_configs.pl
        perl diff_configs.pl

3) Summarize change information from configuration diffs:
    
        cd MGMTPLANE_CODE/extract/
        perl change_frequency.pl [WINDOW [SPLIT [STARTDATE ENDDATE]]]

   The optional WINDOW argument specifies the time window in seconds over which
   two changes should be considered part of the same change event. The optional
   SPLIT argument specifies whether to split data by days (e.g., "1d" for daily
   and "7d" for weekly) or months (e.g., "1m" for monthly and "3m" for
   quarterly); if not specified, then data is not subdivided by time.  The
   optional STARTDATE and ENDDATE arguments specify the range of dates whose
   changes should be included.

4) Summarize ticket information from ticket logs:

        perl ticket_count.pl [SPLIT [STARTDATE ENDDATE]]
   
   All arguments are similar to change_frequency.pl. Use the same argument
   values you used when invoking change_frequency.pl.

5) Combine all extracted metrics into a single file:
    
        perl metrics_combine_basic.pl

== EXTRACTING ADVANCED METRICS ================================================
To extract additional metrics, complete steps 1-4 above, then run the following 
scripts:

1) Determine which stanzas were added/removed/changed in successive device
   configuration stanpshots:

        cd MGMTPLANE_CODE/diffs/
        perl process_all_diffs.pl

2) Summarize stanza changes:
    
        cd MGMTPLANE_CODE/extract/
        perl change_stanzas.pl [WINDOW [SPLIT [STARTDATE ENDDATE]]]

   All arguments are similar to prior scripts. Use the same argument values you
   used when invoking other scripts.

        perl change_stanza_automation.pl

3) Summarize protocol information from device configuration snapshots:
   First, generate a list of configs from which to summarize this information:
   
        perl generate_config_list.pl [SPLIT [STARTDATE ENDDATE]]

   All arguments are similar to prior scripts. Use the same argument values you
   used when invoking other scripts.

   Second, parse the configs to extract the relevant protocol information:

        mkdir MGMTPLANE_DATA/batfish/
        cd MGMTPLANE_CODE/batfish-mpa/mpa/out/
        java -jar mpa.jar MGMTPLANE_DATA/config_list.txt \
            MGMTPLANE_DATA/uncompcfgs MGMTPLANE_DATA/batfish

   Third, combine the protocol information from all of stamp's devices on a
   per-period basis:

        cd MGTMPLANE_CODE/extract/
        perl device_protocols.pl

4) Summarize device firmware information from device configuration snapshots:
   First, generate a list of all firmware changes:

        perl device_firmware.pl 

    Second, combine the firmware information from all of stamp's devices on a
    per-period basis:

        perl firmware_hetero.pl

5) Create binary variables for the presence of specific roles, vendors, and
   models in the network:

        perl role_present.pl
        perl vendor_present.pl
        perl model_present.pl
       
6) Determines the architecture for each stamp:

        perl stamp_architecture.pl
        perl arch_present.pl

   FIXME: The stamp_architecture.pl script is specific to the organization
   whose configurations are used in the IMC paper.

7) Summarize a network's connectivity:

        cd MGMTPLANE_CODE/topos/
        perl physical_links.pl
        perl graph.pl [yes|no [yes|no [yes|no]]]

    The yes/no arguments specify whether to: generate topology graphs, 
    exclude devices not contained in any stamp, and exclude devices contained
    in other stamps, respectively.
        
8) FIXME: Determine how to extract complexity information

9) Combine all extracted metrics into a single file:
    
        perl metrics_combine_all.pl [yes|no [STARTDATE ENDDATE]]

   The first optional argument specifies whether to allow missing values (yes) 
   or replace missing values with -1 (no); default is 'yes'. The optional
   STARTDATE and ENDDATE arguments specify the range of dates whose metrics
   should be included.

10)Filter extract metrics to exclude earlier periods for which we do not have
   data for a network, and (optionally) exclude networks for which we do not 
   have data from the entire desired date range:

        perl metrics_range.pl STARTDATE ENDDATE
        perl metrics_filter.pl METRICSFILE STARTDATE ENDDATE [yes|no]
   
   The METRICSFILE argument specifies the name of the CSV file that contains
   the desired metrics; this file is output by metrics_combine_all.pl. The
   STARTDATE and ENDDATE arguments specify the range of dates whose metrics
   should be included. The optional yes/no argument specifies whether to
   exclude networks for which we do not have data from the entire specified
   date range; defaults to 'no'.

== PLOTTING METRICS ===========================================================
MPA uses R to generate plots. First, launch R from within the MGMTPLANE_DATA
directory:
    
    cd MGMTPLANE_DATA
    R

Next, load the metrics into R by running the following command within R:

    source('analyze/read_basic_metrics.R')

To generate specific plots, source the appropriate plot file within R, e.g.:

    source('plots/hotnets_size_vs_health.R')

The generated plots are stored in MGMTPLANE_DATA/plots.
