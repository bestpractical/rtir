use strict;
use warnings;

package RT::Condition::RTIR_RequireConstituencyGroupChange;
use base 'RT::Condition::RTIR';

=head2 IsApplicable

Applies to Ticket Creation and Constituency changes

=cut

sub IsApplicable {
    my $self = shift;

    my $ticket = $self->TicketObj;
    my $cf = $ticket->LoadCustomFieldByIdentifier('Constituency');
    # no constituency
    return 0 unless $cf && $cf->id;

    my $txn = $self->TransactionObj;
    my $type = $txn->Type;
    return 1 if $type eq 'Create';
    return 1 if $type eq 'CustomField' && $cf->id == $txn->Field;
    return 0;
}

RT::Base->_ImportOverlays;

1;
