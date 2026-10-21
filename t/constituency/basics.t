use strict;
use warnings;
use utf8;

use RT::IR::Test tests => undef;

use_ok('RT::IR');

my ($baseurl) = RT::Test->started_ok;
my $agent = default_agent();
my $rtir_user = RT::CurrentUser->new( rtir_user() );

my $cf;
diag "load and check basic properties of the CF" if $ENV{'TEST_VERBOSE'};
{
    my $cfs = RT::CustomFields->new( RT->SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => 'RTIR Constituency', CASESENSITIVE => 0 );
    is( $cfs->Count, 1, "found one CF with name 'Constituency'" );

    $cf = $cfs->First;
    is( $cf->Type, 'Select', 'type check' );
    is( $cf->LookupType, 'RT::Queue', 'lookup type check' );
    is( $cf->MaxValues, 1, "single value" );
    ok( !$cf->Disabled, "not disabled" );
}

diag "check that CF applies to all RTIR's queues" if $ENV{'TEST_VERBOSE'};
{
    my $queues = RT::Queues->new( RT->SystemUser );
    $queues->Limit(
        FIELD => 'Lifecycle',
        OPERATOR => 'IN',
        VALUE => [RT::IR->Lifecycles],
    );

    while ( my $queue = $queues->Next ) {
        ok( $queue->id, 'loaded queue '. $queue->id );
        my $cfs = $queue->CustomFields;
        $cfs->Limit( FIELD => 'id', VALUE => $cf->id, ENTRYAGGREGATOR => 'AND' );
        is( $cfs->Count, 1, 'field applies to queue' );
    }
}

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

diag "constituency names with special characters are URI-escaped in RTIR links" if $ENV{'TEST_VERBOSE'};
{
    is( RT::IR->HREFTo( 'Display.html', Constituency => 'EDUNET', IncludeWebPath => 0 ),
        '/RTIR/c/EDUNET/Display.html', 'HREFTo leaves a constituency name without special characters unchanged' );

    for my $test ( [ 'EDU NET', 'EDU%20NET' ], [ 'Défense', 'D%C3%A9fense' ] ) {
        my ( $name, $escaped ) = @$test;

        my $manager = RT::IR::ConstituencyManager->new( Constituency => $name );
        ok( $manager->AddConstituency, "added constituency $name" );

        my $group = RT::Group->new( RT->SystemUser );
        $group->LoadUserDefinedGroup("DutyTeam $name");
        ok( $group->id, "loaded DutyTeam $name" );
        $group->AddMember( $rtir_user->PrincipalId );

        is( RT::IR->HREFTo( 'Display.html', Constituency => $name, IncludeWebPath => 0 ),
            "/RTIR/c/$escaped/Display.html", "HREFTo escapes the constituency name $name" );

        my $ticket = RT::Test->create_ticket(
            Queue   => "Incident Reports - $name",
            Subject => "constituency $name",
            Content => 'report details',
        );
        my $txn_id = $ticket->Transactions->First->id;

        $agent->get_ok( "/RTIR/c/$escaped/Display.html?id=" . $ticket->id,
            "displayed the incident report through the $name constituency" );
        my $dom = $agent->dom;

        my $permalink = $dom->at(qq{span.type a[name="txn-$txn_id"]});
        ok( $permalink, 'history has a permalink for the create transaction' );
        is( $permalink && $permalink->attr('href'), "/RTIR/c/$escaped/Display.html?id=" . $ticket->id . "#txn-$txn_id",
            "permalink points to the RTIR display page in the $name constituency" );

        for my $action ( [ 'reply-link', 'Update.html' ], [ 'comment-link', 'Update.html' ], [ 'forward-link', 'Forward.html' ] ) {
            my ( $class, $page ) = @$action;
            my $link = $dom->at("span.actions a.$class");
            ok( $link, "history has a $class" );
            like( $link && $link->attr('href'), qr{^/RTIR/c/\Q$escaped\E/\Q$page\E\?id=\d+&QuoteTransaction=$txn_id},
                "$class points to $page in the $name constituency" );
        }
    }
}

diag "Create an incident report in the EDUNET queue" if $ENV{'TEST_VERBOSE'};

