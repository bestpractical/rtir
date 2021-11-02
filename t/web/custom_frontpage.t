use strict;
use warnings;

use RT::IR::Test tests => undef;
my ($baseurl, $m) = RT::IR::Test->started_ok;

my $url = $m->rt_base_url;

my $user_obj = RT::User->new(RT->SystemUser);
my ($ret, $msg) = $user_obj->LoadOrCreateByEmail('customer@example.com');
ok($ret, 'ACL test user creation');
$user_obj->SetName('customer');
$user_obj->SetPrivileged(1);
($ret, $msg) = $user_obj->SetPassword('customer');
$user_obj->PrincipalObj->GrantRight(Right => 'LoadSavedSearch');
$user_obj->PrincipalObj->GrantRight(Right => 'EditSavedSearches');
$user_obj->PrincipalObj->GrantRight(Right => 'CreateSavedSearch');
$user_obj->PrincipalObj->GrantRight(Right => 'ModifySelf');

ok $m->login( customer => 'customer' ), "logged in";

$m->get ( $url."Search/Build.html");

#create a saved search
$m->form_name ('BuildQuery');

$m->field ( "ValueOfAttachment" => 'stupid');
$m->field ( "SavedSearchDescription" => 'stupid tickets');
$m->click_button (name => 'SavedSearchSave');

$m->get ( $url.'RTIR/Prefs/Home.html' );
$m->content_contains('stupid tickets', 'saved search listed in rt at a glance items');

# Grant rights for RTIR Constituency to get around warnings on create page
my $constituency_cf = RT::CustomField->new(RT->SystemUser);
$constituency_cf->Load('RTIR Constituency');
$user_obj->PrincipalObj->GrantRight( Right => 'SeeCustomField', Object => $constituency_cf );

diag 'Test RTIR_DefaultQueue setting with and without SeeQueue rights';

$m->submit_form_ok( { form_name => 'CreateTicketInQueue' }, 'Try to create ticket' );
$m->text_contains( 'Permission Denied', 'No permission to create ticket without SeeQueue' );
$m->warning_like( qr/Permission Denied/, 'Permission denied warning' );

my $default_queue = RT::Queue->new( RT->SystemUser );
ok( $default_queue->Load( RT->Config->Get('RTIR_DefaultQueue') ), 'Loaded RTIR default queue');

$user_obj->PrincipalObj->GrantRight( Right => 'SeeQueue', Object => $default_queue );
$m->submit_form_ok( { form_name => 'CreateTicketInQueue' }, 'Try to create ticket' );
$m->text_lacks( 'Permission Denied', 'Has permission to view create page' );
my $form          = $m->form_name('TicketCreate');
is( $form->value('Queue'), $default_queue->Id, 'Queue selection dropdown populated and pre-selected with ' . $default_queue->Name );

ok $m->login('root', 'password', logout => 1), 'we did log in as root';

my $args = {
    UpdateSearches => "Save",
    dashboard_id   => "RTIR_HomepageSettings",
    body           => [],
    sidebar        => [],
};

# remove all portlets from the body pane except 'newest unowned tickets'
push(
    @{$args->{body}},
    ( "system-Unowned Tickets", )
);

my $res = $m->post(
    $url . 'RTIR/Prefs/Home.html',
    $args,
);

is( $res->code, 200, "remove all portlets from body except 'newest unowned tickets'" );
like( $m->uri, qr/results=[A-Za-z0-9]{32}/, 'URL redirected for results' );
$m->content_contains( 'Preferences saved' );

$m->get( $url."RTIR/" );
$m->content_contains( 'newest unowned tickets', "'newest unowned tickets' is present" );
$m->content_lacks( 'highest priority tickets', "'highest priority tickets' is not present" );
$m->content_lacks( 'Bookmarked Tickets<span class="results-count">', "'Bookmarked Tickets' is not present" );  # 'Bookmarked Tickets' also shows up in the nav, so we need to be more specific
$m->content_lacks( 'Quick ticket creation', "'Quick ticket creation' is not present" );

# add back the previously removed portlets
push(
    @{$args->{body}},
    ( "system-My Tickets", "system-Bookmarked Tickets", "component-QuickCreate" )
);

push(
    @{$args->{sidebar}},
    ( "component-MyReminders", "component-QueueList", "component-Dashboards", "component-RefreshHomepage", )
);

$res = $m->post(
    $url . 'RTIR/Prefs/Home.html',
    $args,
);

is( $res->code, 200, 'add back previously removed portlets' );
like( $m->uri, qr/results=[A-Za-z0-9]{32}/, 'URL redirected for results' );
$m->content_contains( 'Preferences saved' );

$m->get( $url."RTIR/" );
$m->content_contains( 'newest unowned tickets', "'newest unowned tickets' is present" );
$m->content_contains( 'highest priority tickets', "'highest priority tickets' is present" );
$m->content_contains( 'Bookmarked Tickets<span class="results-count">', "'Bookmarked Tickets' is present" );
$m->content_contains( 'Quick ticket creation', "'Quick ticket creation' is present" );

#create a saved search with special chars
$m->get( $url . "Search/Build.html" );
$m->form_name('BuildQuery');
$m->field( "ValueOfAttachment"      => 'stupid' );
$m->field( "SavedSearchDescription" => 'special chars [test] [_1] ~[_1~]' );
$m->click_button( name => 'SavedSearchSave' );
my ($name) = $m->content =~ /value="(RT::User-\d+-SavedSearch-\d+)"/;
ok( $name, 'saved search name' );
$m->get( $url . 'RTIR/Prefs/Home.html' );
$m->content_contains( 'special chars [test] [_1] ~[_1~]',
    'saved search listed in rt at a glance items' );

# add saved search to body
push(
    @{$args->{body}},
    ( "saved-" . $name )
);

$res = $m->post(
    $url . 'RTIR/Prefs/Home.html',
    $args,
);

is( $res->code, 200, 'add saved search to body' );
like( $m->uri, qr/results=[A-Za-z0-9]{32}/, 'URL redirected for results' );
$m->content_contains( 'Preferences saved' );

$m->get( $url."RTIR/" );
$m->content_like( qr/special chars \[test\] \d+ \[_1\]/,
    'special chars in titlebox' );

# Edit a system saved search to contain "[more]"
{
    my $search = RT::Attribute->new( RT->SystemUser );
    $search->LoadByNameAndObject( Name => 'Search - My Tickets', Object => RT->System );
    my ($id, $desc) = ($search->id, RT->SystemUser->loc($search->Description, '&#34;N&#34;'));
    ok $id, 'loaded search attribute';

    $m->get( $url."RTIR/" );
    $m->follow_link_ok({ url_regex => qr"Prefs/Search\.html\?name=.+?Attribute-$id" }, 'Edit link');
    $m->content_contains($desc, "found description: $desc");

    ok +($search->SetDescription( $search->Description . " [more]" ));

    $m->get_ok($m->uri); # "reload_ok"
    $m->content_contains($desc . " [more]", "found description: $desc");
}

done_testing;
