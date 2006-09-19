#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 97;

require "t/rtir-test.pl";

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
}

diag "create an incident under GOVNET and create a new IR linked to the incident" if $ENV{'TEST_VERBOSE'};
{
    diag "ferst of all create incident" if $ENV{'TEST_VERBOSE'};
    my $val = 'GOVNET';
    my $inc_id = create_incident(
        $agent, { Subject => "test" }, { Constituency => $val }
    );
    ok( $inc_id, "created ticket #$inc_id" );
    display_ticket($agent, $inc_id);
    $agent->content_like( qr/\Q$val/, "value on the page" );
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->QueueObj->Name, 'Incidents', 'correct value' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), $val, 'correct value' );

    my $id = create_ir( $agent, { Subject => "test", Incident => $inc_id } );
    ticket_is_linked_to_inc( $agent, $id => $inc_id );
    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    ok( $ticket->id, 'loaded ticket' );
    is( $ticket->QueueObj->Name, 'Incident Reports', 'correct value' );
    is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), $val, 'correct value' );
}