my $ir_id = $agent->create_rtir_ticket_ok( 'Incident Reports - EDUNET', {
    Subject => "test"
});
ok( $ir_id, "created IR #$ir_id" );
$agent->display_ticket( $ir_id);
$agent->content_like(qr/EDUNET/, "It was created by edunet");

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Load($ir_id);

diag "govhandler can't see the incident report"       if $ENV{'TEST_VERBOSE'};
my $ticket_as_gov = RT::Ticket->new($govhandler);
$ticket_as_gov->Load($ir_id);
is($ticket_as_gov->Subject,undef, "As the gov handler, I can not see the ticket");


diag "eduhandler can see the incident report"         if $ENV{'TEST_VERBOSE'};
my $ticket_as_edu = RT::Ticket->new($eduhandler);
$ticket_as_edu->Load($ir_id);
is($ticket_as_edu->Subject, 'test', "As the edu handler, I can see the ticket");


diag "move the incident report from EDUNET to GOVNET" if $ENV{'TEST_VERBOSE'};
{
    $agent->display_ticket( $ir_id);
    $agent->follow_link_ok({text => 'Edit'}, "go to Edit page");
    $agent->form_number(3);

    my $ir_govnet = RT::Queue->new( RT->SystemUser );
    $ir_govnet->Load( 'Incident Reports - GOVNET' );

    $agent->set_fields(
        Queue => $ir_govnet->id,
    );

    $agent->click('SaveChanges');
    is( $agent->status, 200, "Attempting to edit ticket #$ir_id" );
    $agent->content_like( qr/GOVNET/, "value on the page" );

    DBIx::SearchBuilder::Record::Cachable::FlushCache();
}

diag "govhandler can see the incident report"         if $ENV{'TEST_VERBOSE'};
$ticket_as_gov = RT::Ticket->new($govhandler);
$ticket_as_gov->Load($ir_id);
is($ticket_as_gov->Subject, 'test',"As the gov handler, I can see the ticket");

diag "eduhandler can't see the incident report"       if $ENV{'TEST_VERBOSE'};

$ticket_as_edu = RT::Ticket->new($eduhandler);
$ticket_as_edu->Load($ir_id);
is($ticket_as_edu->Subject,undef , "As the edu handler, I can not see the ticket");


my $edunet_suffix = ' - EDUNET';
my $govnet_suffix = ' - GOVNET';

diag "check queues names on page - eduhandler";
{
    $agent->login('eduhandler', 'eduhandler', logout => 1 );

    for my $queue_name ('Incident Reports', 'Incidents', 'Countermeasures', 'Investigations') {
        $agent->content_contains($queue_name . $edunet_suffix);
        $agent->content_lacks($queue_name . $govnet_suffix);
    }
}

diag "check queue names on page - govhandler";
{
    $agent->login('govhandler', 'govhandler', logout => 1);

    for my $queue_name ('Incident Reports', 'Incidents', 'Countermeasures', 'Investigations') {
        $agent->content_lacks($queue_name . $edunet_suffix);
        $agent->content_contains($queue_name . $govnet_suffix);
    }
}

SKIP: { skip "Create incident and investigation functionality disabled for now", 6;
diag "check queues when creating inc with inv - govhandler";
{
    $agent->login('govhandler', 'govhandler', logout => 1);
	my ($inc_id, $inv_id) = $agent->create_incident_and_investigation('GOVNET',
	    {
            Subject => "Incident",
		    InvestigationSubject => "Investigation",
		    InvestigationRequestors => 'requestor@example.com',
        },
    );
    $agent->content_contains('Incidents'.$govnet_suffix);
    $agent->content_contains('Investigations'.$govnet_suffix);
}
}

SKIP: { skip "Create incident and investigation functionality disabled for now", 6;
diag "check queues when creating inc with inv - eduhandler";
{
    $agent->login('eduhandler', 'eduhandler', logout => 1);
	my ($inc_id, $inv_id) = $agent->create_incident_and_investigation('EDUNET',
	    {
            Subject => "Incident",
		    InvestigationSubject => "Investigation",
		    InvestigationRequestors => 'requestor@example.com',
        },
    );
    $agent->content_contains('Incidents'.$edunet_suffix);
    $agent->content_contains('Investigations'.$edunet_suffix);
}
}

undef $agent;
done_testing;
