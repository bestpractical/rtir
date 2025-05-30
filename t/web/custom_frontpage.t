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
$user_obj->PrincipalObj->GrantRight(Right => 'AdminSavedSearch');
$user_obj->PrincipalObj->GrantRight(Right => 'ModifySelf');
$user_obj->PrincipalObj->GrantRight(Right => 'SeeDashboard');
$user_obj->PrincipalObj->GrantRight(Right => 'SeeOwnDashboard');
$user_obj->PrincipalObj->GrantRight(Right => 'AdminOwnDashboard');

ok $m->login( customer => 'customer' ), "logged in";

$m->get ( $url."Search/Build.html");

#create a saved search
$m->form_name ('BuildQuery');

$m->field ( "ValueOfAttachment" => 'awesome');
$m->field ( "SavedSearchName" => 'awesome tickets');
$m->field ( "SavedSearchDescription" => 'awesome tickets');
$m->click_button (name => 'SavedSearchSave');

$m->get_ok( $url . "Dashboards/Modify.html?Create=1" );
$m->form_name('ModifyDashboard');
$m->field( Name => 'My RTIR homepage' );
$m->click_button( value => 'Create' );

$m->follow_link_ok( { text => 'Content' } );
$m->content_contains('awesome tickets', 'saved search listed in rt at a glance items');

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

$m->get_ok( $url . "Dashboards/Modify.html?Create=1" );
$m->form_name('ModifyDashboard');
$m->field( Name => 'My RTIR homepage' );
$m->click_button( value => 'Create' );

my ($id) = ( $m->uri =~ /id=(\d+)/ );
ok( $id, "got a dashboard ID, $id" );

# remove all portlets from the body pane except 'newest unowned tickets'
my $args = {
    Update => "Save Changes",
    Content => "[{\"Layout\":\"col-md-6\",\"Elements\":[[{\"id\":2,\"portlet_type\":\"search\",\"description\":\"Ticket: Unowned Tickets\"}],[]]}]",
};

$m->follow_link_ok( { text => 'Content' } );

my $res = $m->post(
    $url . "Dashboards/Queries.html?id=$id",
    $args,
);

is( $res->code, 200, "remove all portlets from body except 'newest unowned tickets'" );
like( $m->uri, qr/results=[A-Za-z0-9]{32}/, 'URL redirected for results' );
$m->content_contains( 'Dashboard updated' );

$m->get_ok( $url . '/RTIR/Prefs/Home.html' );
$m->submit_form_ok(
    {   form_name => 'UpdateRTIRDefaultDashboard',
        button    => "RTIRDefaultDashboard-$id",
    },
);

$m->get( $url."RTIR/" );
$m->content_contains( 'newest unowned tickets', "'newest unowned tickets' is present" );
$m->content_lacks( 'highest priority tickets', "'highest priority tickets' is not present" );
$m->content_lacks( 'Bookmarked Tickets<span class="results-count">', "'Bookmarked Tickets' is not present" );  # 'Bookmarked Tickets' also shows up in the nav, so we need to be more specific
$m->content_lacks( 'Quick ticket creation', "'Quick ticket creation' is not present" );

$m->get_ok( $url . "Dashboards/Queries.html?id=$id" );

# add back the previously removed portlets
$args->{Content} =
    "[{\"Layout\":\"col-md-6\",\"Elements\":[[{\"id\":1,\"description\":\"Ticket: My Tickets\",\"portlet_type\":\"search\"},{\"portlet_type\":\"search\",\"description\":\"Ticket: Unowned Tickets\",\"id\":2},{\"description\":\"Ticket: Bookmarked Tickets\",\"portlet_type\":\"search\",\"id\":3},{\"component\":\"QuickCreate\",\"description\":\"QuickCreate\",\"portlet_type\":\"component\",\"path\":\"/Elements/QuickCreate\"}],[{\"path\":\"/Elements/MyReminders\",\"portlet_type\":\"component\",\"description\":\"MyReminders\",\"component\":\"MyReminders\"},{\"description\":\"QueueList\",\"portlet_type\":\"component\",\"path\":\"/Elements/QueueList\",\"component\":\"QueueList\"},{\"portlet_type\":\"component\",\"path\":\"/Elements/Dashboards\",\"description\":\"Dashboards\",\"component\":\"Dashboards\"}]]}]";

