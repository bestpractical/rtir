use strict;
use warnings;

use RT::IR::Test tests => undef;
use Test::Warn;

# OurQuery should return false without dying when given unparseable SQL.
{
    my ( $ret, $lived );
    warning_like {
        $lived = eval { $ret = RT::IR->OurQuery('Queue = ) INVALID @@'); 1 };
    }
    qr/OurQuery: failed to parse query/, 'OurQuery logs a warning for invalid SQL';
    ok( $lived, 'OurQuery does not die on invalid SQL' );
    ok( !$ret,  'OurQuery returns false for invalid SQL' );
}

done_testing;
