package RT::Action::RTIR_SetState;

use strict;
use warnings;

use base 'RT::Action::RTIR';

=head2 Prepare

Always run this.

=cut

sub Prepare { return 1 }

=head2 Commit

Set the state according to the status.

=cut

sub Commit {
    my $self = shift;

    my $t = $self->TicketObj;
 
    if ( $self->TransactionObj->Field eq 'Status' ) {
        return 1;
    }

    my $state = $self->GetState;
    return 1 unless $state;

    my ( $res, $msg ) = $t->SetStatus( $state ) unless $t->Status eq $state;
    $RT::Logger->warning("Couldn't set status to $state: $msg") unless $res;
    return 1;
}

sub GetState { return '' }

eval "require RT::Action::RTIR_SetState_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetState_Vendor.pm});
eval "require RT::Action::RTIR_SetState_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetState_Local.pm});

1;
