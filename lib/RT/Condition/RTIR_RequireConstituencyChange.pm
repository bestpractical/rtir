package RT::Condition::RTIR_RequireConstituencyChange;

use strict;
use warnings;

use base 'RT::Condition::RTIR';

=head2 IsApplicable

Applies to tickets being created, linked to other tickets or when
the Constituency Custom Field is changed

=cut

sub IsApplicable {
    my $self = shift;

    my $type = $self->TransactionObj->Type;
    return 1 if $type eq 'Create';
    return 1 if $type eq 'AddLink';
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

eval "require RT::Condition::RTIR_RequireConstituencyChange_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_RequireConstituencyChange_Vendor.pm});
eval "require RT::Condition::RTIR_RequireConstituencyChange_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_RequireConstituencyChange_Local.pm});

1;


