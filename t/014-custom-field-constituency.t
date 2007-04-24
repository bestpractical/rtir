#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 182;
no warnings 'once';

require "t/rtir-test.pl";

# Test must be run wtih RT_SiteConfig:
# Set(@MailPlugins, 'Auth::MailFrom');

use_ok('RT');
RT::LoadConfig();
RT::Init();

use_ok('RT::IR');

my $cf;
diag "load and check basic properties of the CF" if $ENV{'TEST_VERBOSE'};
{
    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => '_RTIR_Constituency' );
    is( $cfs->Count, 1, "found one CF with name '_RTIR_Constituency'" );

    $cf = $cfs->First;
    is( $cf->Type, 'Select', 'type check' );
    is( $cf->LookupType, 'RT::Queue-RT::Ticket', 'lookup type check' );
    is( $cf->MaxValues, 1, "single value" );
    ok( !$cf->Disabled, "not disabled" );
}

diag "check that CF applies to all RTIR's queues" if $ENV{'TEST_VERBOSE'};
{
    foreach ( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        my $queue = RT::Queue->new( $RT::SystemUser );
        $queue->Load( $_ );
        ok( $queue->id, 'loaded queue '. $_ );
        my $cfs = $queue->TicketCustomFields;
        $cfs->Limit( FIELD => 'id', VALUE => $cf->id, ENTRYAGGREGATOR => 'AND' );
        is( $cfs->Count, 1, 'field applies to queue' );
    }
}

my @constituencies;
diag "fetch list of constituencies and check that groups exist" if $ENV{'TEST_VERBOSE'};
{
    @constituencies = map $_->Name, @{ $cf->Values->ItemsArrayRef };
    ok( scalar @constituencies, "field has some predefined values" );
    foreach ( @constituencies ) {
        my $group = RT::Group->new( $RT::SystemUser );
        $group->LoadUserDefinedGroup( 'DutyTeam '. $_ );
        ok( $group->id, "loaded group for $_ constituency" );
    }
}

my $agent = default_agent();
my $rtir_user = rtir_user();

diag "create a ticket via web and set field" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;
    my $incident_id; # block couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $val = 'GOVNET';
        my $id = create_rtir_ticket(
            $agent, $queue,
            {
                Subject => "test ip",
                ($queue eq 'Blocks'? (Incident => $incident_id): ()),
            },
            { Constituency => $val },
        );
        $incident_id = $id if $queue eq 'Incidents';

        display_ticket($agent, $id);
        $agent->content_like( qr/\Q$val/, "value on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), $val, 'correct value' );
    }
}

diag "create a ticket via gate" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;
    my $incident_id; # block couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $text = <<EOF;
From: @{[ $rtir_user->EmailAddress ]}
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: This is a test of constituency functionality

Foob!
EOF
        my $val = 'GOVNET';
        local $ENV{'EXTENSION'} = $val;
        my ($status, $id) = create_ticket_via_gate($text, queue => $queue);
        is ($status >> 8, 0, "The mail gateway exited ok");
        ok ($id, "created ticket $id");
        $incident_id = $id if $queue eq 'Incidents';

        display_ticket($agent, $id);
        $agent->content_like( qr/\Q$val/, "value on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->QueueObj->Name, $queue, 'correct queue' );
        is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), $val, 'correct value' );
    }
}

diag "create an IR under EDUNET and create new incident from it" if $ENV{'TEST_VERBOSE'};
{
    my $val = 'EDUNET';
    my $ir_id = create_ir(
        $agent, { Subject => "test" }, { Constituency => $val }
    );
    ok( $ir_id, "created IR #$ir_id" );
    display_ticket($agent, $ir_id);
    $agent->content_like( qr/\Q$val/, "value on the page" );

    my $inc_id = create_incident_for_ir(
        $agent, $ir_id, { Subject => "test" },
    );

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->QueueObj->Name, 'Incidents', 'correct value' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), $val, 'correct value' );

