# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2018 Best Practical Solutions, LLC
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

package RT::Action::RTIR_FindIP;
use strict;
use warnings;
use base qw(RT::Action::RTIR);

use Regexp::Common qw(net);
use Regexp::Common::net::CIDR ();
use Regexp::IPv6 qw();
use Net::CIDR ();

my $IPv4_mask_re = qr{3[0-2]|[1-2]?[0-9]};
my $IPv4_prefix_check_re = qr{(?<![0-9.])};
my $IPv4_suffix_check_re = qr{(?!\.?[0-9])};
my $IPv4_CIDR_re = qr{
    $IPv4_prefix_check_re
    $RE{net}{CIDR}{IPv4}{-keep}
    $IPv4_suffix_check_re
}x;
my $IPv4_re = qr[
    $IPv4_prefix_check_re
    (?!0\.0\.0\.0)
    ($RE{net}{IPv4})
    (?!/$IPv4_mask_re)
    $IPv4_suffix_check_re
]x;

my $IPv6_mask_re = qr{12[0-8]|1[01][0-9]|[1-9]?[0-9]};
my $IPv6_prefix_check_re = qr{(?<![0-9a-zA-Z:.])};
my $IPv6_suffix_check_re = qr{(?!\.?[0-9a-zA-Z:])};
my $IPv6_re = qr[
    $IPv6_prefix_check_re
    ($Regexp::IPv6::IPv6_re)
    (?:/($IPv6_mask_re))?
    $IPv6_suffix_check_re
]x;

my $IP_re = qr{$IPv6_re|$IPv4_re|$IPv4_CIDR_re};

=head2 Commit

Search for IP addresses in the transaction's content.

=cut

sub Commit {
    my $self = shift;
    my $ticket = $self->TicketObj;

    my $cf = $ticket->LoadCustomFieldByIdentifier('IP');
    return 1 unless $cf && $cf->id;

    my $how_many_can = $cf->MaxValues;

    my $attachments = $ticket->Attachments;
    return 1 unless $attachments && $attachments->Count;

    my %existing;
    for( @{$cf->ValuesForObject( $ticket )->ItemsArrayRef} ) {
        $existing{ $_->Content } =  1;
    }

    if ( $how_many_can && $how_many_can <= keys %existing ) {
        RT->Logger->debug("Ticket #". $ticket->id ." already has maximum number of IPs, skipping" );
        return 1;
    }

    my $spots_left = $how_many_can - keys %existing;

    while ( my $attach = $attachments->Next ) {
        my $content = $attach->Content || '';
        while ( $content =~ m/$IP_re/go ) {
            if ( $1 && defined $2 ) { # IPv6/mask
                my $range = $2 == 128 ? $1 : (Net::CIDR::cidr2range( "$1/$2" ))[0]
                    or next;
                $spots_left -= $self->AddIP(
                    IP => $range, CustomField => $cf, Skip => \%existing
                );
            }
            elsif ( $1 ) { # IPv6
                $spots_left -= $self->AddIP(
                    IP => $1, CustomField => $cf, Skip => \%existing
                );
            }
            elsif ( $3 ) { # IPv4
                $spots_left -= $self->AddIP(
                    IP => $3, CustomField => $cf, Skip => \%existing
                );
            }
            elsif ( $4 && defined $5 ) { # IPv4/mask
                my $cidr = join( '.', map { $_||0 } (split /\./, $4)[0..3] ) ."/$5";
                my $range = (Net::CIDR::cidr2range( $cidr ))[0] or next;
                $spots_left -= $self->AddIP(
                    IP => $range, CustomField => $cf, Skip => \%existing
                );
            }
            return 1 unless $spots_left;
        }
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

RT::IR->ImportOverlays;

1;