$res = $m->post(
    $url . "Dashboards/Queries.html?id=$id",
    $args,
);

is( $res->code, 200, 'add back previously removed portlets' );
like( $m->uri, qr/results=[A-Za-z0-9]{32}/, 'URL redirected for results' );
$m->content_contains( 'Dashboard updated' );

$m->get( $url."RTIR/" );
$m->content_contains( 'newest unowned tickets', "'newest unowned tickets' is present" );
$m->content_contains( 'highest priority tickets', "'highest priority tickets' is present" );
$m->content_contains( '>Bookmarked Tickets</a>', "'Bookmarked Tickets' is present" );
$m->content_contains( 'Quick ticket creation', "'Quick ticket creation' is present" );

#create a saved search with special chars
$m->get( $url . "Search/Build.html" );
$m->form_name('BuildQuery');
$m->field( "ValueOfAttachment"      => 'awesome' );
$m->field( "SavedSearchName" => 'special chars [test] [_1] ~[_1~]' );
$m->field( "SavedSearchDescription" => 'special chars [test] [_1] ~[_1~]' );
$m->click_button( name => 'SavedSearchSave' );
my ($saved_search_id) = $m->content =~ /\<option value\="(\d+)"\>special chars \[test\]/;
ok( $saved_search_id, "got saved search id $saved_search_id");
$m->get_ok( $url . "Dashboards/Queries.html?id=$id" );
$m->content_contains( 'special chars [test] [_1] ~[_1~]',
    'saved search listed in rt at a glance items' );

# add saved search to body
$args->{Content} =
    "[{\"Layout\":\"col-md-6\",\"Elements\":[[{\"id\":1,\"description\":\"Ticket: My Tickets\",\"portlet_type\":\"search\"},{\"portlet_type\":\"search\",\"description\":\"Ticket: Unowned Tickets\",\"id\":2},{\"description\":\"Ticket: Bookmarked Tickets\",\"portlet_type\":\"search\",\"id\":3},{\"component\":\"QuickCreate\",\"description\":\"QuickCreate\",\"portlet_type\":\"component\",\"path\":\"/Elements/QuickCreate\"},{\"id\":5,\"description\":\"Ticket: special chars [test] [_1] ~[_1~]\",\"portlet_type\":\"search\"}],[{\"path\":\"/Elements/MyReminders\",\"portlet_type\":\"component\",\"description\":\"MyReminders\",\"component\":\"MyReminders\"},{\"description\":\"QueueList\",\"portlet_type\":\"component\",\"path\":\"/Elements/QueueList\",\"component\":\"QueueList\"},{\"portlet_type\":\"component\",\"path\":\"/Elements/Dashboards\",\"description\":\"Dashboards\",\"component\":\"Dashboards\"}]]}]";

$res = $m->post(
    $url . "Dashboards/Queries.html?id=$id",
    $args,
);

is( $res->code, 200, 'add saved search to body' );
like( $m->uri, qr/results=[A-Za-z0-9]{32}/, 'URL redirected for results' );
$m->content_contains( 'Dashboard updated' );

$m->get( $url."RTIR/" );
$m->content_like( qr/special chars \[test\] \d+ \[_1\]/,
    'special chars in titlebox' );

# Edit a system saved search to contain "[more]"
{
    my $search = RT::SavedSearch->new( RT->SystemUser );
    $search->LoadByCols( Name => 'My Tickets' );
    my ($id, $name) = ($search->id, RT->SystemUser->loc($search->Name, '&#34;N&#34;'));
    ok $id, "loaded search record $id";

    $m->get( $url."RTIR/" );
    $m->follow_link_ok({ url_regex => qr"Prefs/Search\.html\?id=$id" }, 'Edit link');
    $m->content_contains($name, "found search name: $name");

    ok +($search->SetName( $search->Name . " [more]" ));

    $m->get_ok($m->uri); # "reload_ok"
    $m->content_contains($name . " [more]", "found search name: $name");
}

done_testing;
