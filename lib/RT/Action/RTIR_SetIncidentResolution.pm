use strict;
use warnings;

package RT::Action::RTIR_SetIncidentResolution;
use base 'RT::Action::RTIR';

=head2 Prepare

Always run this.

=cut

sub Prepare { return 1 }

=head2 Commit

Set the resolution if there is no value.

=cut

sub Commit {
    my $self = shift;

    my $t = $self->TicketObj;
    my $cf = RT::CustomField->new( $self->TransactionObj->CurrentUser );
    $cf->LoadByNameAndQueue( Queue => $t->QueueObj->Id, Name => 'Resolution' );
    return 1 unless $cf->Id;

    my $status = $t->Status;
    if ( $t->QueueObj->IsActiveStatus( $status ) ) {
        # on re-open, drop resolution
        my $txn = $self->TransactionObj; my $type = $txn->Type;
        return 1 unless $type eq "Status" || ( $type eq "Set" && $txn->Field eq "Status" );
        return 1 unless $t->QueueObj->IsInactiveStatus( $txn->OldValue );
        return 1 unless my $value = $t->FirstCustomFieldValue( $cf->id );
        $t->DeleteCustomFieldValue( Field => $cf->id, Value => $value );
        return 1;
    }

    return 1 unless $t->QueueObj->IsInactiveStatus( $status );

    my $value = RT->Config->Get('RTIR_CustomFieldsDefaults')->{'Resolution'}{$status};
    return 1 unless $value;

    return 1 if $t->FirstCustomFieldValue( $cf->id );

    my ($res, $msg) = $t->AddCustomFieldValue( Field => $cf->id, Value => $value );
    $RT::Logger->warning("Couldn't add custom field value: $msg") unless $res;
    return 1;
}

RT::Base->_ImportOverlays;

1;
