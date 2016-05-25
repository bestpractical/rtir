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
        ok !system("bin/add_constituency --quiet --force --name $constituency_name 2>&1"), "add_constituency $constituency_name ran successfully";
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

diag "check queue visibility in modal" if $ENV{'TEST_VERBOSE'};
{
    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=incident_reports");
    $m->content_like(qr{<option value="\d+">Incident Reports</option>}, 'Queue dropdown has standard incident reports queue');
    $m->content_like(qr{<option value="\d+">Incident Reports - EDUNET</option>}, 'Queue dropdown has EDUNET incident reports queue');
    $m->content_like(qr{<option value="\d+">Incident Reports - GOVNET</option>}, 'Queue dropdown has GOVNET incident reports queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=incidents");
    $m->content_like(qr{<option value="\d+">Incidents</option>}, 'Queue dropdown has standard incidents queue');
    $m->content_like(qr{<option value="\d+">Incidents - EDUNET</option>}, 'Queue dropdown has EDUNET incidents queue');
    $m->content_like(qr{<option value="\d+">Incidents - GOVNET</option>}, 'Queue dropdown has GOVNET incidents queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=investigations");
    $m->content_like(qr{<option value="\d+">Investigations</option>}, 'Queue dropdown has standard investigations queue');
    $m->content_like(qr{<option value="\d+">Investigations - EDUNET</option>}, 'Queue dropdown has EDUNET investigations queue');
    $m->content_like(qr{<option value="\d+">Investigations - GOVNET</option>}, 'Queue dropdown has GOVNET investigations queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=blocks");
    $m->content_like(qr{<option value="\d+">Countermeasures</option>}, 'Queue dropdown has standard blocks queue');
    $m->content_like(qr{<option value="\d+">Countermeasures - EDUNET</option>}, 'Queue dropdown has EDUNET blocks queue');
    $m->content_like(qr{<option value="\d+">Countermeasures - GOVNET</option>}, 'Queue dropdown has GOVNET blocks queue');
}

diag "check queue visibility in modal when created from incident" if $ENV{'TEST_VERBOSE'};
{
    my $i = RT::Ticket->new( $rtir_user );
    ($ok, $msg) = $i->Create(
        Subject => 'test incident',
        Queue => 'Incidents - GOVNET',
    );
    ok($ok, 'created test incident');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=incident_reports&Incident=".$i->id);
    $m->content_like(qr{<option value="\d+">Incident Reports - GOVNET</option>}, 'Queue dropdown has GOVNET incident reports queue');
    $m->content_unlike(qr{<option value="\d+">Incident Reports</option>}, 'Queue dropdown doesn\'t have standard incident reports queue');
    $m->content_unlike(qr{<option value="\d+">Incident Reports - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incident reports queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=investigations&Incident=".$i->id);
    $m->content_like(qr{<option value="\d+">Investigations - GOVNET</option>}, 'Queue dropdown has GOVNET investigations queue');
    $m->content_unlike(qr{<option value="\d+">Investigations</option>}, 'Queue dropdown doesn\'t have standard investigations queue');
    $m->content_unlike(qr{<option value="\d+">Investigations - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET investigations queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=blocks&Incident=".$i->id);
    $m->content_like(qr{<option value="\d+">Countermeasures - GOVNET</option>}, 'Queue dropdown has GOVNET blocks queue');
    $m->content_unlike(qr{<option value="\d+">Countermeasures</option>}, 'Queue dropdown doesn\'t have standard blocks queue');
    $m->content_unlike(qr{<option value="\d+">Countermeasures - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET blocks queue');
}

diag "check queue visibility in modal when created from incident report" if $ENV{'TEST_VERBOSE'};
{
    my $r = RT::Ticket->new( $rtir_user );
    ($ok, $msg) = $r->Create(
        Subject => 'test incident report',
        Queue => 'Incident Reports - GOVNET',
    );
    ok($ok, 'created test incident report');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=incidents&Child=".$r->id);
    $m->content_like(qr{<option value="\d+">Incidents - GOVNET</option>}, 'Queue dropdown has GOVNET incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incidents queue');
}

diag "check queue visibility in modal when filtering constituency" if $ENV{'TEST_VERBOSE'};
{
    $m->get("$baseurl/RTIR/c/GOVNET/Helpers/CreateInRTIRQueueModal?Lifecycle=incidents");
    $m->content_like(qr{<option value="\d+">Incidents - GOVNET</option>}, 'Queue dropdown has GOVNET incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');

    $m->get("$baseurl/RTIR/c/EDUNET/Helpers/CreateInRTIRQueueModal?Lifecycle=incidents");
    $m->content_like(qr{<option value="\d+">Incidents - EDUNET</option>}, 'Queue dropdown has EDUNET incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET incidents queue');
}

diag "check queue visibility in modal - eduhandler" if $ENV{'TEST_VERBOSE'};
{
    $m->login('eduhandler', 'eduhandler', logout => 1);

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=incident_reports");
    $m->content_like(qr{<option value="\d+">Incident Reports - EDUNET</option>}, 'Queue dropdown has EDUNET incident reports queue');
    $m->content_unlike(qr{<option value="\d+">Incident Reports</option>}, 'Queue dropdown doesn\'t have standard incident reports queue');
    $m->content_unlike(qr{<option value="\d+">Incident Reports - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET incident reports queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=incidents");
    $m->content_like(qr{<option value="\d+">Incidents - EDUNET</option>}, 'Queue dropdown has EDUNET incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET incidents queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=investigations");
    $m->content_like(qr{<option value="\d+">Investigations - EDUNET</option>}, 'Queue dropdown has EDUNET investigations queue');
    $m->content_unlike(qr{<option value="\d+">Investigations</option>}, 'Queue dropdown doesn\'t have standard investigations queue');
    $m->content_unlike(qr{<option value="\d+">Investigations - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET investigations queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=blocks");
    $m->content_like(qr{<option value="\d+">Countermeasures - EDUNET</option>}, 'Queue dropdown has EDUNET blocks queue');
    $m->content_unlike(qr{<option value="\d+">Countermeasures</option>}, 'Queue dropdown doesn\'t have standard blocks queue');
    $m->content_unlike(qr{<option value="\d+">Countermeasures - GOVNET</option>}, 'Queue dropdown doesn\'t have GOVNET blocks queue');
}

diag "check queue visibility in modal - govhandler" if $ENV{'TEST_VERBOSE'};
{
    $m->login('govhandler', 'govhandler', logout => 1);

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=incident_reports");
    $m->content_like(qr{<option value="\d+">Incident Reports - GOVNET</option>}, 'Queue dropdown has GOVNET incident reports queue');
    $m->content_unlike(qr{<option value="\d+">Incident Reports - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incident reports queue');
    $m->content_unlike(qr{<option value="\d+">Incident Reports</option>}, 'Queue dropdown doesn\'t have standard incident reports queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=incidents");
    $m->content_like(qr{<option value="\d+">Incidents - GOVNET</option>}, 'Queue dropdown has GOVNET incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET incidents queue');
    $m->content_unlike(qr{<option value="\d+">Incidents</option>}, 'Queue dropdown doesn\'t have standard incidents queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=investigations");
    $m->content_like(qr{<option value="\d+">Investigations - GOVNET</option>}, 'Queue dropdown has GOVNET investigations queue');
    $m->content_unlike(qr{<option value="\d+">Investigations - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET investigations queue');
    $m->content_unlike(qr{<option value="\d+">Investigations</option>}, 'Queue dropdown doesn\'t have standard investigations queue');

    $m->get("$baseurl/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=blocks");
    $m->content_like(qr{<option value="\d+">Countermeasures - GOVNET</option>}, 'Queue dropdown has GOVNET blocks queue');
    $m->content_unlike(qr{<option value="\d+">Countermeasures - EDUNET</option>}, 'Queue dropdown doesn\'t have EDUNET blocks queue');
    $m->content_unlike(qr{<option value="\d+">Countermeasures</option>}, 'Queue dropdown doesn\'t have standard blocks queue');
}

undef $m;
done_testing;
