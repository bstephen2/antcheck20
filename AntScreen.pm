package AntScreen;

#	AntCheck.pm
#	(c) 2020, B D Stephenson
#	bds@bstephen.me.uk

#   A class for the console screen. It is extant during the whole course of
#   AntCheck and serves to record information about the program and
#   itsprogress.

#	Except as otherwise stated, this Perl script meets the default standards
#	set by 'Perl Best Practices' by Damian Conway (O'Reilly). It has been
#	tested by Perl::Critic and has passed with no violations.

use warnings;
use English '-no_match_vars';
use strict;
use Readonly;
use Curses;

our $VERSION = '2.0';

Readonly::Scalar my $PROG_NAME   => 'AntCheck';
Readonly::Scalar my $COPY_RIGHT  => '(c) 2020, B D Stephenson';
Readonly::Scalar my $HEAD_LINE   => 0;
Readonly::Scalar my $PREP_LINE   => 2;
Readonly::Scalar my $CHECK_LINE1 => 3;
Readonly::Scalar my $CHECK_LINE2 => 4;
Readonly::Scalar my $HIT_LINE1   => 5;
Readonly::Scalar my $HIT_LINE2   => 6;
Readonly::Scalar my $L_MARGIN    => 0;
Readonly::Scalar my $INSET       => 25;
Readonly::Scalar my $PAUSE_LINE  => 10;

sub new {
    my $class  = shift;
    my $r_self = {};
    my $header = sprintf '%s (v. %s) - %s', $PROG_NAME, $VERSION, $COPY_RIGHT;

    initscr;
    addstr($header);

    move( $PREP_LINE, $L_MARGIN );
    addstr('           #2s prepared:');
    move( $CHECK_LINE1, $L_MARGIN );
    addstr(' #2s checked (Thread 1):');
    move( $CHECK_LINE2, $L_MARGIN );
    addstr(' #2s checked (Thread 2):');
    move( $HIT_LINE1, $L_MARGIN );
    addstr('        Hits (Thread 1):');
    move( $HIT_LINE2, $L_MARGIN );
    addstr('        Hits (Thread 2):');

    refresh;

    bless $r_self, $class;
    return $r_self;
}

sub update_prepared {
    my $in = shift;
    my $number = sprintf '%5d', $in;

    move( $PREP_LINE, $INSET );
    addstr($number);
    refresh;

    return;
}

sub update {
    my ( $thr, $type, $in ) = @_;
    my $number = sprintf '%5d', $in;
    my $l;

    if ( $type == 0 ) {
        $l = ( $thr == 1 ) ? 3 : 4;
    }
    else {
        $l = ( $thr == 1 ) ? 5 : 6;
    }

    move( $l, 25 );
    addstr($number);
    refresh;

    return;
}

sub close {

    getch();
    endwin;

    return;
}

1;
