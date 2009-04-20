package RT::Condition::RTIR_RequireConstituencyGroupChange;

use strict;
use warnings;

use base 'RT::Condition::RTIR';
use RT::CustomField;

=head2 IsApplicable

Applies to Ticket Creation and Constituency changes

=cut

sub IsApplicable {
    my $self = shift;

    my $type = $self->TransactionObj->Type;
    return 1 if $type eq 'Create';
    if ( $type eq 'CustomField' ) {
        my $cf = RT::CustomField->new( $RT::SystemUser );
        $cf->Load('Constituency');
        unless ( $cf->id ) {
            $RT::Logger->error("Couldn't load the 'Costituency' field");
            return 0;
        }
        return 1 if $cf->id == $self->TransactionObj->Field;
    }

    return 0;
}

eval "require RT::Condition::RTIR_RequireConstituencyGroupChange_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_RequireConstituencyGroupChange_Vendor.pm});
eval "require RT::Condition::RTIR_RequireConstituencyGroupChange_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_RequireConstituencyGroupChange_Local.pm});

1;
