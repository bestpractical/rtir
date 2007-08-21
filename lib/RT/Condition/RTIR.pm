
use warnings;
use strict;
use RT::IR;

package RT::Condition::RTIR;
use base 'RT::Condition::Generic';

=head1 NAME

RT::Condition::RTIR - generic checks

=head1 METHODS

=head2 IsStatusChange

Returns true if it's status change of a ticket.

=cut

sub IsStatusChange {
    my $self = shift;
    my $type = $self->TransactionObj->Type;
    return 1 if $type eq "Status" or
        ( $type eq "Set" and
          $self->TransactionObj->Field eq "Status" );

    return 0;
}

=head2 IsStaff

Returns true if creator of a ticket is a staff member. By staff member
we mean memeber of a group which name contains 'DutyTeam'.

=cut

sub IsStaff {
    my $self = shift;

    my $actor_id = $self->TransactionObj->Creator;
    my $cgm = RT::CachedGroupMembers->new( $RT::SystemUser );
    $cgm->Limit(FIELD => 'MemberId', VALUE => $actor_id );
    my $group_alias = $cgm->Join(
        FIELD1 => 'GroupId', TABLE2 => 'Groups', FIELD2 => 'id'
    );
    $cgm->Limit(
        ALIAS    => $group_alias,
        FIELD    => 'Name',
        OPERATOR => 'LIKE',
        VALUE    => 'DutyTeam',
    );
    $cgm->RowsPerPage(1);
    return $cgm->First? 1 : 0;
}

1;
