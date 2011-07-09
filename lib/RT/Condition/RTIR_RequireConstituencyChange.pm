package RT::Condition::RTIR_RequireConstituencyChange;

use strict;
use warnings;

use base 'RT::Condition::RTIR';

=head2 IsApplicable

Applies to tickets being created, linked to other tickets or when
the Constituency Custom Field is changed

=cut

sub IsApplicable {
    my $self = shift;

    my $ticket = $self->TicketObj;
    my $cf = $ticket->LoadCustomFieldByIdentifier('Constituency');
    return 0 unless $cf && $cf->id;

    my $txn = $self->TransactionObj;
    my $type = $txn->Type;
    return 1 if $type eq 'Create';
    return 1 if $type eq 'AddLink';
    return 1 if $type eq 'CustomField' && $cf->id == $txn->Field;
    return 0;
}

RT::Base->_ImportOverlays;

1;
