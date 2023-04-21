# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2023 Best Practical Solutions, LLC
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
    $self->{ua} = LWP::UserAgent->new(env_proxy => 1);
    $self->{rss_feeds} = { };
    $self->{have_rss_feeds} = 0;

    if (RT->Config->Get('ExternalFeeds')->{RSS}) {
        my $i = 1;
        foreach my $rss_feed ( @{RT->Config->Get('ExternalFeeds')->{RSS}} ) {
            next unless (ref $rss_feed eq 'HASH');
            $rss_feed->{index} = $i++;
            $self->{rss_feeds}{$rss_feed->{Name}} = $rss_feed;
            $self->{have_rss_feeds} ||= 1;
        }
    }
    $self->{_rss_parser} = XML::RSS->new();

}

sub rss_feeds {
    my $self = shift;
    return sort { $a->{index} <=> $b->{index} } values %{$self->{rss_feeds}};
}

sub have_rss_feeds {
    return shift()->{have_rss_feeds};
}

sub fetch_rss_feed {
    my ($self, $name) = @_;
    my $url = $self->{rss_feeds}{$name}{URI};
    # make sure we have a fairly short timeout so page doesn't get apache timeout.
    my $response = $self->{ua}->get($url);
    return $self->_parse_rss_feed($response);
}

######

sub _parse_rss_feed {
    my ($self, $response) = @_;
    return { __error => "Can't reach feed : " . $response->status_line } unless ($response->is_success);
    eval { $self->{_rss_parser}->parse($response->content); };
    unless ( $self->{_rss_parser}{channel}{title} && $self->{_rss_parser}{items}[0] ) {
        return { __error => "Couldn't parse RSS response "};
    }

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
            $item_values->{scrubbed_description} = $self->_scrub_html($item_values->{Description});
        } else {
            $item_values->{scrubbed_description} = $item_values->{Description} = 'No content/description for this item';
        }
        push (@{$parsed_feed->{items}}, $item_values);
    }
    return $parsed_feed;
}

sub _scrub_html {
    my ($self, $html) = @_;
    unless ($self->{_scrubber}) {
        my $scrubber = HTML::Scrubber->new( script => 0, allow => [ qw[ p b i u br ] ] );
        $scrubber->rules(
            a => {
                'href' => qr{^(?:http|https)://}i,
                '*' =>  0
            },
            '*' => 0
        );
        $self->{_scrubber} = $scrubber;
    }
    my $scrubbed_html = $self->{_scrubber}->scrub($html);
    $scrubbed_html =~ s|<\/?p>|<br>|gi;
    return $scrubbed_html;
}

RT::IR->ImportOverlays;

1;
