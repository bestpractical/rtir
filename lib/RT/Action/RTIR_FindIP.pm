use strict;
use warnings;

package RT::Action::RTIR_FindIP;
use base qw(RT::Action::RTIR);

use Regexp::Common qw(net);
use Regexp::Common::net::CIDR ();
use Net::CIDR ();

=head2 Commit

Search for IP addresses in the transaction's content.

=cut

sub Commit {
    my $self = shift;
    my $ticket = $self->TicketObj;

    my $cf = $ticket->LoadCustomFieldByIdentifier('IP');
    return 1 unless $cf && $cf->id;

    my $how_many_can = $cf->MaxValues;

    my $attach = $self->TransactionObj->ContentObj;
    return 1 unless $attach && $attach->id;

    my %existing;
    for( @{$cf->ValuesForObject( $ticket )->ItemsArrayRef} ) {
        $existing{ $_->Content } =  1;
    }

    if ( $how_many_can && $how_many_can <= keys %existing ) {
        RT->Logger->debug("Ticket #". $ticket->id ." already has maximum number of IPs, skipping" );
        return 1;
    }

    my $spots_left = $how_many_can - keys %existing;

    my $content = $attach->Content || '';
# 0.0.0.0 is illegal IP address
    my @IPs = ( $content =~ /(?<!\d)(?!0\.0\.0\.0)($RE{net}{IPv4})(?!\d)(?!\/(?:3[0-2]|[1-2]?[0-9])(?:\D|\z))/go );
    foreach my $ip ( @IPs ) {
        $spots_left -= $self->AddIP(
            IP          => $ip,
            CustomField => $cf,
            Skip        => \%existing,
        );
        return 1 unless $spots_left;
    }

# but 0.0.0.0/0 is legal CIDR
    my @CIDRs = ( $content =~ /(?<![0-9.])$RE{net}{CIDR}{IPv4}{-keep}(?!\.?[0-9])/go );
    while ( my ($addr, $bits) = splice @CIDRs, 0, 2 ) {
        my $cidr = join( '.', map $_||0, (split /\./, $addr)[0..3] ) ."/$bits";
        my $range = (Net::CIDR::cidr2range( $cidr ))[0] or next;
        $spots_left -= $self->AddIP(
            IP => $range, CustomField => $cf, Skip => \%existing
        );
        return 1 unless $spots_left;
    }

    return 1;
}

sub AddIP {
    my $self = shift;
    my %arg = ( CustomField => undef, IP => undef, Skip => {}, @_ );
    return 0 if !$arg{'IP'} || $arg{'Skip'}->{ $arg{'IP'} }++
        || $arg{'Skip'}->{ $arg{'IP'} .'-'. $arg{'IP'} }++;

    my ($status, $msg) = $self->TicketObj->AddCustomFieldValue(
        Value => $arg{'IP'},
        Field => $arg{'CustomField'},
    );
    RT->Logger->error("Couldn't add IP address: $msg") unless $status;

    return 1;
}

RT::Base->_ImportOverlays;

1;
