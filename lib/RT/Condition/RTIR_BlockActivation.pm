use strict;
use warnings;

package RT::Condition::RTIR_BlockActivation;
use base 'RT::Condition::RTIR';

=head2 IsApplicable

When state of the block changes from C<pending activation> to C<active>
or ticket created with C<active> state.

=cut

sub IsApplicable {
    my $self = shift;

    my $txn = $self->TransactionObj;
    return 1 if $txn->Type eq 'Create' && $self->TicketObj->Status eq 'active';
    return 1 if
        $self->IsStatusChange
        && $txn->OldValue eq 'pending activation'
        && $txn->NewValue eq 'active';

    return 0;
}

RT::Base->_ImportOverlays;

1;
