# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2025 Best Practical Solutions, LLC
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

package RT::IR::Config;
use strict;
use warnings;

sub Init {
    use RT::Config;

    RT->Config->RegisterPluginConfig(
        Plugin  => 'RTIR',
        Content => [
            {   Name => 'rtirname',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#rtirname',
            },
            {   Name => 'RTIR_IncidentChildren',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_IncidentChildren',
            },
            {   Name => 'RTIR_RedirectOnLogin',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_RedirectOnLogin',
            },
            {   Name => 'RTIR_RedirectOnSearch',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_RedirectOnSearch',
            },
            {   Name => 'RTIR_DefaultQueue',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_DefaultQueue',
            },
            {   Name => 'RTIR_StrictConstituencyLinking',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_StrictConstituencyLinking',
            },
            {   Name => 'OverdueAfter',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#OverdueAfter',
            },
            {   Name => 'ReplyString',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#ReplyString',
            },
            {   Name => 'RTIR_OldestRelatedTickets',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_OldestRelatedTickets',
            },
            {   Name => 'RTIRSearchResultFormats',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIRSearchResultFormats',
            },
            {   Name => 'DisplayAfterEdit',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#DisplayAfterEdit',
            },
            {   Name => 'RTIR_HomepageComponents',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_HomepageComponents',
            },
            {   Name => 'RTIR_CustomFieldsDefaults',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_CustomFieldsDefaults',
            },
            {   Name => 'RTIR_StrictDomainTLD',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_StrictDomainTLD',
            },
            {   Name => 'RTIR_DisableCountermeasures',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_DisableCountermeasures',
            },
            {   Name => 'RTIR_CountermeasureApproveActionRegexp',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIR_CountermeasureApproveActionRegexp',
            },
            {   Name => 'RTIRResearchTools',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RTIRResearchTools',
            },
            {   Name => 'TracerouteCommand',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#TracerouteCommand',
            },
            {   Name => 'whois',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#whois',
            },
            {   Name => 'RunWhoisRequestByDefault',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#RunWhoisRequestByDefault',
            },
            {   Name => 'LookupIPinfoToken',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#LookupIPinfoToken',
            },
            {   Name => 'ExternalFeeds',
                Help => 'https://docs.bestpractical.com/rtir/latest/RTIR_Config.html#ExternalFeeds',
            },
        ],
        Meta => {
            rtirname => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/String',
            },
            RTIR_IncidentChildren => { Type => 'HASH', },
            RTIR_RedirectOnLogin  => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Boolean',
            },
            RTIR_RedirectOnSearch => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Boolean',
            },
            RTIR_DefaultQueue => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Select',
                Section         => 'General',
                Overridable     => 1,
                SortOrder       => 1.5,
                WidgetArguments => {
                    Description => 'Default RTIR queue',    #loc
                    Default     => 1,
                    Callback    => sub {
                        my $ret = { Values => [], ValuesLabel => {}};
                        my @queues = RT::IR->Queues;
                        foreach my $queue_name ( @queues ) {
                            my $queue = RT::Queue->new($HTML::Mason::Commands::session{'CurrentUser'});
                            $queue->Load($queue_name);
                            next unless $queue->CurrentUserHasRight("CreateTicket");
                            push @{$ret->{Values}}, $queue->Id;
                            $ret->{ValuesLabel}{$queue->Id} = $queue->Name;
                        }
                        return $ret;
                    },
                }
            },
            RTIR_StrictConstituencyLinking => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Boolean',
            },
            OverdueAfter => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Integer',
            },
            ReplyString => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/String',
            },
            RTIR_OldestRelatedTickets => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Integer',
            },
            RTIRSearchResultFormats => {
                Type          => 'HASH',
                PostLoadCheck => sub {
                    my ( $self, %value ) = @_;
                    foreach my $format ( keys %value ) {
                        if ( $format =~ /^HASH/ && !defined $value{$format} ) {
                            RT->Logger->warning(
                                'You appear to have $RTIRSearchResultFormats in your configuration, this has been renamed to %RTIRSearchResultFormats see docs/UPGRADING-3.2'
                            );
                        }
                        CheckObsoleteCFSyntax( $value{$format},
                            $RT::Config::META{RTIRSearchResultFormats}{Source}{File} );
                    }
                },
            },
            DisplayAfterEdit        => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Boolean',
                Section         => 'Ticket display',
                Overridable     => 1,
                Widget          => '/Widgets/Form/Boolean',
                WidgetArguments => {
                    Description => 'Display RTIR ticket after edit (don\'t stay on the edit page)',
                }
            },
            RTIR_HomepageComponents   => { Type => 'ARRAY', },
            RTIR_CustomFieldsDefaults => { Type => 'HASH', },
            RTIR_StrictDomainTLD      => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Boolean',
            },
            RTIR_DisableCountermeasures => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Boolean',
            },
            RTIR_CountermeasureApproveActionRegexp => {
                Type      => 'SCALAR',
                Immutable => 1,
            },
            RTIRResearchTools => { Type => 'ARRAY', },
            TracerouteCommand => {
                Type      => 'SCALAR',
                Immutable => 1,
            },
            whois                    => { Type => 'HASH', },
            RunWhoisRequestByDefault => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Boolean',
            },
            LookupIPinfoToken => {
                Type   => 'SCALAR',
                Obfuscate => sub {
                    my ($config, $sources, $user) = @_;
                    return $user->loc('Token not printed');
                },
            },
            ExternalFeeds => { Type => 'HASH', },
        }
    );


    my @homepage_components = @{RT->Config->Get('HomepageComponents')};

    foreach my $component (RT->Config->Get('RTIR_HomepageComponents')){
        # Add them if they aren't already there
        # They may get added to the RT config manually
        push @homepage_components, $component
            unless grep /$component/, @homepage_components;
    }

    RT->Config->Set(HomepageComponents => \@homepage_components);

    if ( RT::Config->Get('RTIR_DisableCountermeasures') ) {
        my $orig_check = $RT::Config::META{'LinkedQueuePortlets'}{'PostLoadCheck'};

        $RT::Config::META{'LinkedQueuePortlets'}{'PostLoadCheck'} = sub {
            $orig_check->(@_) if $orig_check;
            my $LinkedQueuePortlets = RT->Config->Get('LinkedQueuePortlets') || {};

            my $queue_obj = RT::Queue->new( RT->SystemUser );
            foreach my $queue ( keys %{$LinkedQueuePortlets} ) {
                my $linked_queues = $LinkedQueuePortlets->{$queue};

                my @queues;
                foreach my $linked_queue ( @{$linked_queues} ) {
                    my ($queue_name) = keys %{$linked_queue};

                    my ( $ret, $msg ) = $queue_obj->Load($queue_name);
                    unless ($ret) {
                        RT::Logger->error("Could not load queue $queue_name from \%LinkedQueuePortlets hash: $msg");
                        next;
                    }

                    next if $queue_obj->Lifecycle eq RT::IR->lifecycle_countermeasure;
                    push @queues, $linked_queue;
                }
                $LinkedQueuePortlets->{$queue} = \@queues;
            }
        };
    }

    return;
}

