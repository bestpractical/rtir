# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2021 Best Practical Solutions, LLC
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

package RT::Action::RTIR_ChangeChildConstituencies;
use strict;
use warnings;
use base 'RT::Action::RTIR';


=head2 Prepare

=cut

sub Prepare {
    my $self = shift;

    return 0 unless (RT::IR->StrictConstituencyLinking);
    return 0 unless ($self->TransactionObj->Field eq 'Queue');

    my $q1 = RT::Queue->new(RT->SystemUser);
    $q1->Load($self->TransactionObj->OldValue);
    my $q2 = RT::Queue->new(RT->SystemUser);
    $q2->Load($self->TransactionObj->NewValue);

    return 0 unless ((RT::IR->ConstituencyFor($q2)||'') ne (RT::IR->ConstituencyFor($q1)||''));

    $self->{'old_constituency'} = RT::IR->ConstituencyFor($q1) || '';
    $self->{'new_constituency'} = RT::IR->ConstituencyFor($q2) || '';
    return 1;
}

=head2 Commit

Change the constituency of children, but only if they were started
off in the same constituency as the incident

=cut

sub Commit {
    my $self = shift;

    my $new_constituency = $self->{'new_constituency'};
    my $old_constituency = $self->{'old_constituency'};

    # find all the tickets related to this ticket

    my $kids = RT::IR->IncidentChildren($self->TicketObj);

    # for each ticket,
    while ( my $ticket = $kids->Next) {
        my $kid_constituency = RT::IR->ConstituencyFor($ticket) || '';
        next if ($kid_constituency eq $new_constituency);
        next if ($kid_constituency ne $old_constituency);
        # if the constituency of the other ticket isn't the same as the new 
        # constituency
        my $kid_queue = $ticket->QueueObj->Name;

        # Find an equivalent queue in the new constituency
        $kid_queue =~ s/$kid_constituency/$new_constituency/;
        my $new_queue = RT::Queue->new(RT->SystemUser);
        $new_queue->Load($kid_queue);
        if (    !$new_queue->id
             || ( (RT::IR->ConstituencyFor($new_queue)||'') ne $new_constituency)
             || ($new_queue->Lifecycle ne $ticket->QueueObj->Lifecycle)) {
            my $queues = RT::Queues->new(RT->SystemUser);
            $queues->Limit(FIELD => 'Lifecycle', VALUE => $ticket->QueueObj->Lifecycle);
            while (my $temp_queue = $queues->Next) {
                if ((RT::IR->ConstituencyFor($temp_queue)||'') eq $new_constituency) {
                    $new_queue = $temp_queue;
                    last;
                }
            }
        }
        # move the child to the new constituency queue
        my ($val,$msg) = $ticket->SetQueue($new_queue->id);


        RT->Logger->info( "Couldn't change owner: $msg" ) unless $val;
    }
    return 1;
}

RT::IR->ImportOverlays;

1;
