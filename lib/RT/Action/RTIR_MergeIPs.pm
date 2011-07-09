package RT::Action::RTIR_MergeIPs;

use strict;
use warnings;

use base 'RT::Action::RTIR';

=head2 Prepare

Always run this.

=cut

sub Prepare { return 1 }

=head2 Commit

Change the ownership of children.

=cut

sub Commit {
    my $self = shift;

    my $txn = $self->TransactionObj;
    my $uri = $txn->NewValue;

    my $uri_obj = RT::URI->new( $self->CurrentUser );
    my ($status) = $uri_obj->FromURI( $uri );
    unless ( $status && $uri_obj->Resolver && $uri_obj->Scheme ) {
        $RT::Logger->error( "Couldn't resolve '$uri' into a URI." );
        return 1;
    }

    my $target = $uri_obj->Object;
    return 1 if $target->id eq $txn->ObjectId;

    my $has_values = $target->CustomFieldValues( 'IP' );

    my $source = RT::Ticket->new( $self->CurrentUser );
    $source->LoadById( $txn->ObjectId );
    my $add_values = $source->CustomFieldValues( 'IP' );
    while ( my $value = $add_values->Next ) {
        my $ip = $value->Content;
        next if $has_values->HasEntry( $ip );

        my ($status, $msg) = $target->AddCustomFieldValue(
            Value => $ip,
            Field => 'IP',
        );
        $RT::Logger->error("Couldn't add IP address: $msg")
            unless $status;
    }

    return 1;
}

RT::Base->_ImportOverlays;

1;
