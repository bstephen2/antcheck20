package Timer;

#
#	This package does the timing for antcheck.pl
#
use warnings;
use English '-no_match_vars';
use strict;
use Readonly;
use Time::HiRes qw(gettimeofday);

our $VERSION = 2.0;

sub new {
    my $class  = shift;
    my $r_self = {};

    $r_self->{START} = undef;
    $r_self->{END}   = undef;

    bless $r_self, $class;
    return $r_self;
}

sub start {
    my $r_self = shift;

    $r_self->{START} = gettimeofday();

    return;
}

sub end {
    my $r_self = shift;

    $r_self->{END} = gettimeofday();

    return;
}

sub get_elapsed_time {
    my $r_self = shift;

    return ( $r_self->{END} - $r_self->{START} );
}

1;
