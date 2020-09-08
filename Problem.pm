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
Readonly::Scalar my $EMPTY   => q{};

our $VERSION = 2.0;

sub new {
    my ( $class, $dbase, $pid ) = @_;
    my $r_self = {};

    $r_self->{DBASE}            = $dbase;
    $r_self->{PID}              = $pid;
    $r_self->{NOTS}             = [];
    $r_self->{ACTUAL_PATTERNS}  = {};
    $r_self->{SET_PATTERNS}     = {};
    $r_self->{VIRTUAL_PATTERNS} = {};
    $r_self->{NOTSTEXT}         = undef;
    $r_self->{HITS}             = [];
    $r_self->{FEATS}            = undef;
    $r_self->{HIT_COUNT}        = 0;

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
    $r_self->get_patterns();
    $r_self->get_potential_hits();

    return;
}

sub get_potential_hits {
    my $r_self = shift;
    my %other_pids;
    my $r_hash = $r_self->{ACTUAL_PATTERNS};
    my $nots   = $r_self->{NOTSTEXT};
    my $r_hits = $r_self->{HITS};
    my $count  = 0;

    my $total_patts = scalar keys %{$r_hash};

    foreach my $patt ( keys %{$r_hash} ) {
        $count++;
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

    if ( $count > 3 ) {
        while ( ( my $key, my $value ) = each %other_pids ) {
            my $pc = ( $value * $HUNDRED ) / $total_patts;

            if ( $pc > $RUBICON ) {
                push @{$r_hits}, $key;
                $r_self->{DBASE}->insert_hit( $r_self->{PID}, $key, $pc );
                ( $r_self->{HIT_COUNT} )++;
            }
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

sub get_patterns {
    my $r_self = shift;
    my $r_hash = $r_self->{ACTUAL_PATTERNS};
    my $text;
    my $raw_text;
    my $r_array;
    my $r_dict;

    my $doc     = XML::LibXML->load_xml( string => $r_self->{FEATS} );
    my $root    = $doc->getDocumentElement();
    my @actuals = $root->getChildrenByTagName('Actual');
    my @keys    = $actuals[0]->getChildrenByTagName('Key');
    my @threats = $actuals[0]->getChildrenByTagName('Threat');
    my @vars    = $actuals[0]->getChildrenByTagName('Var');

    $text     = $keys[0]->firstChild()->textContent();
    $text     = 'KEY::' . $text;
    $raw_text = $text;
    $text =~ s/\(\w\)/\(\)/gsmx;
    $r_array           = [];
    $r_dict            = {};
    $r_dict->{PIECES}  = get_pieces($raw_text);
    $r_dict->{MATCHED} = 0;
    push @{$r_array}, $r_dict;

    $r_hash->{$text} = $r_array;

    if ( scalar @threats == 1 ) {
        $text     = $threats[0]->firstChild()->textContent();
        $text     = 'THREAT::' . $text;
        $raw_text = $text;
        $text =~ s/\(\w\)/\(\)/gsmx;
        $r_array           = [];
        $r_dict            = {};
        $r_dict->{PIECES}  = get_pieces($raw_text);
        $r_dict->{MATCHED} = 0;
        push @{$r_array}, $r_dict;

        $r_hash->{$text} = $r_array;
    }

    foreach my $var (@vars) {
        $text     = $var->firstChild()->textContent();
        $raw_text = $text;
        $text =~ s/\(\w\)/\(\)/gsmx;
        $r_dict            = {};
        $r_dict->{PIECES}  = get_pieces($raw_text);
        $r_dict->{MATCHED} = 0;

        if ( exists $r_hash->{$text} ) {
            $r_array = $r_hash->{$text};
            push @{$r_array}, $r_dict;
        }
        else {
            $r_array = [];
            $r_dict  = {};
            push @{$r_array}, $r_dict;

            $r_hash->{$text} = $r_array;
        }
    }

    return;
}

## use critic

sub get_pieces {
    my $patt = shift;
    my $rstr = $EMPTY;
    my $len  = length $patt;
    my $ch;

    foreach my $i ( 0 .. ( $len - 3 ) ) {
        $ch = substr $patt, $i, 1;

        if ( $ch eq '(' ) {
            $rstr .= substr $patt, $i + 1, 1;
        }
    }

    return $rstr;
}

sub get_hit_count {
    my $r_self = shift;

    return $r_self->{HIT_COUNT};
}

sub get_hits {
    my $r_self = shift;

    return $r_self->{HITS};
}

1;
