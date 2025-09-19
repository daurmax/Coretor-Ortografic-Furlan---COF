package COF::Letters;

use strict;
use warnings;
use utf8;

use parent qw(Exporter);

our @EXPORT_OK =
  qw($FUR_APOSTROPHS $FUR_LETTERS $FUR_VOWELS $ALL_LETTERS $WORD_LETTERS $WORD_CHARS);

our $FUR_APOSTROPHS = "'\\x91\\x92\\x{2018}\\x{2019}";
our $FUR_LETTERS =
  "a-zA-ZçàáèéìíòóùúâêîôûÂÊÎÔÛÇÀÁÈÉÌÍÒÓÙÚ";
our $FUR_VOWELS = "aeiouAEIOUâêîôûÂÊÎÔÛ";

our $WORD_LETTERS =
'a-zA-ZµÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ';

our $WORD_CHARS = '0-9' . $WORD_LETTERS . $FUR_APOSTROPHS . '-';

1;
