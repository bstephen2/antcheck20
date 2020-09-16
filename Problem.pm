package Problem;

#
#	This package is for the Problem class
#
use warnings;
use English '-no_match_vars';
use strict;
use XML::LibXML;
use Readonly;

Readonly::Scalar my $RUBICON1        => 90.00;
Readonly::Scalar my $RUBICON2        => 95.00;
Readonly::Scalar my $HUNDRED         => 100.00;
Readonly::Scalar my $EXTRA_PATTERN   => -0.5;
Readonly::Scalar my $STANDARD_WEIGHT => 1.0;
Readonly::Scalar my $EMPTY           => q{};
Readonly::Scalar my $WHITES          => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
Readonly::Scalar my $BLACKS          => 'abcdefghijklmnopqrstuvwxyz';

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
    $r_self->{NUM_ACTUAL_VARS}  = 0;
    $r_self->{NEXT_WHITE}       = 0;
    $r_self->{NEXT_BLACK}       = 0;
    $r_self->{TRANS}            = {};

    my $r_array = $r_self->{NOTS};
    push @{$r_array}, $pid;

    bless $r_self, $class;
    return $r_self;
}

sub process {
    my $r_self  = shift;
    my $r_array = $r_self->{NOTS};
    my $eid;

    $r_self->{DBASE}->get_nots( $r_array, $r_self->{PID} );
    $eid = $r_self->{DBASE}->get_eid( $r_self->{PID} );

    if ( ( defined $eid ) && ( $eid != 0 ) ) {
        push @{$r_array}, $eid;
    }

    $r_self->get_text_nots();
    $r_self->get_patterns();

    # TODO How to find anticipations of problems with only dualled variations? The following test ensures
    # that they are not tested.

    if ( $r_self->{NUM_ACTUAL_VARS} > 0 ) {
        $r_self->get_potential_hits();
    }

    return;
}

sub get_potential_hits {
    my $r_self = shift;
    my %other_pids;
    my $r_hash = $r_self->{ACTUAL_PATTERNS};
    my $nots   = $r_self->{NOTSTEXT};
    my $r_hits = $r_self->{HITS};

    my $total_patts = scalar keys %{$r_hash};

    foreach my $patt ( keys %{$r_hash} ) {
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

        if ( $pc > $RUBICON1 ) {
            $r_self->compare_problems($key);
        }
    }

    return;
}

sub compare_problems {
    my ( $r_self, $other_pid ) = @_;
    my $total_value   = 0.0;
    my $compare_value = 0.0;
    my $pc;
    my $extras;
    my $r_other = Problem->new( $r_self->{DBASE}, $other_pid );

    $r_other->get_patterns();

    while ( ( my $key, my $r_array ) = each %{ $r_self->{ACTUAL_PATTERNS} } ) {
        foreach my $r_hash ( @{$r_array} ) {
            $total_value += $STANDARD_WEIGHT;
            $r_hash->{CONVERTED} = $r_self->translate_pieces( $r_hash->{PIECES} );

            if ( $r_other->is_pattern_matched( $key, $r_hash->{CONVERTED} ) == 1 ) {
                $compare_value += $STANDARD_WEIGHT;
            }
        }
    }

    $extras = $r_other->get_extras_count();

    $compare_value += ( $extras * $EXTRA_PATTERN );

    $pc = ( $compare_value * $HUNDRED ) / $total_value;

    if ( $pc >= $RUBICON2 ) {
        $r_self->{DBASE}->insert_hit( $r_self->{PID}, $other_pid, $pc );
        ( $r_self->{HIT_COUNT} )++;
    }

    return;
}

sub get_extras_count() {
    my $r_self = shift;
    my $extras = 0;

    while ( ( my $key, my $r_array ) = each %{ $r_self->{ACTUAL_PATTERNS} } ) {
        foreach my $r_hash ( @{$r_array} ) {
            if ( $r_hash->{MATCHED} == 0 ) {
                $extras++;
            }
        }
    }

    return $extras;
}

