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

use strict;
use warnings;

package RT::Action::RTIR_FindDomain;
use base qw(RT::Action::RTIR);

use Net::Domain::TLD 'tld_exists';

# https://www.safaribooksonline.com/library/view/regular-expressions-cookbook/9781449327453/ch08s15.html
my $regex = qr/\b((?:(?=[a-z0-9-]{1,63}\.)(?:xn--)?[a-z0-9]+(?:-[a-z0-9]+)*\.)+([a-z]{2,63}))\b/;

=head2 Commit

Search for domains in the transaction's content.

=cut

sub Commit {
    my $self   = shift;
    my $ticket = $self->TicketObj;

    my $cf = $ticket->LoadCustomFieldByIdentifier( 'Domain' );
    return 1 unless $cf && $cf->id;

    my $attach = $self->TransactionObj->ContentObj;
    return 1 unless $attach && $attach->id;

    my %existing;
    for ( @{ $cf->ValuesForObject( $ticket )->ItemsArrayRef } ) {
        $existing{ $_->Content } = 1;
    }

    my $how_many_can = $cf->MaxValues;
    if ( $how_many_can && $how_many_can <= keys %existing ) {
        RT->Logger->debug( "Ticket #" . $ticket->id . " already has maximum number of Domains, skipping" );
        return 1;
    }

    my $content = $attach->Content || '';
    while ( $content =~ m/$regex/igo ) {
        my $domain = $1;
        my $tld    = $2;

        next unless length $domain <= 253 && tld_exists( $tld );

        $self->AddDomain(
            Domain      => $domain,
            CustomField => $cf,
            Skip        => \%existing,
        );
    }

    return 1;
}

sub AddDomain {
    my $self = shift;
    my %arg = ( CustomField => undef, Domain => undef, Skip => {}, @_ );
    return 0 if !$arg{'Domain'} || $arg{'Skip'}->{ $arg{'Domain'} }++;

    my ( $status, $msg ) = $self->TicketObj->AddCustomFieldValue(
        Value => $arg{'Domain'},
        Field => $arg{'CustomField'},
    );
    RT->Logger->error( "Couldn't add Domain: $msg" ) unless $status;

    return 1;
}

RT::IR->ImportOverlays;

1;
