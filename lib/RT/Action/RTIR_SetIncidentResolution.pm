package RT::Action::RTIR_SetIncidentResolution;

use strict;
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

    my $status = $t->Status;
    return 1 unless $t->QueueObj->IsInactiveStatus( $t->Status );

    my $value = RT->Config->Get("_RTIR_Resolution_${status}_default");
    return 1 unless $value;

    my $cf = RT::CustomField->new( $self->TransactionObj->CurrentUser );
    $cf->LoadByNameAndQueue( Queue => $t->QueueObj->Id, Name => '_RTIR_Resolution' );
    return 1 unless $cf->Id;

    return 1 if $t->FirstCustomFieldValue( $cf->id );

    my ($res, $msg) = $t->AddCustomFieldValue( Field => $cf->id, Value => $value );
    $RT::Logger->warning("Couldn't add custom field value: $msg") unless $res;
    return 1;
}

eval "require RT::Action::RTIR_SetIncidentResolution_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetIncidentResolution_Vendor.pm});
eval "require RT::Action::RTIR_SetIncidentResolution_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetIncidentResolution_Local.pm});

1;

