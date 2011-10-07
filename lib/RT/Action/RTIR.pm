use strict;
use warnings;

package RT::Action::RTIR;
use base 'RT::Action';

=head2 Prepare

RTIR's actions don't do anything by default.

=cut

sub Prepare { return 1 }

sub CreatorCurrentUser {
    my $self = shift;
    my $user = RT::CurrentUser->new($self->TransactionObj->CurrentUser);
    $user->Load($self->TransactionObj->Creator);
    return $user;
}

RT::Base->_ImportOverlays;

1;
