package RT::Condition::RTIR_LinkingToIncident;

use strict;
use warnings;

use base 'RT::Condition::RTIR';

=head2 IsApplicable

If ticket created with a link to an incident or link's added.

=cut

sub IsApplicable {
    my $self = shift;

    my $type = $self->TransactionObj->Type;
    if ( $type eq "Create" ) {
        my $query = "Queue = 'Incidents'"
            ." AND HasMember = " . $self->TicketObj->Id;
        my $parents = RT::Tickets->new( $self->CurrentUser );
        $parents->FromSQL( $query );
        return $parents->Count;
    }

    my $field = $self->TransactionObj->Field;
    if ( $type eq 'AddLink' && $field eq 'MemberOf' ) {
        my ($status, $msg, $parent) = $self->TicketObj->__GetTicketFromURI(
            URI => $self->TransactionObj->NewValue
        );
        unless ( $parent && $parent->id ) {
            $RT::Logger->error( "Couldn't load linked ticket #". $self->TransactionObj->NewValue );
            return 0;
        }
        return $parent->QueueObj->Name eq 'Incidents';
    }

    return 0;
}

eval "require RT::Condition::RTIR_LinkingToIncident_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_LinkingToIncident_Vendor.pm});
eval "require RT::Condition::RTIR_LinkingToIncident_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_LinkingToIncident_Local.pm});

1;
