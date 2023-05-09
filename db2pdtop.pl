#!/usr/bin/env perl
#
#   db2pdtop.pl  --  Display Db2 EDU CPU utilization statistics
#
#   Copyright (c) 2023 XTIVIA, Inc.
#
#   2023-04-14  Ian D. Bjorhovde <ibjorhovde@xtivia.com>
#

use Getopt::Long;
use Pod::Usage;
use strict;

my $sleep = 5;        # How long to sleep between invocations
my $nproc = 15;       # How many EDUs to display
my $batch = 0;        # clear screen between runs
my $iterations = -1;  # iterate forever

parseOptions();

if (! $ENV{'DB2INSTANCE'}) {
    print "Db2 environment not initialized.  Have you sourced the db2profile?\n";
    exit 1;
}

my $E;      # Hash reference for storing db2pd information

collectAndPrintData();
exit if $iterations == 1;

my $i = 0;
while(1) {
    if ($i < $iterations || $iterations == -1) {
        sleep $sleep;
        collectAndPrintData();
    } else {
        last;
    }
}


sub collectAndPrintData {

    my ($eduid, $usr, $sys, $deltau, $deltas, $totalCPU, $line);

    my $buf = "";
    if (! $batch) {
        $buf .= sprintf("\033[2J");    #clear the screen
        $buf .= sprintf("\033[0;0H");  #jump to 0,0
    }

    #
    # get top information
    #
    open(IN, "top -u $ENV{'DB2INSTANCE'} -bn 1 |") || die "can't execute top";
    while(<IN>) {
        if (/^\s?\d+ /) {
            if (/^\s?\d+ .* db2.*/) {
                $buf .= sprintf("%s", $_);
            }
        } else {
            $buf .= sprintf("%s", $_);
        }
        $line++;
    }
    close(IN);

    $totalCPU = 0;
    $line = 0;
    open(IN, "db2pd -edus |") || die "can't execute db2pd";
    while(<IN>) {

        #  Capture permission error from db2pd
        if (/db2pd can only be run/) {
            print "Error: " . $_;
            exit 1;
        }
	
        # print the first 8 lines of db2pd -edus output
        $buf .= sprintf("%s", $_) unless $line > 8;
        $line++;

        chomp;

        if (/(\d+)\s+(\d+)\s+(\d+)\s+(.*? \d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/) {
            $eduid = $1;

            if (! exists($E->{$eduid})) {
                $E->{$eduid}->{TID}  = $2;
                $E->{$eduid}->{KTID} = $3;
                $E->{$eduid}->{NAME} = $4;
                $E->{$eduid}->{USR}  = 0;
                $E->{$eduid}->{SYS}  = 0;
            }

            $usr = $5;
            $sys = $6;

            $deltau = $usr - $E->{$eduid}->{USR};
            $deltas = $sys - $E->{$eduid}->{SYS};

            $E->{$eduid}->{DELTA} = $deltau + $deltas;

            $E->{$eduid}->{USR}  = $usr;
            $E->{$eduid}->{SYS}  = $sys;

            $totalCPU += $deltau + $deltas;

        }
    }
    close(IN);

    # step through 
    $buf .= sprintf("%-8s %-30s %9s\n", "EDU ID", "EDU Name", "% db2sysc");
    $buf .= sprintf("%8s %30s %9s\n", "-" x 8, "-" x 30, "-" x 9);
    my $top = 0;
    foreach my $k (sort { $E->{$b}->{DELTA} <=> $E->{$a}->{DELTA} } keys %{$E} ) {
        $buf .= sprintf("%-8s %-30s %9.1f\n", $k, $E->{$k}->{NAME}, 100*$E->{$k}->{DELTA}/$totalCPU) unless $top >= $nproc;
        $top++;
    }
    $buf .= sprintf("\n\n");

    $i++;
    print $buf;

}


sub parseOptions {
    my %opt;
    my @opts = ('top:i',
                'delay:i',
                'batch',
                'number:i',
                'help|usage',
                'man');

    GetOptions(\%opt, @opts) || pod2usage(1);

    if ($opt{help}) {
        pod2usage(-verbose => 1);
    }

    if ($opt{man}) {
        pod2usage(-verbose => 2);
    }

    if ($opt{top}) {
        $nproc = $opt{top};
    }

    if ($opt{delay}) {
        $sleep = $opt{delay};
    }

    if ($opt{number}) {
        if ($opt{number} > 0) {
            $iterations = $opt{number};
        } else {
            pod2usage(-msg => "$0 --number must be a positive integer");
        }
    }

    if ($opt{batch}) {
        $batch = 1;
    }
}


########################################################################
#
#  Documentation (POD format - access with --man or --help options)
#

=head1 NAME

db2pdtop.pl - Show Db2 EDU CPU utilization statistics


=head1 SYNOPSIS

db2pdtop.pl [OPTION]...


=head1 OPTIONS

=over 8

=item B<-d, --delay> I<delay_time>

Update every I<delay_time> seconds.  Defaults to 5 seconds.

=item B<-t, --top> I<nprocs>

Display top I<nprocs> EDUs.  Defaults to 15.

=item B<-n, --number> I<number_of_iterations>

Specifies the maximum number of iterations, or frames, top should produce 
before ending.


=item B<-b, --batch>

Run in batch mode.  Useful for feeding into other scripts.


=item B<--help, --usage>

Print a usage statement for this utility and exit.


=item B<--man>

Print the manual page and exit.

=back

=head1 BUGS

When run interactively, the B<db2pdtop.pl> utility only supports Linux and 
UNIX environments.  On Windows, use the B<-b> option.

=head1 AUTHOR

Written by Ian D. Bjorhovde <ibjorhovde@xtivia.com>

=cut
