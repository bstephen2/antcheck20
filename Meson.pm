package Meson;

#
#	This package does all the mysql stuff
#
use warnings;
use English '-no_match_vars';
use strict;
use Readonly;
use DBI;

Readonly::Scalar my $SERVER      => 'localhost';
Readonly::Scalar my $DB          => 'meson';
Readonly::Scalar my $USER        => 'bstephen';
Readonly::Scalar my $PASSWORD    => 'rice37';
Readonly::Scalar my $GET_PID_SQL => 'SELECT pid FROM problem WHERE (stip = \'#2\') AND (sound = \'SOUND\')';

our $VERSION = 2.0;

sub new {
    my $class  = shift;
    my $r_self = {};

    $r_self->{DBH} = undef;

    my $dbh;
    my %attr = ( PrintError => 0, RaiseError => 0 );
    my $parms = sprintf 'dbi:mysql:%s:%s', $DB, $SERVER;

    ## no critic (ProhibitPostfixControls)
    do {
        $dbh = DBI->connect( $parms, $USER, $PASSWORD, \%attr );
    } until ( defined $dbh );
    ## use critic

    $r_self->{DBH} = $dbh;

    bless $r_self, $class;
    return $r_self;
}

sub get_pids {
    my ( $r_self, $threads, $r_pids_one, $r_pids_two ) = @_;
    my $r_row;
    my $sth;
    my $count = 0;

    $sth = $r_self->{DBH}->prepare($GET_PID_SQL);
    $sth->execute();

    while ( $r_row = $sth->fetchrow_arrayref ) {

        if ( $threads == 2 ) {
            if ( ( $count & 2 ) == 0 ) {
                push @{$r_pids_one}, $r_row->[0];
            }
            else {
                push @{$r_pids_two}, $r_row->[0];
            }
        }
        else {
            push @{$r_pids_one}, $r_row->[0];
        }

        $count++;
    }

    $sth->finish();

    return $count;
}

sub close_db {
    my $r_self = shift;

    $r_self->{DBH}->disconnect();

    return;
}

1;
