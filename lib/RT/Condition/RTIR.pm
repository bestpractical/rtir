
use warnings;
use strict;
use RT::IR;

package RT::Condition::RTIR;

use base 'RT::Condition::Generic';

sub IsStatusChange {
    my $self = shift;
    my $type = $self->TransactionObj->Type;
    return 1 if $type eq "Status" or
        ( $type eq "Set" and
          $self->TransactionObj->Field eq "Status" );

    return 0;
}

1;
