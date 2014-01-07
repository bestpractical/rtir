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

package RT::Action::RTIR_SetDueIncident;
use base 'RT::Action::RTIR';

=head1 NAME

RT::Action::RTIR_SetDueIncident - set the Due date based on the most due child

=head1 DESCRIPTION

Set the Due date based on the most due child. Only takes into
account active children.

Can be applied not only to Incidents queue, but to children's
as well. In the latter case all incidents the current ticket
is linked to are updated.

=head1 METHODS

=head2 Commit

Performs update.

=cut

sub Commit {
    my $self = shift;

    if ( $self->TicketObj->QueueObj->Name eq 'Incidents' ) {
        return $self->UpdateDue( $self->TicketObj );
    }

    my $type = $self->TransactionObj->Type;
    if ( $type eq 'DeleteLink' ) {
        my $uri = RT::URI->new( $self->CurrentUser );
        $uri->FromURI( $self->TransactionObj->OldValue );
        return $self->UpdateDue( $uri->Object );
    }

    my $incidents = RT::IR->Incidents( $self->TicketObj );
    while ( my $incident = $incidents->Next ) {
        $self->UpdateDue( $incident );
    }

    return 1;
}

sub UpdateDue {
    my $self = shift;
    my $incident = shift;
    return 1 unless $incident;
    return 1 unless $incident->QueueObj->Name eq 'Incidents';

    my $children = RT::IR->IncidentChildren(
        $incident, Initial => 1, Active => 1,
        And => "Due > '1970-01-02 00:00:00'",
    );
    $children->OrderBy( FIELD => 'Due', ORDER => 'ASC' );
    $children->RowsPerPage(1);

    my $mostdue = $children->First;
    my $new = $mostdue? $mostdue->DueObj->ISO: '1970-01-01 00:00:00';
    my $old = $incident->DueObj->ISO;
    return 1 if $new eq $old;

    my ($status, $msg) = $incident->SetDue( $new );
    $RT::Logger->error( "Couldn't set due date: $msg" ) unless $status;

    return 1;
}

RT::Base->_ImportOverlays;

1;
