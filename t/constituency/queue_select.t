use strict;
use warnings;

use RT::IR::Test tests => undef;

use_ok('RT::IR');

my ($baseurl) = RT::Test->started_ok;
my $m = default_agent();
my $rtir_user = RT::CurrentUser->new( rtir_user() );
my ($ok, $msg);

diag "create constituencies EDUNET and GOVNET" if $ENV{'TEST_VERBOSE'};
{
    for my $constituency_name ( qw(EDUNET GOVNET) ) {
        my $manager = RT::IR::ConstituencyManager->new(Constituency => $constituency_name);
        ok($manager->AddConstituency, "added constituency $constituency_name");
    }
}

my $eduhandler = RT::Test->load_or_create_user( Name => 'eduhandler', Password => 'eduhandler' );
ok $eduhandler->id, "Created eduhandler";

my $govhandler = RT::Test->load_or_create_user( Name => 'govhandler', Password => 'govhandler' );
ok $govhandler->id, "Created govhandler";

my $edugroup = RT::Group->new( RT->SystemUser );
$edugroup->LoadUserDefinedGroup('DutyTeam EDUNET');
$edugroup->AddMember( $eduhandler->PrincipalId );
$edugroup->AddMember( $rtir_user->PrincipalId );

my $govgroup = RT::Group->new( RT->SystemUser );
$govgroup->LoadUserDefinedGroup('DutyTeam GOVNET');
$govgroup->AddMember( $govhandler->PrincipalId );
$govgroup->AddMember( $rtir_user->PrincipalId );

diag "check queue visibility" if $ENV{'TEST_VERBOSE'};
{
    $m->get("$baseurl/RTIR/Create.html?Lifecycle=incident_reports");
    $m->content_like(qr{Incident Reports</option>}, 'Queue dropdown has standard incident reports queue');
    $m->content_like(qr{Incident Reports - EDUNET</option>}, 'Queue dropdown has EDUNET incident reports queue');
    $m->content_like(qr{Incident Reports - GOVNET</option>}, 'Queue dropdown has GOVNET incident reports queue');

    $m->get("$baseurl/RTIR/Incident/Create.html?Lifecycle=incidents");
    $m->content_like(qr{Incidents</option>}, 'Queue dropdown has standard incidents queue');
    $m->content_like(qr{Incidents - EDUNET</option>}, 'Queue dropdown has EDUNET incidents queue');
    $m->content_like(qr{Incidents - GOVNET</option>}, 'Queue dropdown has GOVNET incidents queue');

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=investigations");
    $m->content_like(qr{Investigations</option>}, 'Queue dropdown has standard investigations queue');
    $m->content_like(qr{Investigations - EDUNET</option>}, 'Queue dropdown has EDUNET investigations queue');
    $m->content_like(qr{Investigations - GOVNET</option>}, 'Queue dropdown has GOVNET investigations queue');

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=countermeasures");
    $m->content_like(qr{Countermeasures</option>}, 'Queue dropdown has standard countermeasures queue');
    $m->content_like(qr{Countermeasures - EDUNET</option>}, 'Queue dropdown has EDUNET countermeasures queue');
    $m->content_like(qr{Countermeasures - GOVNET</option>}, 'Queue dropdown has GOVNET countermeasures queue');
}

