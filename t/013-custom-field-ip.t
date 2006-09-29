#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 185;

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
my $rtir_user = RT::CurrentUser->new( rtir_user() );

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

diag "check that IPs in messages don't add duplicates" if $ENV{'TEST_VERBOSE'};
{
    my $id = create_ir( $agent, {
        Subject => "test ip",
        Content => '192.168.20.2 192.168.20.2 192.168.20/30'
    } );
    ok($id, "created first ticket");

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    ok( $ticket->id, 'loaded ticket' );

    my $values = $ticket->CustomFieldValues('_RTIR_IP');
    my %has;
    $has{ $_->Content }++ foreach @{ $values->ItemsArrayRef };
    is(scalar values %has, 4, "four IPs were added");
    ok(!grep( $_ != 1, values %has), "no duplicated values");
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

    my $flag = 1;
    while ( my $ticket = $tickets->Next ) {
        my %has = map { $_->Content => 1 } @{ $ticket->CustomFieldValues('_RTIR_IP')->ItemsArrayRef };
        next if $has{'172.16.1.1'};
        $flag = 0;
        ok(0, "ticket #". $ticket->id ." has no IP 172.16.1.1, but should");
        last;
    }
    ok(1, "all tickets has IP 172.16.1.1") if $flag;
}

diag "search tickets by IP range" if $ENV{'TEST_VERBOSE'};
{
    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("CF.{_RTIR_IP} = '172.16.2.0-172.16.2.255'");
    ok( $tickets->Count, "found tickets" );

    my $flag = 1;
    while ( my $ticket = $tickets->Next ) {
        my %has = map { $_->Content => 1 } @{ $ticket->CustomFieldValues('_RTIR_IP')->ItemsArrayRef };
        next if grep /^172\.16\.2\./, keys %has;
        $flag = 0;
        ok(0, "ticket #". $ticket->id ." has no IP from 172.16.2.0-172.16.2.255, but should");
        last;
    }
    ok(1, "all tickets have at least one IP from 172.16.2.0-172.16.2.255") if $flag;
}

diag "search tickets within CIDR block" if $ENV{'TEST_VERBOSE'};
{
    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("CF.{_RTIR_IP} = '172.16.2/24'");
    ok( $tickets->Count, "found tickets" );
    $tickets->FromSQL("CF.{_RTIR_IP} = '172.16/16'");
    ok( $tickets->Count, "found tickets" );
}

diag "create two tickets with different IPs and check several searches" if $ENV{'TEST_VERBOSE'};
{
    my $id1 = create_ir( $agent, { Subject => "test ip" }, { IP => '192.168.21.10' } );
    ok($id1, "created first ticket");
    my $id2 = create_ir( $agent, { Subject => "test ip" }, { IP => '192.168.22.10' } );
    ok($id2, "created second ticket");

    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("id = $id1 OR id = $id2");
    is( $tickets->Count, 2, "found both tickets by 'id = x OR y'" );

    # IP
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.21.10'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.21.10', "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.22.10'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.22.10', "correct value" );

    # IP/32 - one address
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.21.10/32'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.21.10', "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.22.10/32'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.22.10', "correct value" );

    # IP range
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.21.0-192.168.21.255'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.21.10', "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.22.0-192.168.22.255'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.22.10', "correct value" );

    # IP range, with start IP greater than end
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.21.255-192.168.21.0'");
    TODO: { local $TODO = "not yet implemented";
        is( $tickets->Count, 1, "found one ticket" );
        #is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.21.10', "correct value" );
    }
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.22.255-192.168.22.0'");
    TODO: { local $TODO = "not yet implemented";
        is( $tickets->Count, 1, "found one ticket" );
        #is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.22.10', "correct value" );
    }

    # CIDR/24
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.21.0/24'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.21.10', "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} = '192.168.22.0/24'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.22.10', "correct value" );

    # IP is not in CIDR/24
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} != '192.168.21.0/24'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.22.10', "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{_RTIR_IP} != '192.168.22.0/24'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->FirstCustomFieldValue('_RTIR_IP'), '192.168.21.10', "correct value" );

    # CIDR or CIDR
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND "
        ."(CF.{_RTIR_IP} = '192.168.21.0/24' OR CF.{_RTIR_IP} = '192.168.22.0/24')");
    is( $tickets->Count, 2, "found both tickets" );
}

