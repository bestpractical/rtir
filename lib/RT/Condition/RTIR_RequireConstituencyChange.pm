package RT::Condition::RTIR_RequireConstituencyChange;

use strict;
use warnings;

use base 'RT::Condition::RTIR';

=head2 IsApplicable

If a child had a Due Date change or changes parents.

=cut

sub IsApplicable {
    my $self = shift;

    my $type = $self->TransactionObj->Type;
    return 1 if $type eq 'Create';
    return 1 if $type eq 'AddLink';
#    return 1 if $type eq "Set" && $self->TransactionObj->Field eq "Due";

    return 0;
}

eval "require RT::Condition::RTIR_RequireConstituencyChange_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_RequireConstituencyChange_Vendor.pm});
eval "require RT::Condition::RTIR_RequireConstituencyChange_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_RequireConstituencyChange_Local.pm});

1;


