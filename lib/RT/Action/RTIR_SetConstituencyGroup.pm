# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2014 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

use strict;
use warnings;

package RT::Action::RTIR_SetConstituencyGroup;
use base 'RT::Action::RTIR';

=head2 Commit

Set the Constituency custom field.

=cut

sub Commit {
    my $self = shift;
    my $ticket = $self->TicketObj;
    my $admincc_group = $ticket->AdminCc;
    unless ( $admincc_group && $admincc_group->id ) {
        RT->Logger->crit("Couldn't load AdminCc group of ticket #". $ticket->id);
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
            RT->Logger->error("Couldn't delete admin cc: $msg") unless $status;
        }
    }
    if ( !$required_group_there && $constituency ) {
        my $group = RT::Group->new( RT->SystemUser );
        $group->LoadUserDefinedGroup("DutyTeam $constituency");
        unless ( $group->id ) {
            RT->Logger->warning("Couldn't load group 'DutyTeam $constituency'");
            # return success as if there is no custom group for the constituency
            # then it means that no custom ACLs should be applied
            return 1;
        }
        my ($status, $msg) = $ticket->AddWatcher(
            Type        => 'AdminCc',
            PrincipalId => $group->id,
        );
        RT->Logger->error("Couldn't add admin cc: $msg") unless $status;
    }
    return 1;
}

{ my @constituencies;

sub ConstituencyValues {
    my $self = shift;
    my $value = shift or return 0;
    unless ( @constituencies ) {
        my $cf = RT::CustomField->new( RT->SystemUser );
        $cf->Load('Constituency');
        unless ( $cf->id ) {
            RT->Logger->crit("Couldn't load constituency field");
            return 0;
        }
        @constituencies = map $_->Name, @{ $cf->Values->ItemsArrayRef };
    }
    return @constituencies;
}

}

RT::Base->_ImportOverlays;

1;
