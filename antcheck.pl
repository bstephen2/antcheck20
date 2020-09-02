#!/usr/bin/perl

#	antcheck.pl
#	(c) 2020, B D Stephenson
#	bds@bstephen.me.uk
#
#	This program attempts to find anticipations for all sound #2s in Meson.

#	Except as otherwise stated, this Perl script meets the default standards
#	set by 'Perl Best Practices' by Damian Conway (O'Reilly). It has been
#	tested by Perl::Critic and has passed with no violations.
#
#	USAGE:
#
#	antcheck.pl [--threads=n] [--set] [--tries]
#
#	VERSION HISTORY
#
#	2020/09/02	1.1	Initial controlled release.

use warnings;
use strict;
use English '-no_match_vars';
use threads;
use threads::shared;
use Readonly;
use Getopt::Long;
use ANTCHECK::Timer;
use ANTCHECK::AntScreen;

our $VERSION = 2.0;

my $sets    = 0;
my $tries   = 0;
my $threads = 2;
my $timer;
my $rc;
my $screen;

$timer = Timer->new();
$timer->start();

GetOptions( 'threads=i' => \$threads, 'set' => \$sets, 'tries' => \$tries );
( $sets == 1 )  && ( die "--set not yet implemented\n" );
( $tries == 1 ) && ( die "--tries not yet implemented\n" );
( $threads != 1 ) && ( $threads != 2 ) && ( die "--threads must be 1 or 2\n" );

$screen = AntScreen->new();
$screen->close();

$timer->end();
$rc = printf "antcheck.pl finished (sets = %d, tries = %d, threads = %d)\n", $sets, $tries, $threads;
$rc = printf "Time taken = %0.5f seconds\n", $timer->get_elapsed_time();

exit 0;
