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
    return;
}

1;
