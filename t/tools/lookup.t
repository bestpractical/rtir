use strict;
use warnings;

use RT::IR::Test tests => undef;

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
    skip "No network", 2 if $no_network;
    $agent->form_name('ToolFormWhois');
    $agent->field('q', 'mit.edu');
    $agent->select('WhoisServer', 'IANA');
    $agent->click;
    $agent->content_contains('WHOIS Results');
    $agent->content_contains('IANA WHOIS server');
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

undef $agent;
done_testing();
