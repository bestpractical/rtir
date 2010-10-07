package RT::Condition::RTIR_BlockActivation;

use strict;
use warnings;

use base 'RT::Condition::RTIR';
use RT::CustomField;

=head2 IsApplicable

When state of the block changes from C<pending active> to C<active>
or ticket created with C<active> state.

=cut

sub IsApplicable {
    my $self = shift;

    my $txn = $self->TransactionObj;

    my $type = $txn->Type;
    return 1 if $type eq 'Create' && $self->TicketObj->Status eq 'active';

    return 0;
}

eval "require RT::Condition::RTIR_BlockActivation_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_BlockActivation_Vendor.pm});
eval "require RT::Condition::RTIR_BlockActivation_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_BlockActivation_Local.pm});

1;
