package COF::SpellChecker;

use strict;
use warnings;
use utf8;
use COF::Letters qw/$WORD_LETTERS/;

use constant {
    F_USER_EXC => 1000, F_SAME => 400, F_USER_DICT => 350, F_ERRS => 300, };

sub new {
    my ( $class, $data ) = @_;
    my $self = bless { data => $data, }, $class;

    return $self;
}

sub get_phonetic_sugg {
    my ( $self, $type, $codeA, $codeB ) = @_;
    my $hash =
      $type eq 'sys' ? $self->data->get_words_ph : $self->data->get_user_dict;
    unless ( defined $hash ) {
        die("dizionari $type no definît\n");
    }

    if ( $codeA eq $codeB ) {
        return split /,/, ( $hash->{$codeA} || '' );
    }
    else {
        my %hashloc;

        $hashloc{$_} = 1 foreach split /,/, ( $hash->{$codeA} || '' );
        $hashloc{$_} = 1 foreach split /,/, ( $hash->{$codeB} || '' );

        return keys %hashloc;
    }
}

sub get_case_words {
    my ( $self, $word ) = @_;
    $word = COF::Data::lc_word $word;
    my @words;
    for my $w (
        $self->get_phonetic_sugg( 'sys', COF::Data::phalg_furlan($word) ) )
    {
        push( @words, $w ) if COF::Data::lc_word($w) eq $word;
    }
    return @words;
}

sub get_rt_sugg {
    my ( $self, $word ) = @_;
    my %list = ();
    for my $simw ( $self->data->get_words_rt->get_words_ed1($word) ) {
        if ( substr( $simw, -1, 1 ) eq $COF::RT_Checker::NOLC_CAR ) {
            $simw = substr( $simw, 0, -1 );
            $list{$_} = 1 for $self->get_case_words($simw);
        }
        else {
            $list{$simw} = 1;
        }
    }
    return ( keys %list );
}

sub _find_in_exc {
    my ( $self, $answer, $dict_type ) = @_;
    my $dict =
      $dict_type eq 'sys' ? $self->data->get_errors : $self->data->get_user_exc;
    my $word = $answer->word;
    if ( my $cor = $dict->{$word} ) {
        return $cor;
    }
    else {
        $answer->calc_case unless $answer->case;
        my $case = $answer->case;
        if ( $case == 1 ) { return;
        }
        elsif ( $case == 2 ) { return $dict->{ $answer->word_lc };
        }
        else { if ( my $cor = $dict->{ $answer->word_lc } ) {
                return $cor;
            }
            else {
                return $dict->{ $answer->word_ucfirst };
            }
        }
    }
}


sub _find {
    my ( $self, $answer, $dict, $apostrof ) = @_;
    my @sugg =
      $self->get_phonetic_sugg( $dict, @{$answer}{ '_code1', '_code2' } );
    my $word = $answer->{'word'};

    foreach (@sugg) {
        if ( $word eq $_ ) {
            return !$apostrof || $self->data->word_has_elision($_);
        }
    }

    $answer->calc_case unless $answer->case;
    my $case = $answer->case;

    if ( $case == 1 ) { return 0;
    }
    elsif ( $case == 2 ) { my $lc_word = $answer->word_lc;
        foreach (@sugg) {
            if ( $lc_word eq $_ ) {
                return !$apostrof || $self->data->word_has_elision($_);
            }
        }
        return 0;
    }
    else { my $lc_word = $answer->word_lc;
        my $ucf_word = $answer->word_ucfirst;
        foreach (@sugg) {
            if ( ( $ucf_word eq $_ ) || ( $lc_word eq $_ ) ) {
                return !$apostrof || $self->data->word_has_elision($_);
            }
        }
        return 0;
    }
}


sub check_word {
    my ( $self, $word ) = @_;
    my $answer = bless { ok => 0, word => $word }, 'COF::SpellChecker::Answer';

    my $lc_word = $answer->{word_lc} = COF::Data::lc_word $word;
    if ( $word =~ /\d|(^[^$WORD_LETTERS]+$)/o ) { $answer->{ok} = 1;
    }
    elsif ( $self->data->has_user_exc
        && defined( $self->_find_in_exc( $answer, 'user' ) ) )
    {
        $answer->{ok} = 0;
    }
    elsif ( length($lc_word) > 2 && ( substr( $lc_word, 0, 2 ) eq "l'" ) ) {

        if ( $self->data->has_user_dict ) {
            ( $answer->{_code1}, $answer->{_code2} ) =
              COF::Data::phalg_furlan($lc_word);
            if ( $self->_find( $answer, 'user' ) ) {
                $answer->{ok} = 1;
                return $answer;
            }
        }
        my $dx    = substr( $word,    2 );
        my $dx_lc = substr( $lc_word, 2 );
        my $dx_ans = bless { ok => 0, word => $dx, word_lc => $dx_lc },
          'COF::SpellChecker::Answer';
        ( $answer->{dx_code1}, $answer->{dx_code2} ) =
          ( $dx_ans->{_code1}, $dx_ans->{_code2} ) =
          COF::Data::phalg_furlan($dx_lc);
        if ( $self->_find( $dx_ans, 'sys', 1 ) ) {
            $answer->{'ok'} = 1;
        }
        else {
            $answer->{'dx_case'} = $dx_ans->case;
        }
    }
    else {
        ( $answer->{_code1}, $answer->{_code2} ) =
          COF::Data::phalg_furlan($lc_word);
        unless ( $self->_find( $answer, 'sys' ) ) {
            if ( $self->data->has_user_dict && $self->_find( $answer, 'user' ) )
            {
                $answer->{ok} = 1;
            }
            else {
                $answer->{ok} = 0;
            }
        }
        else {
            $answer->{ok} = 1;
        }
    }
    return $answer;
}