diag "edit constituency on the IR and check that change is cascading" if $ENV{'TEST_VERBOSE'};

    display_ticket($agent, $ir_id);
    $agent->follow_link_ok({text => 'Edit'}, "go to Edit page");
    $agent->form_number(3);
    ok(set_custom_field( $agent, Constituency => 'GOVNET' ), "fill value in the form");
    $agent->click('SaveChanges');
    is( $agent->status, 200, "Attempting to edit ticket #$ir_id" );
    $agent->content_like( qr/GOVNET/, "value on the page" );

    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), 'GOVNET', 'correct value' );

    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $ir_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), 'GOVNET', 'correct value' );

    
}

diag "create an incident under GOVNET and create a new IR linked to the incident" if $ENV{'TEST_VERBOSE'};
{
    diag "ferst of all create incident" if $ENV{'TEST_VERBOSE'};
    my $inc_id = create_incident(
        $agent, { Subject => "test" }, { Constituency => 'GOVNET' }
    );
    ok( $inc_id, "created ticket #$inc_id" );
    display_ticket( $agent, $inc_id );
    $agent->content_like( qr/GOVNET/, "value on the page" );
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->QueueObj->Name, 'Incidents', 'correct value' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), 'GOVNET', 'correct value' );

    my $ir_id = create_ir(
        $agent, { Subject => "test", Incident => $inc_id }, { Constituency => 'EDUNET' },
    );
    ticket_is_linked_to_inc( $agent, $ir_id => $inc_id );

    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $ir_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->QueueObj->Name, 'Incident Reports', 'correct value' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), 'GOVNET', 'correct value' );

    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->QueueObj->Name, 'Incidents', 'correct value' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), 'GOVNET', 'correct value' );
}

diag "create an IR and check that we couldn't change value during creation of new linked incident" if $ENV{'TEST_VERBOSE'};
{
    # create an IR
    my $ir_id = create_ir(
        $agent, { Subject => "test" }, { Constituency => 'GOVNET' }
    );
    ok( $ir_id, "created ticket #$ir_id" );
    display_ticket($agent, $ir_id);
    $agent->content_like( qr/GOVNET/, "value on the page" );
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $ir_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->QueueObj->Name, 'Incident Reports', 'correct value' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), 'GOVNET', 'correct value' );

    # click [new] near 'incident', set another constituency and create
    $agent->follow_link_ok({text => '[New]'}, "go to 'New Incident' page");
    $agent->form_number(3);
    ok(!eval{ set_custom_field( $agent, Constituency => 'EDUNET' ) }, "couldn't change value in the form");
    $agent->click('CreateIncident');
    is ($agent->status, 200, "Attempted to create the ticket");

    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    # Incident has the new value 
    my $inc_id = get_ticket_id( $agent );
    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->QueueObj->Name, 'Incidents', 'correct value' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), 'GOVNET', 'correct value' );

    # Incident's value is prefered and was inhertied by the IR
    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $ir_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->QueueObj->Name, 'Incident Reports', 'correct value' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), 'GOVNET', 'correct value' );
}

my $eduhandler = RT::User->new($RT::SystemUser);
$eduhandler->Create(Name => 'eduhandler-'.$$, Privileged => 1);
ok($eduhandler->id, "Created eduhandler");
my $govhandler = RT::User->new($RT::SystemUser);
$govhandler->Create(Name => 'govhandler-'.$$, Privileged => 1);
ok($govhandler->id, "Created govhandler");

my $govqueue = RT::Queue->new($RT::SystemUser);
$govqueue->LoadByCols(Name => 'Incident Reports - GOVNET');
unless ($govqueue->id) {
$govqueue->Create(Name => 'Incident Reports - GOVNET', CorrespondAddress => 'govnet@example.com');
}
ok ($govqueue->id);
my $eduqueue = RT::Queue->new($RT::SystemUser);
$eduqueue->LoadByCols(Name => 'Incident Reports - EDUNET');
unless ($eduqueue->id)  {$eduqueue->Create(Name => 'Incident Reports - EDUNET', CorrespondAddress => 'edunet@example.com' )};
ok($eduqueue->id);
diag "Grant govhandler the right to see tickets in Incident Reports - GOVNET" if $ENV{'TEST_VERBOSE'};

{ 
    my ($val,$msg)  = $govhandler->PrincipalObj->GrantRight(Right => 'ShowTicket', Object => $govqueue);
    ok ($val,$msg);

    ok($govqueue->HasRight(Principal => $govhandler, Right => 'ShowTicket'), "Govhnadler can see govtix"); 
    ok(!$govqueue->HasRight(Principal => $eduhandler, Right => 'ShowTicket'), "eduhandler can not see gov tix"); 

}