diag "check queue visibility when created from incident" if $ENV{'TEST_VERBOSE'};
{
    my $id = $m->create_rtir_ticket_ok( 'Incidents - GOVNET', { Subject => 'test incident' } );

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=incident_reports&Incident=$id");
    $m->content_like(qr{Incident Reports - GOVNET</option>}, 'Queue dropdown has GOVNET incident reports queue');
    $m->content_unlike(qr{Incident Reports</option>}, 'Queue dropdown doesn\'t have standard incident reports queue');
    $m->content_unlike(qr{Incident Reports - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incident reports queue');

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=investigations&Incident=$id");
    $m->content_like(qr{Investigations - GOVNET</option>}, 'Queue dropdown has GOVNET investigations queue');
    $m->content_unlike(qr{Investigations</option>}, 'Queue dropdown doesn\'t have standard investigations queue');
    $m->content_unlike(qr{Investigations - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET investigations queue');

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=countermeasures&Incident=$id");
    $m->content_like(qr{Countermeasures - GOVNET</option>}, 'Queue dropdown has GOVNET countermeasures queue');
    $m->content_unlike(qr{Countermeasures</option>}, 'Queue dropdown doesn\'t have standard countermeasures queue');
    $m->content_unlike(qr{Countermeasures - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET countermeasures queue');
}

diag "check queue visibility when created from incident report" if $ENV{'TEST_VERBOSE'};
{
    my $id = $m->create_rtir_ticket_ok( 'Incident Reports - GOVNET', { Subject => 'test incident report' } );

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=incidents&Child=$id");
    $m->content_like(qr{Incidents - GOVNET</option>}, 'Queue dropdown has GOVNET incidents queue');
    $m->content_unlike(qr{Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');
    $m->content_unlike(qr{Incidents - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incidents queue');
}

diag "check queue visibility when filtering constituency" if $ENV{'TEST_VERBOSE'};
{
    $m->get("$baseurl/RTIR/c/GOVNET/Create.html?Lifecycle=incidents");
    $m->content_like(qr{Incidents - GOVNET</option>}, 'Queue dropdown has GOVNET incidents queue');
    $m->content_unlike(qr{Incidents - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incidents queue');
    $m->content_unlike(qr{Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');

    $m->get("$baseurl/RTIR/c/EDUNET/Create.html?Lifecycle=incidents");
    $m->content_like(qr{Incidents - EDUNET</option>}, 'Queue dropdown has EDUNET incidents queue');
    $m->content_unlike(qr{Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');
    $m->content_unlike(qr{Incidents - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET incidents queue');
}

diag "check queue visibility - eduhandler" if $ENV{'TEST_VERBOSE'};
{
    $m->login('eduhandler', 'eduhandler', logout => 1);

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=incident_reports");
    $m->content_like(qr{Incident Reports - EDUNET</option>}, 'Queue dropdown has EDUNET incident reports queue');
    $m->content_unlike(qr{Incident Reports</option>}, 'Queue dropdown doesn\'t have standard incident reports queue');
    $m->content_unlike(qr{Incident Reports - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET incident reports queue');

    $m->get("$baseurl/RTIR/Incident/Create.html?Lifecycle=incidents");
    $m->content_like(qr{Incidents - EDUNET</option>}, 'Queue dropdown has EDUNET incidents queue');
    $m->content_unlike(qr{Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');
    $m->content_unlike(qr{Incidents - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET incidents queue');

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=investigations");
    $m->content_like(qr{Investigations - EDUNET</option>}, 'Queue dropdown has EDUNET investigations queue');
    $m->content_unlike(qr{Investigations</option>}, 'Queue dropdown doesn\'t have standard investigations queue');
    $m->content_unlike(qr{Investigations - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET investigations queue');

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=countermeasures");
    $m->content_like(qr{Countermeasures - EDUNET</option>}, 'Queue dropdown has EDUNET countermeasures queue');
    $m->content_unlike(qr{Countermeasures</option>}, 'Queue dropdown doesn\'t have standard countermeasures queue');
    $m->content_unlike(qr{Countermeasures - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET countermeasures queue');
}

diag "check queue visibility - govhandler" if $ENV{'TEST_VERBOSE'};
{
    $m->login('govhandler', 'govhandler', logout => 1);

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=incident_reports");
    $m->content_like(qr{Incident Reports - GOVNET</option>}, 'Queue dropdown has GOVNET incident reports queue');
    $m->content_unlike(qr{Incident Reports - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incident reports queue');
    $m->content_unlike(qr{Incident Reports</option>}, 'Queue dropdown doesn\'t have standard incident reports queue');

    $m->get("$baseurl/RTIR/Incident/Create.html?Lifecycle=incidents");
    $m->content_like(qr{Incidents - GOVNET</option>}, 'Queue dropdown has GOVNET incidents queue');
    $m->content_unlike(qr{Incidents - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incidents queue');
    $m->content_unlike(qr{Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=investigations");
    $m->content_like(qr{Investigations - GOVNET</option>}, 'Queue dropdown has GOVNET investigations queue');
    $m->content_unlike(qr{Investigations - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET investigations queue');
    $m->content_unlike(qr{Investigations</option>}, 'Queue dropdown doesn\'t have standard investigations queue');

    $m->get("$baseurl/RTIR/Create.html?Lifecycle=countermeasures");
    $m->content_like(qr{Countermeasures - GOVNET</option>}, 'Queue dropdown has GOVNET countermeasures queue');
    $m->content_unlike(qr{Countermeasures - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET countermeasures queue');
    $m->content_unlike(qr{Countermeasures</option>}, 'Queue dropdown doesn\'t have standard countermeasures queue');
}

undef $m;
done_testing;
