use strict;
use warnings;

use RT::IR::Test tests => undef, playwright => 1;

my ( $url, $p ) = RT::Test->started_ok;
$p->login();

$p->get_ok('/RTIR/Incident/Create.html?Lifecycle=incidents');
$p->wait_for_htmx;

my $incident_section      = $p->{page}->locator('#ticket-create-incident');
my $investigation_section = $p->{page}->locator('#ticket-create-investigation');

ok( $incident_section->isVisible,      'Incident section is rendered in the DOM' );
ok( $investigation_section->count > 0, 'Investigation section is rendered in the DOM' );

# Each widget is wrapped by HTMXLoadStart in a div with the
# class="htmx-load-widget" and an hx-trigger attribute. The trigger
# should be "...load" for the eager Incident half and "...revealed" for
# the lazy Investigation half.
my $incident_widget      = $incident_section->locator('.htmx-load-widget')->first;
my $investigation_widget = $investigation_section->locator('.htmx-load-widget')->first;

my $inc_trigger = $incident_widget->getAttribute('hx-trigger')      // '';
my $inv_trigger = $investigation_widget->getAttribute('hx-trigger') // '';

like( $inc_trigger, qr/\bload\b/,     "Incident widget triggers on load (hx-trigger='$inc_trigger')" );
like( $inv_trigger, qr/\brevealed\b/, "Investigation widget triggers on reveal (hx-trigger='$inv_trigger')" );

$p->logout;
done_testing;
