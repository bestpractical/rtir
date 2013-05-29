use strict;
use warnings;

package RT::IR::Config;
use strict;
use warnings;

sub Init {
    use RT::Config;
    my %meta = (
        DisplayAfterEdit => {
            Section         => 'Tickets view',
            Overridable     => 1,
            Widget          => '/Widgets/Form/Boolean',
            WidgetArguments => {
                Description => 'Display ticket after edit (don\'t stay on the edit page)',
            },
        },
    );
    %RT::Config::META = (%meta, %RT::Config::META);

    # Tack on the PostLoadCheck here so it runs no matter where
    # RTIRSearchResultFormats gets loaded from. It will still
    # squash any other PostLoadChecks for this config entry, but those
    # should go here.
    $RT::Config::META{RTIRSearchResultFormats}{PostLoadCheck} =
        sub {
            my ($self, $value) = @_;
            foreach my $format ( keys %{$value} ){
                CheckObsoleteCFSyntax($value->{$format},
                    $RT::Config::META{RTIRSearchResultFormats}{Source}{File});
            }
        };

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
