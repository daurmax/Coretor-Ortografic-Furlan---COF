use strict;
use warnings;
use utf8;

package COF::RadixTree;

use constant { NODE_HEAD_DIM => 1, };

sub new {
    my ( $class, $file ) = @_;
    my $fh;
    return unless open( $fh, '<', $file );
    my $data;
    binmode($fh);
    read( $fh, $data, -s $fh ) or return;
    close($fh);

    my $self = bless [ \$data ], $class;
    return $self;
}

sub get_root {
    my $self = shift;
    return COF::RadixTree::RT_Node->new( 0, $self->[0] );
}

package COF::RadixTree::RT_Node;

use constant {
    NTREE     => 0,
    NPOS      => 1,
    NNEDGE    => 2,
    NNEXT_POS => 3,
    NNEXT_NUM => 4
};

sub new {
    my ( $class, $pos, $tree ) = @_;
    my $self = bless [ $tree, $pos, unpack( 'C', substr( $$tree, $pos, 1 ) ),
        $pos + 1, 0 ],
      $class;
    return $self;
}

sub get_num_edges {
    return $_[0]->[NNEDGE];
}

sub get_next_edge {
    my $self = shift;
    unless ( $self->get_num_edges() > $self->[NNEXT_NUM] ) {
        $self->[NNEXT_NUM] = 0;
        $self->[NNEXT_POS] = 1;
        return;
    }
    $self->[NNEXT_NUM]++;
    my $edge =
      COF::RadixTree::RT_Edge->new( $self->[NNEXT_POS], $self->[NTREE] );
    $self->[NNEXT_POS] += $edge->get_dimension();
    return $edge;
}

sub copy {
    my $self = shift;
    return COF::RadixTree::RT_Node->new( $self->[NPOS], $self->[NTREE] );
}

package COF::RadixTree::RT_Edge;

use constant {
    IS_WORD_FLAG  => 128,
    CASE_FLAG     => 64,
    IS_LEAF_FLAG  => 32,
    NO_FLAGS      => ~( 128 | 64 | 32 ),
    EDGE_HEAD_DIM => 1, OFFSET_DIM => 4
};

sub new {
    my ( $class, $pos, $tree ) = @_;
    return
      bless [ $pos, $tree,
        unpack( 'C', substr( $$tree, $pos, EDGE_HEAD_DIM ) ) ],
      $class;
}

sub is_word {
    return
        ( $_[0]->[2] & IS_WORD_FLAG )
      ? ( $_[0]->[2] & CASE_FLAG )
          ? 2
          : 1
      : 0;
}

sub is_lc {
    return !( $_[0]->[2] & CASE_FLAG );
}

sub is_leaf {
    return $_[0]->[2] & IS_LEAF_FLAG;
}

sub get_len_string {
    return $_[0]->[2] & NO_FLAGS;
}

sub get_string {
    my $self = shift;
    return substr( ${ $self->[1] }, $self->[0] + 1, $self->get_len_string );
}

sub get_dimension {
    return EDGE_HEAD_DIM + $_[0]->get_len_string() +
      ( $_[0]->is_leaf ? 0 : OFFSET_DIM );
}

sub get_node {
    my $self     = shift;
    my $node_pos = unpack(
        'V',
        substr(
            ${ $self->[1] },
            $self->[0] + EDGE_HEAD_DIM + $self->get_len_string(), OFFSET_DIM
        )
    );
    return COF::RadixTree::RT_Node->new( $self->[0] + $node_pos, $self->[1] );
}

1;
