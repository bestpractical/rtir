use strict;
use warnings;

package RT::Condition::RTIR_RequireReportActivation;
use base 'RT::Condition::RTIR';

=head2 IsApplicable

This condition is very close to conditions in L<RT::Action::AutoOpen>.

Main difference is that IRs are not activated until they are linked to an Incident.

=cut

sub IsApplicable {
    my $self = shift;

    my $ticket = $self->TicketObj;
    my $next = $ticket->FirstActiveStatus;
    return 0 unless defined $next;

    my $txn = $self->TransactionObj;

    my $cycle = $ticket->QueueObj->Lifecycle;
    if ( $cycle->IsInitial( $ticket->Status ) ) {
        # no change if the ticket in initial status and is not linked to parent
        return 0 unless RT::IR->Incidents( $ticket )->Count;
        # no change if the ticket is in initial status and the message is a mail
        # from a requestor
        return 0 if $txn->IsInbound;
    }

    if ( my $msg = $txn->Message->First ) { 
        return 0 if ($msg->GetHeader('RT-Control') || '') =~ /\bno-autoopen\b/i;
    }

    return 1;
}

RT::Base->_ImportOverlays;

1;
