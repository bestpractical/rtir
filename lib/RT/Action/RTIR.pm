
use warnings;
use strict;
use RT::IR;
package RT::Action::RTIR;

use base 'RT::Action::Generic';

sub CreatorCurrentUser {
    my $self = shift;
    my $user = new RT::CurrentUser($self->TransactionObj->CurrentUser);
    $user->Load($self->TransactionObj->Creator);
    return $user;
}


1;