diag "Grant eduhandler the right to see tickets in Incident Reports - EDUNET" if $ENV{'TEST_VERBOSE'};
{ 
    my ($val,$msg)  = $eduhandler->PrincipalObj->GrantRight(Right => 'ShowTicket', Object => $eduqueue);
    ok ($val,$msg);
    ok($eduqueue->HasRight(Principal => $eduhandler, Right => 'ShowTicket'), "For the eduqueue, eduhandler can see tix"); 
    ok(!$eduqueue->HasRight(Principal => $govhandler, Right => 'ShowTicket'), "For the eduqueue, govhandler can not seetix"); 
}
diag "Create an incident report with a default constituency of EDUNET" if $ENV{'TEST_VERBOSE'};


    my $val = 'EDUNET';
    my $ir_id = create_ir(
        $agent, { Subject => "test" }, { Constituency => $val }
    );
    ok( $ir_id, "created IR #$ir_id" );
    display_ticket($agent, $ir_id);
    $agent->content_like(qr/EDUNET/, "It was created by edunet");

diag "autoreply comes from the EDUNET queue address" if $ENV{'TEST_VERBOSE'};
my $ticket = RT::Ticket->new($RT::SystemUser);
$ticket->Load($ir_id);
$ticket->AddWatcher(Type => 'Requestor', Email => 'enduser@example.com');
$ticket->Correspond(Content => 'Testing');
my $txns = $ticket->Transactions;
my $from;
while (my $txn = $txns->Next) {
    next unless ($txn->Type eq 'EmailRecord');
    $from = $txn->Attachments->First->GetHeader('From');
    last;
}
ok($from =~ /edunet/, "The from address pciked up the edunet address");


diag "govhandler can't see the incident report"       if $ENV{'TEST_VERBOSE'};
my $ticket_as_gov = RT::Ticket->new($govhandler);
$ticket_as_gov->Load($ir_id);
is($ticket_as_gov->Subject,undef, "As the gov handler, I can not see the ticket");


diag "eduhandler can see the incident report"         if $ENV{'TEST_VERBOSE'};
my $ticket_as_edu = RT::Ticket->new($eduhandler);
$ticket_as_edu->Load($ir_id);
is($ticket_as_edu->Subject, 'test', "As the edu handler, I can see the ticket");




diag "move the incident report from EDUNET to GOVNET" if $ENV{'TEST_VERBOSE'};

    display_ticket($agent, $ir_id);
    $agent->follow_link_ok({text => 'Edit'}, "go to Edit page");
    $agent->form_number(3);
    ok(set_custom_field( $agent, Constituency => 'GOVNET' ), "fill value in the form");
    $agent->click('SaveChanges');
    is( $agent->status, 200, "Attempting to edit ticket #$ir_id" );
    $agent->content_like( qr/GOVNET/, "value on the page" );

    DBIx::SearchBuilder::Record::Cachable::FlushCache();
        $RT::IR::ConstituencyCache->{$ir_id}  = undef;


diag "govhandler can see the incident report"         if $ENV{'TEST_VERBOSE'};
$ticket_as_gov = RT::Ticket->new($govhandler);
$ticket_as_gov->Load($ir_id);
is($ticket_as_gov->Subject, 'test',"As the gov handler, I can see the ticket");

diag "eduhandler can't see the incident report"       if $ENV{'TEST_VERBOSE'};
 
$ticket_as_edu = RT::Ticket->new($eduhandler);
$ticket_as_edu->Load($ir_id);
is($ticket_as_edu->Subject,undef , "As the edu handler, I can not see the ticket");

diag "govhandler replies to the incident report" if $ENV{'TEST_VERBOSE'};
$ticket_as_gov->Correspond(Content => 'Testing 2');
diag "reply comes from the GOVNET queue address" if $ENV{'TEST_VERBOSE'};
{
my $txns = $ticket->Transactions;
my $from;
while (my $txn = $txns->Next) {
    next unless ($txn->Type eq 'EmailRecord');
    $from = $txn->Attachments->First->GetHeader('From');
}
ok($from =~ /govnet/, "The from address pciked up the gov address");

}
