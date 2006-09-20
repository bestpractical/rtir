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

    my $transaction = $self->TransactionObj;
    if ( $transaction->Type eq 'Create' ) {
        # on create fetch value from X-RT-Mail-Extension field
        my $attachments = $transaction->Attachments;
        $attachments->OrderByCols(
            { FIELD => 'Created', ORDER => 'ASC' },
            { FIELD => 'id', ORDER => 'ASC' },
        );
        $attachments->Columns( qw(id Parent TransactionId ContentType ContentEncoding Headers Subject Created) );
        my $attachment = $attachments->First;
        return 1 unless $attachment;

        my $value = $attachment->GetHeader('X-RT-Mail-Extension');
        return 1 unless $self->IsValidConstituency( $value );

        my ($status, $msg) = $ticket->AddCustomFieldValue(
            Field => '_RTIR_Constituency',
            Value => $value,
        );
        return ($status, $msg) unless $status;
        return 1;
    }

    my $constituency = $ticket->FirstCustomFieldValue('_RTIR_Constituency');
    my $actor = $self->CreatorCurrentUser;

    # change owner of child Incident Reports, Investigations, Blocks
    my $query =  "( Queue = 'Incidents'"
        ." OR Queue = 'Incident Reports'"
        ." OR Queue = 'Investigations'"
        ." OR Queue = 'Blocks'"
        .")"
        ." AND ( MemberOf = ". $ticket->Id ." OR HasMember = ". $ticket->Id ." )";

    if ( $constituency ) {
        $query .= " AND ( CF.{_RTIR_Constituency} != '$constituency' OR CF.{_RTIR_Constituency} IS NULL )";
    } else {
        $query .= " AND ( CF.{_RTIR_Constituency} IS NOT NULL )";
    }
    my $tickets = new RT::Tickets( $actor );
    $tickets->FromSQL( $query );

    while ( my $t = $tickets->Next ) {
        my ($res, $msg) = $t->AddCustomFieldValue(
            Field => '_RTIR_Constituency',
            Value => $constituency,
        );
        $RT::Logger->info( "Couldn't set CF: $msg" ) unless $res;
    }
    return 1;
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
        %constituency = map { lc $_->Name => 1 } @{ $cf->Values->ItemsArrayRef };
    }
    return exists $constituency{ lc $value };
}

}

eval "require RT::Action::RTIR_SetConstituency_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetConstituency_Vendor.pm});
eval "require RT::Action::RTIR_SetConstituency_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetConstituency_Local.pm});

1;
