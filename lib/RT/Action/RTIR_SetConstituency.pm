package RT::Action::RTIR_SetConstituency;

use strict;
use warnings;

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

    my $type = $self->TransactionObj->Type;
    if ( $type eq 'Create' ) {
        my $status = $self->SetConstituencyOnCreate;
        return $status if defined $status;
    }

    my $propagation = lc RT->Config->Get('_RTIR_Constituency_Propagation');
    if ( $type eq 'AddLink' && $propagation eq 'reject' ) {
        #XXX: check here that linked tickets have the same constituency
    }

    return 1 unless $propagation eq 'inherit';

    my $query =  "( Queue = 'Incidents'"
        ." OR Queue = 'Incident Reports'"
        ." OR Queue = 'Investigations'"
        ." OR Queue = 'Blocks'"
        .")";

    my $constituency = $ticket->FirstCustomFieldValue('_RTIR_Constituency');
    if ( $constituency ) {
        $query .= " AND CF.{_RTIR_Constituency} != '$constituency'";
    } else {
        $query .= " AND CF.{_RTIR_Constituency} IS NOT NULL";
    }

    # do two queries as mysql couldn't optimize things well
    foreach my $link_type (qw(MemberOf HasMember)) {
        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->FromSQL( $query ." AND $link_type = ". $ticket->Id );
        while ( my $t = $tickets->Next ) {
            $RT::Logger->debug( "Ticket #". $t->id ." inherits constituency from ticket #". $ticket->id );
            my ($res, $msg) = $t->AddCustomFieldValue(
                Field => '_RTIR_Constituency',
                Value => $constituency,
            );
            $RT::Logger->warning( "Couldn't set CF: $msg" ) unless $res;
        }
    }
    return 1;
}

sub SetConstituencyOnCreate {
    my $self = shift;
    my $ticket = $self->TicketObj;

    my ($current, $value);
    $current = $value = $ticket->FirstCustomFieldValue('_RTIR_Constituency');
    if ( my $tmp = $self->GetConstituencyFromParent ) {
        my $propagation = lc RT->Config->Get('_RTIR_Constituency_Propagation');
        if ( $propagation eq 'inherit' ) {
            $value = $tmp;
        } elsif ( $propagation eq 'reject' && ($current||'') ne $tmp ) {
            $RT::Logger->error(
                "Constituency propagation algorithm is 'reject', but "
                . "ticket ". $ticket->id ." has constituency '$current'"
                . " when its parent incident has '$tmp'"
            );
        }
    }
    $value ||= $self->GetConstituencyFromAttachment;
    $value ||= RT->Config->Get('_RTIR_Constituency_default');
    return undef if ($current||'') eq ($value||'');

    my ($status, $msg) = $ticket->AddCustomFieldValue(
        Field => '_RTIR_Constituency',
        Value => $value,
    );
    $RT::Logger->warning( "Couldn't set CF: $msg" ) unless $status;
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
    $RT::Logger->debug( "Got constituency from attachment". ($value||'(no value)') );
    return $value;
}

sub GetConstituencyFromParent {
    my $self = shift;
    my $parents = RT::Tickets->new( $RT::SystemUser );
    $parents->FromSQL( "HasMember = ". $self->TicketObj->id );
    $parents->OrderByCols( { FIELD => 'LastUpdated', ORDER => 'DESC' } );
    $parents->RowsPerPage(1);
    return unless my $parent = $parents->First;
    my $value = $parent->FirstCustomFieldValue('_RTIR_Constituency');
    $RT::Logger->debug( "Got constituency from parent: ". ($value||'(no value)') );
    return $value;
}

{ my %constituency;

sub IsValidConstituency {
    my $self = shift;
    my $value = shift or return 0;
    unless ( keys %constituency ) {
        my $cf = RT::CustomField->new( $RT::SystemUser );
        $cf->Load('_RTIR_Constituency');
        unless ( $cf->id ) {
            $RT::Logger->crit("Couldn't load constituency field");
            return 0;
        }
        %constituency = map { lc $_->Name => $_->Content } @{ $cf->Values->ItemsArrayRef };
    }
    return $constituency{ lc $value };
}

}

eval "require RT::Action::RTIR_SetConstituency_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetConstituency_Vendor.pm});
eval "require RT::Action::RTIR_SetConstituency_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetConstituency_Local.pm});

1;
