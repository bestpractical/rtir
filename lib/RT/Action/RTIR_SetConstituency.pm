# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2013 Best Practical Solutions, LLC
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

package RT::Action::RTIR_SetConstituency;
use base 'RT::Action::RTIR';

=head2 Commit

Set the Constituency custom field.

=cut

sub Commit {
    my $self = shift;
    my $ticket = $self->TicketObj;

    my $type = $self->TransactionObj->Type;
    if ( $type eq 'Create' ) {
        my $status = $self->SetConstituencyOnCreate;
        return $status if defined $status;
    }

    my $propagation = lc RT->Config->Get('_RTIR_Constituency_Propagation');
    if ( $type eq 'AddLink' && $propagation eq 'reject' ) {
        #XXX: check here that linked tickets have the same constituency
    }

    return $self->InheritConstituency if $propagation eq 'inherit';

    return 1;

}

sub InheritConstituency {
    my $self = shift;
    my $ticket = $self->TicketObj;

    my $query =  "( Queue = 'Incidents'"
        ." OR Queue = 'Incident Reports'"
        ." OR Queue = 'Investigations'"
        ." OR Queue = 'Blocks'"
        .")";

    my $constituency = $ticket->FirstCustomFieldValue('Constituency');
    if ( $constituency ) {
        $query .= " AND CF.{Constituency} != '$constituency'";
    } else {
        $query .= " AND CF.{Constituency} IS NOT NULL";
    }

    my $type = $self->TransactionObj->Type;
    if ( $type eq 'AddLink' ) {
        # inherit from parent on linking
        my $tickets = RT::Tickets->new( RT->SystemUser );
        $tickets->FromSQL( $query ." AND HasMember = ". $ticket->Id );
        $tickets->RowsPerPage( 1 );
        if ( my $parent = $tickets->First ) {
            RT->Logger->debug( "Ticket #". $ticket->id ." inherits constituency from ticket #". $parent->id );
            my ($res, $msg) = $ticket->AddCustomFieldValue(
                Field => 'Constituency',
                Value => $constituency,
            );
            RT->Logger->warning( "Couldn't set CF: $msg" ) unless $res;
            return 1;
        }
    }

    # propagate to members
    foreach my $link_type (qw(MemberOf HasMember)) {
        my $tickets = RT::Tickets->new( RT->SystemUser );
        $tickets->FromSQL( $query ." AND $link_type = ". $ticket->Id );
        while ( my $t = $tickets->Next ) {
            RT->Logger->debug(
                "Ticket #". $t->id ." inherits constituency"
                ." from ticket #". $ticket->id
            );
            my ($res, $msg) = $t->AddCustomFieldValue(
                Field => 'Constituency',
                Value => $constituency,
            );
            RT->Logger->warning( "Couldn't set CF: $msg" ) unless $res;
        }
    }
    return 1;
}

sub SetConstituencyOnCreate {
    my $self = shift;
    my $ticket = $self->TicketObj;

    my ($current, $value);
    $current = $value = $ticket->FirstCustomFieldValue('Constituency');
    if ( my $tmp = $self->GetConstituencyFromParent ) {
        my $propagation = lc RT->Config->Get('_RTIR_Constituency_Propagation');
        if ( $propagation eq 'inherit' ) {
            $value = $tmp;
        } elsif ( $propagation eq 'reject' && ($current||'') ne $tmp ) {
            RT->Logger->error(
                "Constituency propagation algorithm is 'reject', but "
                . "ticket ". $ticket->id ." has constituency '$current'"
                . " when its parent incident has '$tmp'"
            );
        }
    }
    $value ||= $self->GetConstituencyFromAttachment;
    $value ||= RT->Config->Get('RTIR_CustomFieldsDefaults')->{'Constituency'};
    return undef if ($current||'') eq ($value||'');

    my ($status, $msg) = $ticket->AddCustomFieldValue(
        Field => 'Constituency',
        Value => $value,
    );
    RT->Logger->warning( "Couldn't set CF: $msg" ) unless $status;
    return $status || 0;
}

sub GetConstituencyFromAttachment {
    my $self = shift;

    # fetch value from X-RT-Mail-Extension field
    my $attachments = $self->TransactionObj->Attachments;
    $attachments->OrderByCols(
        { FIELD => 'Created', ORDER => 'ASC' },
        { FIELD => 'id',      ORDER => 'ASC' },
    );
    $attachments->Columns( qw(id Parent TransactionId ContentType ContentEncoding Headers Subject Created) );
    my $attachment = $attachments->First;
    return undef unless $attachment;

    my $value = $attachment->GetHeader('X-RT-Mail-Extension');
    return undef unless $self->IsValidConstituency( $value );
    RT->Logger->debug( "Got constituency from attachment". ($value||'(no value)') );
    return $value;
}

sub GetConstituencyFromParent {
    my $self = shift;
    my $parents = RT::Tickets->new( RT->SystemUser );
    $parents->FromSQL( "HasMember = ". $self->TicketObj->id );
    $parents->OrderByCols( { FIELD => 'LastUpdated', ORDER => 'DESC' } );
    $parents->RowsPerPage(1);
    return unless my $parent = $parents->First;
    my $value = $parent->FirstCustomFieldValue('Constituency');
    RT->Logger->debug( "Got constituency from parent: ". ($value||'(no value)') );
    return $value;
}

{ my %constituency;

sub IsValidConstituency {
    my $self = shift;
    my $value = shift or return 0;
    unless ( keys %constituency ) {
        my $cf = RT::CustomField->new( RT->SystemUser );
        $cf->Load('Constituency');
        unless ( $cf->id ) {
            RT->Logger->crit("Couldn't load constituency field");
            return 0;
        }
        %constituency = map { lc $_->Name => $_->Name } @{ $cf->Values->ItemsArrayRef };
    }
    return $constituency{ lc $value };
}

}

RT::Base->_ImportOverlays;

1;