sub is_pattern_matched {
    my ( $r_self, $patt, $converted ) = @_;
    my $rc = 0;

    my $r_patts = $r_self->{ACTUAL_PATTERNS};

    if ( exists $r_patts->{$patt} ) {
        my $r_array = $r_patts->{$patt};

        foreach my $r_hash ( @{$r_array} ) {

            if ( $r_hash->{MATCHED} == 0 ) {
                $r_hash->{CONVERTED} = $r_self->translate_pieces( $r_hash->{PIECES} );

                if ( $converted eq $r_hash->{CONVERTED} ) {
                    $r_hash->{MATCHED} = 1;
                    $rc = 1;
                    last;
                }
            }
        }
    }

    return $rc;
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
    my $actual_vars = 0;
    $r_self->{FEATS} = $r_self->{DBASE}->get_features( $r_self->{PID} );

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
    $r_array             = [];
    $r_dict              = {};
    $r_dict->{PIECES}    = $r_self->get_pieces($raw_text);
    $r_dict->{MATCHED}   = 0;
    $r_dict->{CONVERTED} = 0;
    push @{$r_array}, $r_dict;

    $r_hash->{$text} = $r_array;

    if ( scalar @threats == 1 ) {
        $text     = $threats[0]->firstChild()->textContent();
        $text     = 'THREAT::' . $text;
        $raw_text = $text;
        $text =~ s/\(\w\)/\(\)/gsmx;
        $r_array             = [];
        $r_dict              = {};
        $r_dict->{PIECES}    = $r_self->get_pieces($raw_text);
        $r_dict->{MATCHED}   = 0;
        $r_dict->{CONVERTED} = 0;
        push @{$r_array}, $r_dict;

        $r_hash->{$text} = $r_array;
    }

    foreach my $var (@vars) {
        $actual_vars++;
        $text     = $var->firstChild()->textContent();
        $raw_text = $text;
        $text =~ s/\(\w\)/\(\)/gsmx;
        $r_dict              = {};
        $r_dict->{PIECES}    = $r_self->get_pieces($raw_text);
        $r_dict->{MATCHED}   = 0;
        $r_dict->{CONVERTED} = 0;

        if ( exists $r_hash->{$text} ) {
            $r_array = $r_hash->{$text};
            push @{$r_array}, $r_dict;
        }
        else {
            $r_array = [];
            push @{$r_array}, $r_dict;

            $r_hash->{$text} = $r_array;
        }
    }

    $r_self->{NUM_ACTUAL_VARS} = $actual_vars;

    return;
}

## use critic

## no critic (ProhibitEscapedMetacharacters)

sub get_pieces {
    my ( $r_self, $patt ) = @_;
    my $rstr = $EMPTY;

    #$text =~ s/\(\w\)/\(\)/gsmx;

    while ( $patt =~ m/\((\w)\)/gsmx ) {
        $rstr .= $1;
    }

    return $rstr;
}

## use critic

sub translate_pieces {
    my ( $r_self, $pieces ) = @_;
    my $rstr   = $EMPTY;
    my $r_hash = $r_self->{TRANS};
    my $len    = length $pieces;

    foreach my $i ( 0 .. ( $len - 1 ) ) {
        my $ch = substr $pieces, $i, 1;

        if ( exists( $r_hash->{$ch} ) ) {
            $rstr .= $r_hash->{$ch};
        }
        else {
            my $tch;
            my $j;

            if ( $ch =~ m/\p{Uppercase}/sxm ) {
                $j = $r_self->{NEXT_WHITE};
                $tch = substr $WHITES, $j, 1;
                $j++;
                $r_self->{NEXT_WHITE} = $j;
            }
            else {
                $j = $r_self->{NEXT_BLACK};
                $tch = substr $BLACKS, $j, 1;
                $j++;
                $r_self->{NEXT_BLACK} = $j;
            }

            $rstr .= $tch;
            $r_hash->{$ch} = $tch;
        }
    }

    return $rstr;
}

sub get_hit_count {
    my $r_self = shift;

    return $r_self->{HIT_COUNT};
}

1;
