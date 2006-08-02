package RT::Action::RTIR_FindIP;

use strict;
use warnings;

use base qw(RT::Action::RTIR);

use Regexp::Common qw(net);

=head2 Prepare

Always run this.

=cut

sub Prepare { return 1 }

=head2 Commit

Search for IP addresses in the transaction's content.

=cut

sub Commit {
    my $self = shift;
    my $ticket = $self->TicketObj;

    my $cf = $ticket->LoadCustomFieldByIdentifier('_RTIR_IP');
    return 1 unless $cf && $cf->id;

    my $attach = $self->TransactionObj->ContentObj;
    return 1 unless $attach && $attach->id;

    my @IPs = ( $attach->Content =~ /($RE{net}{IPv4})/g );
    foreach ( @IPs ) {
        my ($status, $msg) = $ticket->AddCustomFieldValue(
            Value => $_,
            Field => $cf,
        );
        $RT::Logger->error("Couldn't add CF value: $msg") unless $status;
    }

    return 1;
}

1;
