#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 111;
require "t/rtir-test.pl";

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

diag "check that there is no option to set 'no value' on create" if $ENV{'TEST_VERBOSE'};
{
    my $default = RT->Config->Get('_RTIR_Constituency_default');
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "'$queue' queue" if $ENV{'TEST_VERBOSE'};

        goto_create_rtir_ticket( $agent, $queue );

        my $value = $agent->form_number(3)->value("Object-RT::Ticket--CustomField-". $cf->id ."-Values");
        is lc $value, lc $default, 'correct value is selected';

        my @values = $agent->form_number(3)->param("Object-RT::Ticket--CustomField-". $cf->id ."-Values");
        ok !grep( $_ eq '', @values ), 'have no empty value for selection';
    }
}

diag "create a ticket via web and set field" if $ENV{'TEST_VERBOSE'};
{
    # we skip blocks here, as they are always connected to
    # an incident and constituency inheritance comes into game
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $val = 'GOVNET';
        my $id = create_rtir_ticket_ok(
            $agent, $queue,
            { Subject => "test ip" },
            { Constituency => $val },
        );

        display_ticket($agent, $id);
        $agent->content_like( qr/\Q$val/, "value on the page" );
        DBIx::SearchBuilder::Record::Cachable::FlushCache();

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), $val, 'correct value' );

diag "check that we can edit value" if $ENV{'TEST_VERBOSE'};
        $agent->follow_link( text => 'Edit' );
        $agent->content_like(qr/Constituency/, 'CF on the page');

        my $value = $agent->form_number(3)->value("Object-RT::Ticket-$id-CustomField-". $cf->id ."-Values");
        is lc $value, 'govnet', 'correct value is selected';

        $val = 'EDUNET';
        $agent->select("Object-RT::Ticket-$id-CustomField-". $cf->id ."-Values" => $val );
        $agent->click('SaveChanges');
        $agent->content_like(qr/Constituency .* changed to \Q$val/mi, 'field is changed') or diag $agent->content;
        DBIx::SearchBuilder::Record::Cachable::FlushCache();

        $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( lc $ticket->FirstCustomFieldValue('_RTIR_Constituency'), lc $val, 'correct value' );
    }
}

my $eduhandler = RT::Test->load_or_create_user( Name => 'eduhandler' );
ok $eduhandler->id, "Created eduhandler";

my $govhandler = RT::Test->load_or_create_user( Name => 'govhandler' );
ok $govhandler->id, "Created govhandler";

my $govqueue = RT::Test->load_or_create_queue(
    Name => 'Incident Reports - GOVNET',
    CorrespondAddress => 'govnet@example.com',
);
ok $govqueue->id, "loaded or created queue";

my $eduqueue = RT::Test->load_or_create_queue(
    Name => 'Incident Reports - EDUNET',
    CorrespondAddress => 'edunet@example.com',
);
ok $eduqueue->id, "loaded or created queue";

diag "Grant govhandler the right to see tickets in Incident Reports - GOVNET" if $ENV{'TEST_VERBOSE'};
{ 
    my ($val,$msg)  = $govhandler->PrincipalObj->GrantRight(Right => 'ShowTicket', Object => $govqueue);
    ok $val || $msg =~ /That principal already has that right/, $msg;

    ok($govqueue->HasRight(Principal => $govhandler, Right => 'ShowTicket'), "Govhnadler can see govtix"); 
    ok(!$govqueue->HasRight(Principal => $eduhandler, Right => 'ShowTicket'), "eduhandler can not see gov tix"); 
}


diag "Grant eduhandler the right to see tickets in Incident Reports - EDUNET" if $ENV{'TEST_VERBOSE'};
{ 
    my ($val,$msg) = $eduhandler->PrincipalObj->GrantRight(Right => 'ShowTicket', Object => $eduqueue);
    ok $val || $msg =~ /That principal already has that right/, $msg;
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
$txns->Limit( FIELD => 'Type', VALUE => 'EmailRecord' );
ok $txns->Count, 'we have at least one email record';

my $from_ok = 1;
while ( my $txn = $txns->Next ) {
    my $from = $txn->Attachments->First->GetHeader('From');
    next if $from =~ /edunet/;

    $from_ok = 0;
    last;
}
ok $from_ok, "The from address picked up the edunet address";


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
