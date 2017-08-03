use strict;
use warnings;

use RT::IR::Test tests => 13, config => q{Set($RunWhoisRequestByDefault, 1);};
use Test::NoWarnings;

RT::Test->started_ok;

my $agent = default_agent();

diag "Test Lookup page with RunWhoisRequestByDefault set to true";
{
    $agent->get_ok("/RTIR/Tools/Lookup.html", "Loaded Lookup page");
    $agent->content_contains('Look Up Information');
}

my @warnings = &Test::NoWarnings::warnings;
is( scalar @warnings, 1, 'Caught one startup warning');
like( $warnings[0]->getMessage, qr/Change of config option \'RunWhoisRequestByDefault\'/,
    'Warning about change of config option');

&Test::NoWarnings::clear_warnings;
@warnings = &Test::NoWarnings::warnings;
is( scalar @warnings, 0, 'Config warning cleared');

# done_testing doesn't work here because we are manually checking for warnings