=head1 CheckObsoleteCFSyntax

RTIR upgrades changed the naming of installed custom fields,
removing the _RTIR_ prefix from the custom field names and removing
State in favor of RT's default Status.

This function checks queries and formats for references to the old
CF names and warns that they need to be updated.

Takes: $string, $location

String that can be a format or query that might have an old CF format.

Location is where the format or query is, if available.

Returns: Nothing, just issues a warning in the logs.

=cut

sub CheckObsoleteCFSyntax {
    my $string = shift;
    my $location = shift;
    return unless $string;

    $location = 'unknown' unless $location;

    if ( $string =~ /__CustomField\.\{State\}__/
         or $string =~ /CF\.\{State\}/ ){

        RT::Logger->warning('The custom field State has been replaced with the RT Status field.'
                        . ' You should update your custom searches and result formats accordingly.'
                        . ' See the UPGRADING file and the $RTIRSearchResultFormats option'
                        . ' in the default RTIR_Config.pm file. Found in: ' . $string
                        . ' from ' . $location );
    }

    if ( $string =~ /__CustomField\.\{_RTIR_(\w+)\}__/
         or $string =~ /CF\.\{_RTIR_\w+\}/ ){

        RT::Logger->warning('The _RTIR_ prefix has been removed from all RTIR custom fields.'
                        . ' You should update your custom searches and result formats accordingly.'
                        . ' See the UPGRADING file for details. Found in: ' . $string
                        . ' from ' . $location );
    }
    return;
}

1;
