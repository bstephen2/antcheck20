package Meson;

#
#	This package does all the mysql stuff
#
use warnings;
use English '-no_match_vars';
use strict;
use Readonly;
use DBI;

Readonly::Scalar my $SERVER           => 'localhost';
Readonly::Scalar my $DB               => 'meson';
Readonly::Scalar my $USER             => 'bstephen';
Readonly::Scalar my $PASSWORD         => 'rice37';
Readonly::Scalar my $GET_FEATS_SQL    => 'SELECT UNCOMPRESS(class) FROM classol WHERE pid = %d';
Readonly::Scalar my $GET_FEAT_FID_SQL => 'SELECT fid FROM meson_feature WHERE text = \'%s\'';
Readonly::Scalar my $GET_PIDS_WITH_FID =>
  'SELECT pid from meson_keyclass WHERE (fid = %d) AND (pid NOT IN %s )';
Readonly::Scalar my $INSERT_HIT => 'INSERT INTO antcheck SET pid = %d, aid = %d, score = %f';

#Readonly::Scalar my $GET_PID_SQL => 'SELECT pid FROM problem WHERE (stip = \'#2\') AND (sound = \'SOUND\')';

Readonly::Scalar my $GET_PID_SQL =>
  'SELECT pid FROM problem WHERE (stip = \'#2\') AND (sound = \'SOUND\') AND (gbr REGEXP \'^3\')';
Readonly::Scalar my $TRUNCATE_SQL => 'TRUNCATE TABLE antcheck';

Readonly::Scalar my $EID_SQL => 'SELECT eid FROM problem WHERE pid = %d';

my @not_sql = (
    'SELECT caid FROM cants WHERE pid = %d',
    'SELECT cabid FROM cabs WHERE pid = %d',
    'SELECT said FROM sants WHERE pid = %d',
    'SELECT sabid FROM sabs WHERE pid = %d',
    'SELECT aid FROM nots WHERE pid = %d',
    'SELECT aid FROM afters WHERE pid = %d',
    'SELECT aid FROM versions WHERE pid = %d',
);

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

sub get_eid {
    my ( $r_self, $pid ) = @_;
    my $sth;
    my $r_row;
    my $eid;

    my $sql = sprintf $EID_SQL, $pid;

    $sth = $r_self->{DBH}->prepare($sql);
    $sth->execute();
    $r_row = $sth->fetchrow_arrayref;
    $eid   = $r_row->[0];
    $sth->finish();

    return $eid;
}

sub insert_hit {
    my ( $r_self, $pid, $aid, $score ) = @_;
    my $sth;
    my $sql = sprintf $INSERT_HIT, $pid, $aid, $score;

    $sth = $r_self->{DBH}->prepare($sql);
    $sth->execute();
    $sth->finish();

    return;
}

sub truncate_antcheck {
    my $r_self = shift;
    my $sth;

    $sth = $r_self->{DBH}->prepare($TRUNCATE_SQL);
    $sth->execute();
    $sth->finish();

    return;
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

sub get_nots {
    my ( $r_self, $r_array, $pid ) = @_;
    my $r_row;
    my $sth;

    foreach my $notsql (@not_sql) {
        my $sql = sprintf $notsql, $pid;
        $sth = $r_self->{DBH}->prepare($sql);
        $sth->execute();

        while ( $r_row = $sth->fetchrow_arrayref ) {
            push @{$r_array}, $r_row->[0];
        }

        $sth->finish();
    }

    return;
}

sub get_features {
    my ( $r_self, $pid ) = @_;
    my $r_row;
    my $sth;
    my $rc;

    my $sql = sprintf $GET_FEATS_SQL, $pid;
    $sth = $r_self->{DBH}->prepare($sql);
    $sth->execute();
    $r_row = $sth->fetchrow_arrayref;
    $rc    = $r_row->[0];
    $sth->finish();

    return $rc;
}

sub get_potential_pids {
    my ( $r_self, $patt, $nots, $r_array ) = @_;
    my $r_row;
    my $sth;
    my $fid;

    my $sql = sprintf $GET_FEAT_FID_SQL, $patt;
    $sth = $r_self->{DBH}->prepare($sql);
    $sth->execute();
    $r_row = $sth->fetchrow_arrayref;
    $fid   = $r_row->[0];
    $sth->finish();

    $sql = sprintf $GET_PIDS_WITH_FID, $fid, $nots;
    $sth = $r_self->{DBH}->prepare($sql);
    $sth->execute();

    while ( $r_row = $sth->fetchrow_arrayref ) {
        push @{$r_array}, $r_row->[0];
    }

    $sth->finish();

    return;
}

sub close_db {
    my $r_self = shift;

    $r_self->{DBH}->disconnect();

    return;
}

1;
