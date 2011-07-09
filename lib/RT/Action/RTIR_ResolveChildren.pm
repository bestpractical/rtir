# {{{ BEGIN BPS TAGGED BLOCK
# 
# COPYRIGHT:
#  
# This software is Copyright (c) 1996-2004 Best Practical Solutions, LLC 
#                                          <jesse@bestpractical.com>
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
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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
# }}} END BPS TAGGED BLOCK
#
package RT::Action::RTIR_ResolveChildren;
use strict;
use base 'RT::Action::RTIR';

use RT::IR::Ticket;

=head2 Prepare

Check if the Incident is being closed.

=cut


sub Prepare {
    my $self = shift;
    my @inactive = $self->TicketObj->QueueObj->InactiveStatusArray;
    my $new_status = $self->TransactionObj->NewValue;

    return 0 unless grep $_ eq $new_status, @inactive;
    return 1;
}

=head2 Commit

Resolve all children.

=cut

sub Commit {
    my $self = shift;
    my $id = $self->TicketObj->Id;

    foreach my $qname ( 'Incident Reports', 'Investigations', 'Blocks' ) {
        next if $qname eq 'Blocks' && RT->Config->Get('RTIR_DisableBlocksQueue');

        my $queue = RT::Queue->new( $self->CurrentUser );
        $queue->Load( $qname );
        unless ( $queue->id ) {
            $RT::Logger->error("Couldn't load '$qname' queue");
            next;
        }

        my $cycle = $queue->Lifecycle;
        my $query = "MemberOf = $id AND Queue = '$qname' AND "
            . join ' AND ', map "Status != '$_'", $cycle->Inactive;

        my $members = RT::Tickets->new( $self->CurrentUser );
        $members->FromSQL( $query );
        while ( my $member = $members->Next ) {
            if ( RT::IR->IsLinkedToActiveIncidents( $member, $self->TicketObj ) ) {
                $member->Comment(Content => <<END);

Linked Incident \#$id was resolved, but ticket still has unresolved linked Incidents.

END
                next;
            }
            my ($res, $msg) = $member->SetStatus(
                $cycle->DefaultStatus('on_incident_resolve') || ($cycle->Inactive)[0]
            );
            $RT::Logger->info( "Couldn't resolve ticket: $msg" ) unless $res;
        }
    }
    return 1;
}

RT::Base->_ImportOverlays;

1;