sub suggest_raw {
    my ( $self, $answer ) = @_;
    $answer = bless { ok => 0, word => $answer }, 'COF::SpellChecker::Answer'
      unless ref($answer);

    my $list = _build_suggestions( $self, $answer );

    my @parole_trovate = ();
    for my $p ( keys %$list ) {
        push( @parole_trovate, $p );
    }

    @parole_trovate = COF::Data::sort_friulian(@parole_trovate);
    my %parole_hamming = ();

    foreach my $indice_parola ( 0 .. $#parole_trovate ) {
        my $y    = $parole_trovate[$indice_parola];
        my $vals = $list->{$y};
        push @{ $parole_hamming{ $vals->[0] }{ $vals->[1] } }, $indice_parola;
    }

    return ( \%parole_hamming, \@parole_trovate );
}

sub suggest {
    my ( $self, $answer ) = @_;
    my ( $peso, $sugg )   = $self->suggest_raw($answer);
    my @sugg_ord;
    for my $f ( sort { $b <=> $a } keys %$peso )
    { for my $d ( sort { $a <=> $b } keys %{ $peso->{$f} } )
        { push( @sugg_ord, $sugg->[$_] )
              for @{ $peso->{$f}->{$d} };
        }
    }
    return \@sugg_ord;
}

sub is_error {
    my ( $self, $answer ) = @_;
    $answer = bless { ok => 0, word => $answer }, 'COF::SpellChecker::Answer'
      unless ref($answer);
    if ( $self->data->has_errors ) {
        return 1 if $self->_find_in_exc( $answer, 'sys' );
    }

    if ( $self->data->has_user_exc ) {
        return 2 if $self->_find_in_exc( $answer, 'user' );
    }
    return 0;
}

sub _basic_suggestions {
    my ( $self, $answer, $diz_word ) = @_;

    $answer = bless { ok => 0, word => $answer }, 'COF::SpellChecker::Answer'
      unless ref($answer);
    $answer->calc_case unless $answer->case;
    my $word    = $answer->word;
    my $lc_word = $answer->word_lc;
    my $case    = $answer->case;

    my %list = ();
    my %sugg = ();
    
    @{$answer}{ '_code1', '_code2' } = COF::Data::phalg_furlan($lc_word)
      unless exists $answer->{'_code1'};
    my ( $codeA, $codeB ) = @{$answer}{ '_code1', '_code2' };

    $sugg{$_} = 5 for $self->get_phonetic_sugg( 'sys', $codeA, $codeB );
    if ( $self->data->has_user_dict ) {
        $sugg{$_} = 4 for $self->get_phonetic_sugg( 'user', $codeA, $codeB );
    }

    $sugg{$_} = 3 for $self->get_rt_sugg($lc_word);

    if ( $self->data->has_errors ) {
        my $cor = $self->_find_in_exc( $answer, 'sys' );
        $sugg{$cor} = 2 if $cor;
    }

    if ( $self->data->has_user_exc ) {
        my $cor = $self->_find_in_exc( $answer, 'user' );
        $sugg{$cor} = 1 if $cor;
    }

    while ( my ( $p, $type ) = each %sugg ) {
        my $fixed_p = $self->fix_case( $case, $p );
        unless ( $list{$fixed_p} ) {
            my @vals = ();
            my $lc_p = COF::Data::lc_word $p;
            if ( $lc_word eq $lc_p ) { @vals = ( F_SAME, 1 );
            }
            elsif ( $type == 1 ) {
                @vals = ( F_USER_EXC, 0 );
            }
            elsif ( $type == 2 ) {
                @vals = ( F_ERRS, 0 );
            }
            elsif ( $type == 3 )
            { @vals = ( $self->data->get_freq->{$p} || 0, 1 );
            }
            elsif ( $type == 4 )
            { @vals = ( F_USER_DICT, COF::Data::Levenshtein( $lc_word, $p ) )
                  ;
            }
            else { @vals = (
                    $self->data->get_freq->{$p} || 0,
                    COF::Data::Levenshtein( $lc_word, $p )
                );
            }
            push( @vals, $p ) if $diz_word;
            $list{$fixed_p} = [@vals];
        }
    }

    return \%list;
}


