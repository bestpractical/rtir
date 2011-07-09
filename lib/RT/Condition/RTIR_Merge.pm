package RT::Condition::RTIR_Merge;

use strict;
use warnings;

use base 'RT::Condition::RTIR';

=head2 IsApplicable

If ticket has been merged.

=cut

sub IsApplicable {
    my $self = shift;

    my $txn = $self->TransactionObj;
    return 0 unless $txn->Type eq 'AddLink';
    return 0 unless $txn->Field eq 'MergedInto';
    return 1;
}

RT::Base->_ImportOverlays;

1;
