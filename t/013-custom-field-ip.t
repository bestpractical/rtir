#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 138;

require "t/rtir-test.pl";

use_ok('RT');
RT::LoadConfig();
RT::Init();

use_ok('RT::IR');

my $cf;
diag "load and check basic properties of the IP CF" if $ENV{'TEST_VERBOSE'};
{
    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => '_RTIR_IP' );
    is( $cfs->Count, 1, "found one CF with name '_RTIR_IP'" );

    $cf = $cfs->First;
    is( $cf->Type, 'Freeform', 'type check' );
    is( $cf->LookupType, 'RT::Queue-RT::Ticket', 'lookup type check' );
    ok( !$cf->MaxValues, "unlimited number of values" );
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

diag "create a ticket via web and set IP" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;
    my $incident_id; # block couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $val = '192.168.20.'. ++$i;
        my $id = create_rtir_ticket(
            $agent, $queue,
            {
                Subject => "test ip",
                ($queue eq 'Blocks'? (Incident => $incident_id): ()),
            },
            { IP => $val },
        );
        $incident_id = $id if $queue eq 'Incidents';

        display_ticket($agent, $id);
        $agent->content_like( qr/\Q$val/, "IP on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue('_RTIR_IP'), $val, 'correct value' );
    }
}

diag "create a ticket via web with IP in message" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;
    my $incident_id; # block couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $val = '192.168.20.'. ++$i;
        my $id = create_rtir_ticket(
            $agent, $queue,
            {
                Subject => "test ip in message",
                ($queue eq 'Blocks'? (Incident => $incident_id): ()),
                Content => "$val",
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        display_ticket($agent, $id);
        $agent->content_like( qr/\Q$val/, "IP on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue('_RTIR_IP'), $val, 'correct value' );
    }
}

diag "create a ticket via web with CIDR in message" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;
    my $incident_id; # block couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $val = '172.16.'. ++$i .'/31'; # add two hosts
        my $id = create_rtir_ticket(
            $agent, $queue,
            {
                Subject => "test ip in message",
                ($queue eq 'Blocks'? (Incident => $incident_id): ()),
                Content => "$val",
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        display_ticket($agent, $id);
        $agent->content_like( qr/172\.16\.$i\.1/, "IP on the page" );
        $agent->content_like( qr/172\.16\.$i\.2/, "IP on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        my $values = $ticket->CustomFieldValues('_RTIR_IP');
        my %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        ok( $has{ "172.16.$i.1" }, "has value" ) or diag "but has values ". join ", ", keys %has;
        ok( $has{ "172.16.$i.2" }, "has value" ) or diag "but has values ". join ", ", keys %has;
    }
}

diag "search tickets by IP" if $ENV{'TEST_VERBOSE'};
{
    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("CF.{_RTIR_IP} = '172.16.1.1'");
    ok( $tickets->Count, "found tickets" );
}

diag "search tickets by IP range" if $ENV{'TEST_VERBOSE'};
{
    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("CF.{_RTIR_IP} = '172.16.2.0-172.16.2.255'");
    ok( $tickets->Count, "found tickets" );
}

diag "search tickets within CIDR block" if $ENV{'TEST_VERBOSE'};
{
    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("CF.{_RTIR_IP} = '172.16.2/24'");
    ok( $tickets->Count, "found tickets" );
    $tickets->FromSQL("CF.{_RTIR_IP} = '172.16/16'");
    ok( $tickets->Count, "found tickets" );
}
