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

package RT::IR::ExternalFeeds;
use strict;
use warnings;

use LWP::UserAgent;
use XML::RSS;
use HTML::Entities;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );
    $self->_Init(@_);
    return $self;
}

sub _Init {
    my $self = shift;
    my %args = (
        Constituency => undef,
        @_,
    );
    $self->{ua} = LWP::UserAgent->new(timeout => 20);
    $self->{rss_feeds} = {
        map { $_->{Name} => $_ }
        @{RT->Config->Get('ExternalFeeds')->{RSS}}
    };
    $self->{_rss_parser} =  XML::RSS->new();
}

sub rss_feeds {
    my $self = shift;
    return values %{$self->{rss_feeds}};
}

sub fetch_rss_feed {
    my ($self, $name) = @_;
    my $url = $self->{rss_feeds}{$name}{URI};
    my $response = $self->{ua}->get($url);
    return $self->_parse_rss_feed($response);
}

######

sub _parse_rss_feed {
    my ($self, $response) = @_;
    return { }  unless ($response->is_success);
    $self->{_rss_parser}->parse($response->content);
    my $parsed_feed = { map { ucfirst($_) => $self->{_rss_parser}{channel}{$_} }
                            ( qw(title description pubDate lastBuildDate) ) };
    foreach my $item (@{$self->{_rss_parser}{items}}) {
        my $item_values = {
            map { ucfirst($_) => $item->{$_} }
                (qw(title link url guid pubDate) )
            };
        $item_values->{Link} //= $item_values->{Url};
        if (defined( $item->{'description'} ) ) {
            $item_values->{Description} = decode_entities($item->{'description'});
        } else {
            $item_values->{Description} = 'No content/description for this item';
        }
        push (@{$parsed_feed->{items}}, $item_values);
    }
    return $parsed_feed;
}

1;
