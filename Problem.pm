package Problem;

#
#	This package is for the Problem class
#
use warnings;
use English '-no_match_vars';
use strict;
use XML::LibXML;
use Readonly;

Readonly::Scalar my $RUBICON => 95.00;
Readonly::Scalar my $HUNDRED => 100.00;

our $VERSION = 2.0;

sub new {
    my ( $class, $dbase, $pid ) = @_;
    my $r_self = {};

    $r_self->{DBASE}     = $dbase;
    $r_self->{PID}       = $pid;
    $r_self->{NOTS}      = [];
    $r_self->{ACTPATTS}  = [];
    $r_self->{NOTSTEXT}  = undef;
    $r_self->{HITS}      = [];
    $r_self->{FEATS}     = undef;
    $r_self->{HIT_COUNT} = 0;

    my $r_array = $r_self->{NOTS};
    push @{$r_array}, $pid;

    bless $r_self, $class;
    return $r_self;
}

sub process {
    my $r_self  = shift;
    my $r_array = $r_self->{NOTS};

    $r_self->{DBASE}->get_nots( $r_array, $r_self->{PID} );
    $r_self->get_text_nots();
    $r_self->{FEATS} = $r_self->{DBASE}->get_features( $r_self->{PID} );
    $r_self->get_actual_patts();
    $r_self->get_potential_hits();

    return;
}

sub get_potential_hits {
    my $r_self = shift;
    my %other_pids;
    my $r_array     = $r_self->{ACTPATTS};
    my $nots        = $r_self->{NOTSTEXT};
    my $r_hits      = $r_self->{HITS};
    my $total_patts = scalar @{$r_array};

    for my $patt ( @{$r_array} ) {
        my $r_pids = [];
        $r_self->{DBASE}->get_potential_pids( $patt, $nots, $r_pids );

        foreach my $pid ( @{$r_pids} ) {

            if ( exists $other_pids{$pid} ) {
                ( $other_pids{$pid} )++;
            }
            else {
                $other_pids{$pid} = 1;
            }
        }
    }

    while ( ( my $key, my $value ) = each %other_pids ) {
        my $pc = ( $value * $HUNDRED ) / $total_patts;

        if ( $pc > $RUBICON ) {
            push @{$r_hits}, $key;
            $r_self->{DBASE}->insert_hit( $r_self->{PID}, $key, $pc );
            ( $r_self->{HIT_COUNT} )++;
        }
    }

    return;
}

sub get_text_nots {
    my $r_self = shift;
    my $pid;
    my $text    = '( ';
    my $r_array = $r_self->{NOTS};
    my $count   = scalar @{$r_array};

    if ( $count > 1 ) {
        foreach my $p ( 1 .. ( $count - 1 ) ) {
            $pid = pop @{$r_array};
            $text .= "$pid, ";
        }
    }

    $pid = pop @{$r_array};
    $text .= "$pid )";

    $r_self->{NOTSTEXT} = $text;

    return;
}
## no critic (ProhibitEscapedMetacharacters)

sub get_actual_patts {
    my $r_self  = shift;
    my $r_array = $r_self->{ACTPATTS};
    my $text;

    my $doc     = XML::LibXML->load_xml( string => $r_self->{FEATS} );
    my $root    = $doc->getDocumentElement();
    my @actuals = $root->getChildrenByTagName('Actual');
    my @keys    = $actuals[0]->getChildrenByTagName('Key');
    my @threats = $actuals[0]->getChildrenByTagName('Threat');
    my @vars    = $actuals[0]->getChildrenByTagName('Var');

    $text = $keys[0]->firstChild()->textContent();
    $text = 'KEY::' . $text;
    $text =~ s/\(\w\)/\(\)/gsmx;
    push @{$r_array}, $text;

    if ( scalar @threats == 1 ) {
        $text = $threats[0]->firstChild()->textContent();
        $text = 'THREAT::' . $text;
        $text =~ s/\(\w\)/\(\)/gsmx;
        push @{$r_array}, $text;
    }

    foreach my $var (@vars) {
        $text = $var->firstChild()->textContent();
        $text =~ s/\(\w\)/\(\)/gsmx;
        push @{$r_array}, $text;
    }

    return;
}

## use critic

sub get_hit_count {
    my $r_self = shift;

    return $r_self->{HIT_COUNT};
}

sub get_hits {
    my $r_self = shift;

    return $r_self->{HITS};
}

1;
