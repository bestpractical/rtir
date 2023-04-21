# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2023 Best Practical Solutions, LLC
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

package RT::Action::RTIR_ResolveChildren;
use strict;
use warnings;
use base 'RT::Action::RTIR';

=head2 Prepare

Check if the Incident is being closed.

=cut

sub Prepare {
    my $self = shift;
    my @inactive = $self->TicketObj->QueueObj->InactiveStatusArray;
    my $new_status = $self->TransactionObj->NewValue;

    return 0 unless grep { $_ eq $new_status } @inactive;
    return 1;
}

=head2 Commit

Resolve all children.

=cut

sub Commit {
    my $self = shift;
    my $incident = $self->TicketObj;
    my $id = $incident->Id;

    foreach my $lifecycle ( RT::IR->lifecycle_report, RT::IR->lifecycle_investigation, RT::IR->lifecycle_countermeasure ) {
        next if $lifecycle eq RT::IR->lifecycle_countermeasure && RT->Config->Get('RTIR_DisableCountermeasures');

        my $members = RT::IR->IncidentChildren(
            $incident, Lifecycle => $lifecycle,
            Initial => 1, Active => 1,
        );
        while ( my $member = $members->Next ) {
            if ( RT::IR->IsLinkedToActiveIncidents( $member, $incident ) ) {
                $member->Comment(Content => <<END);

Linked Incident \#$id was resolved, but ticket still has unresolved linked Incidents.

END
                next;
            }
            my $set_to = RT::IR->MapStatus( $incident->Status, $incident => $lifecycle );
            next unless $set_to;
            next if $member->Status eq $set_to;

            my ($res, $msg) = $member->SetStatus( $set_to );
            RT->Logger->info( "Couldn't resolve ticket: $msg" ) unless $res;
        }
    }
    return 1;
}

RT::IR->ImportOverlays;

1;
