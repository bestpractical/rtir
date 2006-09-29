package RT::Action::RTIR_FindIP;

use strict;
use warnings;

use base qw(RT::Action::RTIR);

use Regexp::Common qw(net);
use Regexp::Common::net::CIDR ();

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

    my %existing;
    for( @{$cf->ValuesForObject($ticket)->ItemsArrayRef} ) {
        $existing{$_->Content} =  1;

    }
    my $attach = $self->TransactionObj->ContentObj;
    return 1 unless $attach && $attach->id;

    my @IPs = ( $attach->Content =~ /($RE{net}{IPv4})/go );
    foreach my $ip ( @IPs ) {
        next if ($existing{$ip}); # skip any IP we already had.
        my ($status, $msg) = $ticket->AddCustomFieldValue(
            Value => $ip,
            Field => $cf,
        );
        $RT::Logger->error("Couldn't add CF value: $msg") unless $status;
        $existing{$ip} = 1;
    }

    my @CIDRs = ( $attach->Content =~ /$RE{net}{CIDR}{IPv4}{-keep}/go );
    while ( my ($addr, $bits) = splice @CIDRs, 0, 2 ) {
        my $cidr = join( '.', map $_||0, (split /\./, $addr)[0..3] ) ."/$bits";
        my ($sip, $eip) = split /-/, ( (Net::CIDR::cidr2range( $cidr ))[0] or next );
        my $snum = unpack( 'N', pack( 'C4', split /\./, $sip ) );
        my $enum = unpack( 'N', pack( 'C4', split /\./, $eip ) );
        while ( $snum++ <= $enum ) {
            my ($status, $msg) = $ticket->AddCustomFieldValue(
                Value => join( '.', unpack( 'C4', pack( 'N', $snum ) ) ),
                Field => $cf,
            );
            $RT::Logger->error("Couldn't add CF value: $msg") unless $status;
        }
    }

    return 1;
}

1;
