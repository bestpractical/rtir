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
package RT::Action::RTIR_SetDueIncident;


use strict;

use base 'RT::Action::RTIR';

=head2 Prepare

Always run this.

=cut


sub Prepare {
    my $self = shift;

    return 1;
}

# {{{ sub Commit

=head2 Commit

Set the Due date based on the most due child.

=cut

sub Commit {
    my $self = shift;

    my $type = $self->TransactionObj->Type;
    if ( $type eq 'DeleteLink' ) {
        my $uri = new RT::URI( $self->CurrentUser );
        $uri->FromURI( $self->TransactionObj->OldValue );
        return $self->UpdateDue( $uri->Object );
    }

    my $incidents = new RT::Tickets( $self->CurrentUser );
    $incidents->FromSQL( "Queue = 'Incidents' AND HasMember = " . $self->TicketObj->id );
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

    my $query =  "(Queue = 'Incident Reports'"
                ." OR Queue = 'Investigations'"
                ." OR Queue = 'Blocks'"
                .") AND MemberOf = " . $incident->Id
                ." AND ("
                . join( " OR ", map "Status = '$_'",
                        RT::Queue->ActiveStatusArray )
                .")";
    my $children = new RT::Tickets($self->CurrentUser);
    $children->FromSQL( $query );
    $children->OrderBy( FIELD => 'Due', ORDER => 'ASC' );
    $children->RowsPerPage(1);
    my $mostdue = $children->First;

    $incident->SetDue( $mostdue? $mostdue->DueObj->ISO: '1970-01-01 00:00:00' );

    return 1;
}

# }}}

1;
