use strict;
use warnings;
use utf8;

package COF::RT_Checker;

use Encode qw/encode decode/;

our $NOLC_CAR = '*';


sub new {
    my ( $class, $rt ) = @_;
    return bless [$rt], $class;
}


sub has_word {
    my ( $self, $word ) = @_;
    $word = encode( "iso-8859-1", $word );
    return _node_check( $self->[0]->get_root(), $word );
}


sub get_words_ed1 {
    my ( $self, $word ) = @_;
    $word = encode( "iso-8859-1", $word );
    return
      map { decode( "iso-8859-1", $_ ) }
      _get_words( $self->[0]->get_root(), $word );
}


sub _node_check {
    my ( $node, $sufis ) = @_;
    while ( my $edge = $node->get_next_edge() ) {
        my $label = $edge->get_string();
        my $len_conf =
          length($label) > length($sufis) ? length($sufis) : length($label);
        my $res_conf =
          substr( $label, 0, $len_conf ) cmp substr( $sufis, 0, $len_conf );
        if ( $res_conf == -1 ) {
            next;
        }
        elsif ( $res_conf == 1 ) {
            return 0;
        }
        else { if ( length($label) > length($sufis) ) {
                return 0;
            }
            elsif ( length($label) == length($sufis) ) {
                return $edge->is_word();
            }
            else {
                if ( $edge->is_leaf() ) {
                    return 0;
                }
                else {
                    return _node_check( $edge->get_node(),
                        substr( $sufis, length($label) ) );
                }
            }
        }
    }
    return 0;
}

sub _edge_check {
    my ( $edge, $sufis ) = @_;
    my $label = $edge->get_string();
    my $len_conf =
      length($label) > length($sufis) ? length($sufis) : length($label);
    my $res_conf =
      substr( $label, 0, $len_conf ) cmp substr( $sufis, 0, $len_conf );
    if ($res_conf) { return 0;
    }
    else {
        if ( length($label) > length($sufis) ) {
            return 0;
        }
        elsif ( length($label) == length($sufis) ) {
            return $edge->is_word();
        }
        else {
            if ( $edge->is_leaf() ) {
                return 0;
            }
            else {
                return _node_check( $edge->get_node(),
                    substr( $sufis, length($label) ) );
            }
        }
    }
}

sub _get_words {
    my ( $node, $word ) = @_;
    my @words = ();
    while ( my $edge = $node->get_next_edge() ) {
        my $label = $edge->get_string();
        my $min_len =
          length($label) > length($word) ? length($word) : length($label);
        my $i;
        for (
            $i = 0 ;
            $i < $min_len
            && ( substr( $label, $i, 1 ) eq substr( $word, $i, 1 ) ) ;
            $i++
          )
        {
        }
        my $tmpw;
        my $case;
        if ( $i < $min_len ) {
            $tmpw =
                substr( $word, 0, $i )
              . substr( $label, $i, 1 )
              . substr( $word, $i + 1 );
            push( @words, $tmpw . ( $case == 2 ? $NOLC_CAR : '' ) )
              if $case = _edge_check( $edge, $tmpw );
            $tmpw =
                substr( $word, 0, $i )
              . substr( $label, $i, 1 )
              . substr( $word, $i );
            push( @words, $tmpw . ( $case == 2 ? $NOLC_CAR : '' ) )
              if $case = _edge_check( $edge, $tmpw );
            if ( length($word) > $i + 1
                && ( substr( $label, $i, 1 ) eq substr( $word, $i + 1, 1 ) ) )
            {
                $tmpw = substr( $word, 0, $i ) . substr( $word, $i + 1 );
                push( @words, $tmpw . ( $case == 2 ? $NOLC_CAR : '' ) )
                  if $case = _edge_check( $edge, $tmpw );
                $tmpw =
                    substr( $word, 0, $i )
                  . substr( $word, $i + 1, 1 )
                  . substr( $word, $i,     1 )
                  . substr( $word, $i + 2 );
                push( @words, $tmpw . ( $case == 2 ? $NOLC_CAR : '' ) )
                  if $case = _edge_check( $edge, $tmpw );
            }
        }
        elsif ( $i < length($word) ) {  push(
                @words,
                map( "$label$_",
                    _get_words( $edge->get_node(), substr( $word, $i ) ) )
            ) unless $edge->is_leaf();
            push( @words, $label . ( $case == 2 ? $NOLC_CAR : '' ) )
              if length($word) == $i + 1 && ( $case = $edge->is_word );
        }
        elsif ( $i < length($label) ) {
            push( @words, $label . ( $case == 2 ? $NOLC_CAR : '' ) )
              if length($label) == $i + 1 && ( $case = $edge->is_word );
        }
        else {  push( @words,
                map( "$label$_", _get_words( $edge->get_node(), '' ) ) )
              unless $edge->is_leaf();
        }
    }
    return @words;
}

1;