sub _build_suggestions {
    my ( $self, $answer ) = @_;

    my %list = %{ $self->_basic_suggestions($answer) };

    $answer->calc_case unless $answer->case;
    my $word    = $answer->word;
    my $lc_word = $answer->word_lc;
    my $case    = $answer->case;

    my $pos;
    if (
        (
            $pos = 2,
            (
                length($lc_word) > $pos
                  && ( substr( $lc_word, 0, $pos ) eq "d'" )
            )
        )
        || (
            $pos = 3,
            (
                length($lc_word) > $pos
                  && ( substr( $lc_word, 0, $pos ) eq "un'" )
            )
        )
      )
    {
        my $sx = $pos == 2 ? 'di' : 'une';
        my $dx_answer = bless {
            word    => substr( $word,    $pos ),
            word_lc => substr( $lc_word, $pos )
          },
          'COF::SpellChecker::Answer';

        $dx_answer->calc_case;
        my ($case_sx);
        if ( $case == 3 ) {
            $case_sx = 3;
        }
        else {
            $case_sx = COF::Data::first_is_uc($word) ? 2 : 1;
        }
        $sx = $self->fix_case( $case_sx, $sx ) . ' ';

        my %dx_list = %{ $self->_basic_suggestions($dx_answer) };
        while ( my ( $p, $vals ) = each %dx_list ) {
            my $p = $sx . $p;
            $vals->[1]++;
            $list{$p} = $vals;
        }

    }
    elsif ( length($lc_word) > 2 && ( substr( $lc_word, 0, 2 ) eq "l'" ) ) {
        my $dx_answer = bless {
            word    => substr( $word,    2 ),
            word_lc => substr( $lc_word, 2 )
          },
          'COF::SpellChecker::Answer';

        my $case_sx = COF::Data::first_is_uc($word) ? $case == 3 ? 3 : 2 : 1;
        my $sx_ap    = $self->fix_case( $case_sx, "l'" );
        my $sx_no_ap = $self->fix_case( $case_sx, 'la' ) . ' ';

        my %dx_list = %{ $self->_basic_suggestions( $dx_answer, 1 ) };
        while ( my ( $p, $vals ) = each %dx_list ) {
            my ( $frec, $dist, $p_in_diz ) = @$vals;
            my $sx =
              ( $self->data->word_has_elision($p_in_diz) ) ? $sx_ap : $sx_no_ap;
            my $p = $sx . $p;
            $list{$p} = [ $frec, $dist + 1 ];
        }
    }

    if ( index( $word, "-", 0 ) > -1 ) {
        my ( $sx, $dx ) = split /-/, $word, 2;

        my %sx_list = %{ $self->_basic_suggestions($sx) };
        my %dx_list = %{ $self->_basic_suggestions($dx) };

        while ( my ( $sx_p, $sx_vals ) = each %sx_list ) {
            while ( my ( $dx_p, $dx_vals ) = each %dx_list ) {
                $list{"$sx_p $dx_p"} = [
                    $sx_vals->[0] + $dx_vals->[0],
                    $sx_vals->[1] + $dx_vals->[1]
                ];
            }
        }
    }

    return \%list;
}

sub fix_case {
    my ( $self, $case, $word ) = @_;
    return $word if $case == 1;
    my $lc_word  = COF::Data::lc_word $word;
    my $ucf_word = COF::Data::ucf_word($lc_word);
    my $uc_word  = COF::Data::uc_word $lc_word;
    if ( $word eq $lc_word || $word eq $ucf_word ) {
        return ( $case == 2 ) ? $ucf_word : $uc_word;
    }
    return $word;
}

sub data { $_[0]->{data} }

package COF::SpellChecker::Answer;

use strict;

sub ok           { $_[0]->{ok} }
sub word         { $_[0]->{word} }
sub word_lc      { $_[0]->{word_lc} }
sub word_ucfirst { $_[0]->{word_ucfirst} }
sub _code1       { $_[0]->{_code1} }
sub _code2       { $_[0]->{_code2} }

sub case {
    $_[0]->{case};
}

sub calc_case {
    my $self    = shift;
    my $word    = $self->{word};
    my $lc_word = $self->{word_lc};
    unless ($lc_word) {
        $lc_word = $self->{word_lc} = COF::Data::lc_word $word;
    }

    if ( $word eq $lc_word ) {
        $self->{case} = 1;
        return;
    }
    my $ucf_word = $self->{word_ucfirst} = COF::Data::ucf_word($lc_word);
    if ( $ucf_word eq $word ) { $self->{case} = 2;
        return;
    }
    elsif ( $word eq COF::Data::uc_word($lc_word) ) { $self->{case} = 3;
        return;
    }
    $self->{case} = 1;
}

1;
