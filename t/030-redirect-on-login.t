use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();
$agent->logout;

# $agent->login() doesn't actually test /NoAuth/Login.html
# It requests $rt_web_url/?user=root;pass=password which is
# a different flow than our users use.
my $url = $agent->rt_base_url;
diag $url if $ENV{TEST_VERBOSE};
$agent->get($url);

# test a login from the main page
{
    $agent->get_ok($url);
    is($agent->{'status'}, 200, "Loaded a page");
    is($agent->uri, $url, "didn't redirect to /NoAuth/Login.html for base URL");
    ok($agent->current_form->find_input('user'));
    ok($agent->current_form->find_input('pass'));
    like($agent->current_form->action, qr{/NoAuth/Login\.html$}, "login form action is correct");

    ok($agent->content =~ /username:/i);
    $agent->field( 'user' => 'rtir_test_user' );
    $agent->field( 'pass' => 'rtir_test_pass' );

    # the field isn't named, so we have to click link 0
    $agent->click(0);
    is( $agent->status, 200, "Fetched the page ok");
    ok( $agent->content =~ /Logout/i, "Found a logout link");
    is( $agent->uri, $url.'RTIR/', "right URL" );
    like( $agent->{redirected_uri}, qr{/NoAuth/Login\.html$}, "We redirected from login");
    $agent->logout();
}


# test a login from a non-front page, both with a double leading slash and without
for my $path (qw(Prefs/Other.html /Prefs/Other.html)) {
    my $requested = $url.$path;
    $agent->get_ok($requested);
    is($agent->status, 200, "Loaded a page");
    like($agent->uri, qr'/NoAuth/Login\.html\?next=[a-z0-9]{32}', "on login page, with next page hash");
    is($agent->{redirected_uri}, $requested, "redirected from our requested page");

    ok($agent->current_form->find_input('user'));
    ok($agent->current_form->find_input('pass'));
    ok($agent->current_form->find_input('next'));
    like($agent->value('next'), qr/^[a-z0-9]{32}$/i, "next page argument is a hash");
    like($agent->current_form->action, qr{/NoAuth/Login\.html$}, "login form action is correct");

    ok($agent->content =~ /username:/i);
    $agent->field( 'user' => 'rtir_test_user' );
    $agent->field( 'pass' => 'rtir_test_pass' );

    # the field isn't named, so we have to click link 0
    $agent->click(0);
    is( $agent->status, 200, "Fetched the page ok");
    ok( $agent->content =~ /Logout/i, "Found a logout link");

    if ($path =~ m{/}) {
        (my $collapsed = $path) =~ s{^/}{};
        is( $agent->uri, $url.$collapsed, "right URL, with leading slashes in path collapsed" );
    } else {
        is( $agent->uri, $requested, "right URL" );
    }

    like( $agent->{redirected_uri}, qr{/NoAuth/Login\.html}, "We redirected from login");
    $agent->logout();
}

# test a login from the main page as somebody not in the duty team
{
    $agent->get_ok($url);
    is($agent->{'status'}, 200, "Loaded a page");
    is($agent->uri, $url, "didn't redirect to /NoAuth/Login.html for base URL");
    ok($agent->current_form->find_input('user'));
    ok($agent->current_form->find_input('pass'));
    like($agent->current_form->action, qr{/NoAuth/Login\.html$}, "login form action is correct");

    ok($agent->content =~ /username:/i);
    $agent->field( 'user' => 'root' );
    $agent->field( 'pass' => 'password' );

    # the field isn't named, so we have to click link 0
    $agent->click(0);
    is( $agent->status, 200, "Fetched the page ok");
    ok( $agent->content =~ /Logout/i, "Found a logout link");
    is( $agent->uri, $url, "right URL" );
    like( $agent->{redirected_uri}, qr{/NoAuth/Login\.html$}, "We redirected from login");
    $agent->logout();
}

# test REST login response
{
    $agent = RT::Test::Web->new;
    my $requested = $url."REST/1.0/?user=rtir_test_user;pass=rtir_test_pass";
    $agent->get($requested);
    is($agent->status, 200, "Loaded a page");
    is($agent->uri, $requested, "didn't redirect to /NoAuth/Login.html for REST");
    $agent->get_ok($url."REST/1.0");
}




done_testing;

#TODO
#Test with WebPath (needs apache)
#Test with config off

1;
