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
use Timer;
use AntScreen;
use Meson;
use Problem;

our $VERSION = 2.0;

my $sets    = 0;
my $tries   = 0;
my $threads = 2;
my $timer;
my $rc;
my $screen;
my $meson;
my @pids_one;
my @pids_two;
my $thread1;
my $thread2;
my $pid_count;
my $mutex : shared;

$timer = Timer->new();
$timer->start();

GetOptions( 'threads=i' => \$threads, 'set' => \$sets, 'tries' => \$tries );
( $sets == 1 )  && ( die "--set not yet implemented\n" );
( $tries == 1 ) && ( die "--tries not yet implemented\n" );
( $threads != 1 ) && ( $threads != 2 ) && ( die "--threads must be 1 or 2\n" );

$screen = AntScreen->new($threads);
$meson  = Meson->new();
$meson->truncate_antcheck();
$pid_count = $meson->get_pids( $threads, \@pids_one, \@pids_two );
$meson->close_db();

$screen->update_prepared($pid_count);

$thread1 = threads->new( \&find_matches, 1, \@pids_one );

if ( $threads == 2 ) {
    $thread2 = threads->new( \&find_matches, 2, \@pids_two );
}

$thread1->join();

if ( $threads == 2 ) {
    $thread2->join();
}

$screen->close_screen();

$timer->end();
$rc = printf "antcheck.pl finished (sets = %d, tries = %d, threads = %d)\n", $sets, $tries, $threads;
$rc = printf "Time taken = %0.5f seconds\n", $timer->get_elapsed_time();

exit 0;

sub find_matches {
    my ( $thr, $r_pids ) = @_;
    my $checked = 0;
    my $hits    = 0;
    my $dbase   = Meson->new();
    my $pid;

    $pid = pop @{$r_pids};

    while ( defined $pid ) {
        my $prb = Problem->new( $dbase, $pid );
        $prb->process();
        my $found = $prb->get_hit_count();

        if ( $found > 0 ) {
            $hits++;

            {
                lock $mutex;
                $screen->update_hits( $thr, $hits );
            }
        }

        $checked++;

        {
            lock $mutex;
            $screen->update_checked( $thr, $checked );
        }
        
        $pid = pop @{$r_pids};
    }

    $dbase->close_db();

    return;
}
