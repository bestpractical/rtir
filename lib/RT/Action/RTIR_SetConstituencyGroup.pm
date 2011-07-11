use strict;
use warnings;

package RT::Action::RTIR_SetConstituencyGroup;
use base 'RT::Action::RTIR';

=head2 Prepare

Always run this.

=cut


sub Prepare { return 1 }

=head2 Commit

Set the Constituency custom field.

=cut

sub Commit {
    my $self = shift;
    my $ticket = $self->TicketObj;
    my $admincc_group = $ticket->AdminCc;
    unless ( $admincc_group && $admincc_group->id ) {
        $RT::Logger->crit("Couldn't load AdminCc group of ticket #". $ticket->id);
        return 0;
    }
    my $groups = $admincc_group->GroupMembersObj( Recursively => 0 );
    $groups->LimitToUserDefinedGroups;
    $groups->Limit( FIELD => 'Name', OPERATOR => 'STARTSWITH', VALUE => 'DutyTeam ' );

    my $constituency = $ticket->FirstCustomFieldValue('Constituency') || '';
    my $required_group_there = 0;
    while ( my $group = $groups->Next ) {
        if ( lc $group->Name eq lc "dutyteam $constituency" ) {
            $required_group_there = 1;
        } elsif ( $group->Name =~ /^DutyTeam\s+\S.*$/ ) {
            my ($status, $msg) = $ticket->DeleteWatcher(
                Type        => 'AdminCc',
                PrincipalId => $group->id,
            );
            $RT::Logger->error("Couldn't delete admin cc: $msg") unless $status;
        }
    }
    if ( !$required_group_there && $constituency ) {
        my $group = RT::Group->new( $RT::SystemUser );
        $group->LoadUserDefinedGroup("DutyTeam $constituency");
        unless ( $group->id ) {
            $RT::Logger->warning("Couldn't load group 'DutyTeam $constituency'");
            # return success as if there is no custom group for the constituency
            # then it means that no custom ACLs should be applied
            return 1;
        }
        my ($status, $msg) = $ticket->AddWatcher(
            Type        => 'AdminCc',
            PrincipalId => $group->id,
        );
        $RT::Logger->error("Couldn't add admin cc: $msg") unless $status;
    }
    return 1;
}

{ my @constituencies;

sub ConstituencyValues {
    my $self = shift;
    my $value = shift or return 0;
    unless ( @constituencies ) {
        my $cf = RT::CustomField->new( $RT::SystemUser );
        $cf->Load('Constituency');
        unless ( $cf->id ) {
            $RT::Logger->crit("Couldn't load constituency field");
            return 0;
        }
        @constituencies = map $_->Name, @{ $cf->Values->ItemsArrayRef };
    }
    return @constituencies;
}

}

RT::Base->_ImportOverlays;

1;
