package RT::IR::Web;
use warnings;
use strict;

use RT::Interface::Web;
package HTML::Mason::Commands;

# Extend RT's html scribber to allow the custom RTIR ticket url helper
# If we set this in the ColumnMap callback, it's too late, as RT's scrubber
# has already been initialized
#
$HTML::Mason::Commands::SCRUBBER_ALLOWED_ATTRIBUTES{'href'} = '^(?:'.$HTML::Mason::Commands::SCRUBBER_ALLOWED_ATTRIBUTES{'href'} . ')|(?:__RTIRTicketURI__)';

package RT::IR::Web;
RT::Base->_ImportOverlays();
1;