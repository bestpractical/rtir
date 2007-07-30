package RT::Action::RTIR_SetState;

use strict;
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
    my $cf = RT::CustomField->new( $self->TransactionObj->CurrentUser );
    $cf->LoadByNameAndQueue( Queue => $t->QueueObj->Id, Name => '_RTIR_State' );
    unless ( $cf->Id ) {
        $RT::Logger->warning("Couldn't load '_RTIR_State' CF for queue ". $t->QueueObj->Name );
        return 1;
    }
 
    if ($self->TransactionObj->Type eq 'CustomField' and $self->TransactionObj->Field == $cf->id) {
	return 1;
    }

    my $state = $self->GetState;
    return 1 unless $state;

    my ($res, $msg) = $t->AddCustomFieldValue(Field => $cf->id, Value => $state);

    $RT::Logger->warning("Couldn't add custom field value: $msg") unless $res;
    return 1;
}

sub GetState { return '' }

eval "require RT::Action::RTIR_SetState_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetState_Vendor.pm});
eval "require RT::Action::RTIR_SetState_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetState_Local.pm});

1;
