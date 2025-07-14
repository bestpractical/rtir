use strict;
use warnings;
use RT::IR::Test tests => undef;

RT->Config->Set('RunWhoisRequestByDefault', 1);

RT::Test->started_ok;
my $agent = default_agent();

diag "Test Lookup page with RunWhoisRequestByDefault set to true";
{
    $agent->get_ok("/RTIR/Tools/Lookup.html", "Loaded Lookup page");
    $agent->content_contains('Look Up Information');
}

done_testing;

