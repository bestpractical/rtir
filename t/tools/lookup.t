use strict;
use warnings;

use RT::IR::Test tests => undef;

RT->Config->Set( LogToFile => 'info' );

RT::Test->started_ok;
my $agent = default_agent();

# The whois lookup requires an internet connection. Skip those tests if
# there is no network.
$agent->get("http://bestpractical.com");
my $no_network;
unless ($agent->status == 200){
    $no_network = 1;
    diag "No network connection. Skipping whois tests";
}

diag "Test Lookup page directly";
{
    $agent->get_ok("/RTIR/Tools/Lookup.html", "Loaded Lookup page");
SKIP:{
    skip "No network", 3 if $no_network;
    $agent->form_name('ToolFormWhois');
    $agent->field('q', 'mit.edu');
    $agent->select('WhoisServer', 'IANA');
    $agent->click;
    $agent->content_contains('WHOIS Results');
    $agent->content_contains('IANA WHOIS server');
    $agent->next_warning_like( qr/Asked to run a full text search from Lookup\.html/ );
}
    $agent->get_ok("/RTIR/Tools/Lookup.html", "Loaded Lookup page");
SKIP:{
    skip "No network", 3 if $no_network;
    $agent->form_name('ToolFormWhois');
    $agent->field('q', 'bestpractical.com');
    $agent->select('WhoisServer', 'RIPE');
    $agent->click;
    $agent->content_contains('WHOIS Results');
    $agent->content_contains('response');
    $agent->content_contains('comment');
    $agent->content_contains('ERROR:101');
    $agent->content_contains('No entries found in source RIPE');
    $agent->next_warning_like( qr/Asked to run a full text search from Lookup\.html/ );
}
}

diag "Test Lookup page in context of ticket";
{
    my $ir1 = $agent->create_ir(
    {Subject => 'First IR for testing whois lookup'},
    {IP => '172.16.0.1'}, );
    $agent->display_ticket( $ir1);
    $agent->follow_link_ok({text => '172.16.0.1'}, "Followed IP link");

    my $ir2 = $agent->create_ir(
    {Subject => 'Another IR for testing whois lookup'},
    {IP => '172.16.0.1'}, );
    $agent->display_ticket( $ir2);
    $agent->follow_link_ok({text => '172.16.0.1'}, "Followed IP link");
    $agent->content_contains('First IR for testing whois lookup');

SKIP:{
    skip "No network", 2 if $no_network;
    $agent->form_name('ToolFormWhois');
    $agent->click;
    $agent->content_contains('WHOIS Results');
    $agent->content_contains('No match');
}
}

diag "Test IP Lookup";
{
    $agent->get_ok("/RTIR/Tools/ScriptedAction.html?loop=IP", "Loaded Lookup page");

  SKIP:{
        skip "No network", 2 if $no_network;
        $agent->form_name('ScriptedAction');
        $agent->field('IPs', '45.33.11.14');
        $agent->field('field', 'organisation');
        $agent->select('server', 'whois.iana.org');
        $agent->click;
        $agent->content_contains('Address test results');
        $agent->content_contains('45.33.11.14');
        $agent->content_contains('Administered by ARIN');
    }

    $agent->get_ok("/RTIR/Tools/ScriptedAction.html?loop=IP", "Loaded Lookup page");

  SKIP:{
        skip "No network", 2 if $no_network;
        $agent->form_name('ScriptedAction');
        $agent->field('IPs', '45.33.11.14');
        $agent->field('field', 'netname');
        $agent->select('server', 'whois.ripe.net');
        $agent->click;
        $agent->content_contains('Address test results');
        $agent->content_contains('45.33.11.14');
        $agent->content_contains('NON-RIPE-NCC-MANAGED-ADDRESS-BLOCK');
    }
}


undef $agent;
done_testing;
