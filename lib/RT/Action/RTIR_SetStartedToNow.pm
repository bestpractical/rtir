use strict;
use warnings;

package RT::Action::RTIR_SetStartedToNow;
use base 'RT::Action::RTIR';

sub Prepare { return 1 }

=head2 Commit

Set the Started date to now.

=cut

sub Commit {
    my $self = shift;

    my $ticket = $self->TicketObj;

    # set if the Started value isn't already set
    return 1 if $ticket->StartedObj->Unix > 0;

    my $date = RT::Date->new( $RT::SystemUser );
    $date->SetToNow;
    my ($status, $msg) = $ticket->SetStarted( $date->ISO );
    unless ( $status ) {
        $RT::Logger->error("Couldn't set date: $msg");
        return 0;
    }

    return 1;
}

RT::Base->_ImportOverlays;

1;
