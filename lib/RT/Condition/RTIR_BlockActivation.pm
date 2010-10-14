package RT::Condition::RTIR_BlockActivation;

use strict;
use warnings;

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

eval "require RT::Condition::RTIR_BlockActivation_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_BlockActivation_Vendor.pm});
eval "require RT::Condition::RTIR_BlockActivation_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_BlockActivation_Local.pm});

1;
