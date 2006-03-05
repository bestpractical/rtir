package RT::IR::Ticket;

use strict;
use warnings;

=head1 NAME

RT::IR::Ticket - RTIR's tickets utilities

=head1 FUNCTIONS

=head2 FirstCustomFieldValue $TicketObj, $Field

Returns first RTIR ticket's custom field value. Use it only with RTIR's
special custom fields like C<_RTIR_State> and other.

=cut

sub FirstCustomFieldValue {
    my $ticket = shift;
    my $field = shift;
    return undef unless $ticket->CurrentUserHasRight('ShowTicket');

    return $ticket->FirstCustomFieldValue( $field );
}

1;
