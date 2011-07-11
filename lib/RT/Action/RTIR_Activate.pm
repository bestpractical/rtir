use strict;
use warnings;

package RT::Action::RTIR_Activate;
use base 'RT::Action::RTIR';

=head2 Commit

Set status to first active that's possible to change to.

=cut

sub Commit {
    my $self = shift;

    my $ticket = $self->TicketObj;

    my $new = $ticket->FirstActiveStatus;
    return 1 unless $new;

    my ($status, $msg) = $ticket->SetStatus( $new );
    unless ( $status ) {
        $RT::Logger->error( "Couldn't activate ticket: $msg" );
        return 0;
    }

    return 1;
}

RT::Base->_ImportOverlays;

1;
