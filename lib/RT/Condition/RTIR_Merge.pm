package RT::Condition::RTIR_Merge;

use strict;
use warnings;

use base 'RT::Condition::RTIR';

=head2 IsApplicable

If ticket has been merged.

=cut

sub IsApplicable {
    my $self = shift;

    my $txn = $self->TransactionObj;
    return 0 unless $txn->Type eq 'AddLink';
    return 0 unless $txn->Field eq 'MergedInto';
    return 1;
}

eval "require RT::Condition::RTIR_Merge_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_Merge_Vendor.pm});
eval "require RT::Condition::RTIR_Merge_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_Merge_Local.pm});

1;
