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

    my $txn = $self->TransactionObj;
 
    return 1 if $txn->Type eq 'Set' && $txn->Field eq 'Status';

    my $status = $self->GetState;
    return 1 unless $status;
    return 1 if $t->Status eq $status;

    my ( $res, $msg ) = $t->SetStatus( $status );
    $RT::Logger->warning("Couldn't set status to $status: $msg")
        unless $res;
    return 1;
}

sub GetState { return '' }

eval "require RT::Action::RTIR_SetState_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetState_Vendor.pm});
eval "require RT::Action::RTIR_SetState_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetState_Local.pm});

1;
