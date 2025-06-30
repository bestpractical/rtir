#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

my $cf;
diag "load and check basic properties of the CVE ID CF";
{
    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => 'CVE ID', CASESENSITIVE => 0 );
    is( $cfs->Count, 1, "found one CF with name 'CVE ID'" );

    $cf = $cfs->First;
    is( $cf->Type,       'Freeform',             'type check' );
    is( $cf->LookupType, 'RT::Queue-RT::Ticket', 'lookup type check' );
    ok( !$cf->MaxValues, "unlimited number of values" );
    ok( !$cf->Disabled,  "not disabled" );
}

diag "check that CF applies to all RTIR's queues";
{
    foreach ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        my $queue = RT::Queue->new( $RT::SystemUser );
        $queue->Load( $_ );
        ok( $queue->id, 'loaded queue ' . $_ );
        my $cfs = $queue->TicketCustomFields;
        $cfs->Limit( FIELD => 'id', VALUE => $cf->id, ENTRYAGGREGATOR => 'AND' );
        is( $cfs->Count, 1, 'field applies to queue' );
    }
}

my $rtir_user = RT::CurrentUser->new( rtir_user() );

diag "create a ticket via web and set CVE ID";
{
    my $i = 0;
    my $incident_id;    # countermeasure couldn't be created without incident id
    foreach my $queue ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue";

        my $val = 'CVE-2021-' . sprintf '%04d', ++$i;
        my $id  = $agent->create_rtir_ticket_ok(
            $queue,
            { Subject => "test CVE ID", ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ), },
            { 'CVE ID' => $val },
        );
        $incident_id = $id if $queue eq 'Incidents';

        $agent->content_like( qr/\Q$val/, "CVE ID on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue( 'CVE ID' ), $val, 'correct value' );
    }
}

diag "create a ticket via web with CVE ID in message";
{
    my $i = 0;
    my $incident_id;    # countermeasure couldn't be created without incident id
    foreach my $queue ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue";

        my $val = 'CVE-2021-' . sprintf '%04d', ++$i;
        my $id  = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test CVE ID in message",
                ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ), Content => "$val",
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        $agent->content_like( qr/\Q$val/, "CVE ID on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue( 'CVE ID' ), $val, 'correct value' );
    }
}

diag "create a ticket and edit CVE ID field using Edit page";
{
    my $i = 0;
    my $incident_id;    # countermeasure couldn't be created without incident id
    foreach my $queue ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue";

        my $id = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test CVE ID in message",
                ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ),
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        my $field_name = "Object-RT::Ticket-$id-CustomField:Details-" . $cf->id . "-Values";

        diag "set CVE ID";
        my $val = 'CVE-2021-1234';
        $agent->submit_form_ok( { with_fields => { $field_name => $val } }, 'Change CVE ID' );
        $agent->content_like( qr/$val/, "CVE ID on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        my $values = $ticket->CustomFieldValues( 'CVE ID' );
        my %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        is( scalar values %has, 1, "one CVE ID were added" );
        ok( $has{$val}, "has value" ) or diag "but has values " . join ", ", keys %has;

        diag "set CVE ID with spaces around";
        $val = "  CVE-2021-1234  \n  ";
        $agent->submit_form_ok( { with_fields => { $field_name => $val } }, 'Change CVE ID' );
        $agent->content_like( qr/CVE-2021-1234/, "CVE ID on the page" );

        $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        $values = $ticket->CustomFieldValues( 'CVE ID' );
        %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        is( scalar values %has, 1, "one CVE ID were added" );
        ok( $has{'CVE-2021-1234'}, "has value" ) or diag "but has values " . join ", ", keys %has;
    }
}

diag "check that CVE IDs in messages don't add duplicates";
{
    my $id = $agent->create_ir( { Subject => "test CVE ID", Content => 'CVE-2021-1234 CVE-2021-1234' } );
    ok( $id, "created first ticket" );

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    ok( $ticket->id, 'loaded ticket' );

    my $values = $ticket->CustomFieldValues( 'CVE ID' );
    my %has;
    $has{ $_->Content }++ foreach @{ $values->ItemsArrayRef };
    is( scalar values %has, 1, "one CVE ID were added" );
    ok( !grep( $_ != 1, values %has ), "no duplicated values" );
    ok( $has{'CVE-2021-1234'}, "CVE ID is there" );
}

diag "search tickets by CVE ID";
{
    my $id = $agent->create_ir( { Subject => "test CVE ID", Content => 'CVE-2021-1234' } );
    ok( $id, "created first ticket" );

    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL( "id = $id AND CF.{CVE ID} = 'CVE-2021-1234'" );
    ok( $tickets->Count, "found tickets" );

    my $flag = 1;
    while ( my $ticket = $tickets->Next ) {
        my %has = map { $_->Content => 1 } @{ $ticket->CustomFieldValues( 'CVE ID' )->ItemsArrayRef };
        next if $has{'CVE-2021-1234'};
        $flag = 0;
        ok( 0, "ticket #" . $ticket->id . " has no CVE ID CVE-2021-1234, but should" )
          or diag "but has values " . join ", ", keys %has;
        last;
    }
    ok( 1, "all tickets has CVE ID CVE-2021-1234" ) if $flag;
}

diag "merge ticket, CVE IDs should be merged";
{
    my $incident_id = $agent->create_rtir_ticket_ok( 'Incidents', { Subject => "test" }, );
    my $b1_id = $agent->create_countermeasure(
        { Subject => "test CVE ID", Incident => $incident_id, },
        { 'CVE ID'  => 'CVE-2021-1234' },
    );
    my $b2_id = $agent->create_countermeasure(
        { Subject => "test CVE ID", Incident => $incident_id, },
        { 'CVE ID'  => 'CVE-2021-5678' },
    );

    $agent->display_ticket( $b1_id );
    $agent->follow_link_ok( { text => 'Merge' }, "Followed merge link" );
    $agent->form_number( 3 );
    $agent->field( 'SelectedTicket', $b2_id );
    $agent->submit;
    $agent->ok_and_content_like( qr{Merge Successful}, 'Merge Successful' );

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $b1_id );
    ok $ticket->id, 'loaded ticket';
    my $values = $ticket->CustomFieldValues( 'CVE ID' );
    my %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
    is( scalar values %has, 2, "both CVE IDs are there" );
    ok( $has{'CVE-2021-1234'}, "has value" ) or diag "but has values " . join ", ", keys %has;
    ok( $has{'CVE-2021-5678'},  "has value" ) or diag "but has values " . join ", ", keys %has;
}

diag "merge ticket with the same CVE ID";
{
    my $incident_id = $agent->create_rtir_ticket_ok( 'Incidents', { Subject => "test" }, );
    my $b1_id = $agent->create_countermeasure(
        { Subject => "test CVE ID", Incident => $incident_id, },
        { 'CVE ID'  => 'CVE-2021-12345' },
    );
    my $b2_id = $agent->create_countermeasure(
        { Subject => "test CVE ID", Incident => $incident_id, },
        { 'CVE ID'  => 'CVE-2021-12345' },
    );

    $agent->display_ticket( $b1_id );
    $agent->follow_link_ok( { text => 'Merge' }, "Followed merge link" );
    $agent->form_number( 3 );
    $agent->field( 'SelectedTicket', $b2_id );
    $agent->submit;
    $agent->ok_and_content_like( qr{Merge Successful}, 'Merge Successful' );

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $b1_id );
    ok $ticket->id, 'loaded ticket';
    my $values = $ticket->CustomFieldValues( 'CVE ID' );
    my @has = map $_->Content, @{ $values->ItemsArrayRef };
    is( scalar @has, 1, "only one CVE ID" ) or diag "values: @has";
    is( $has[ 0 ], 'CVE-2021-12345', "has value" );
}

diag "test various invalid CVE IDs";
{
    my @invalid_cves = (
        'cve-2021-',
        'cve-20-3',
        'cve-2021-123',
    );

    for my $cve ( @invalid_cves ) {
        my $id = $agent->create_rtir_ticket_ok( 'Incident Reports', { Subject => "test", Content => $cve }, );
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id,                                 'loaded ticket' );
        ok( !$ticket->FirstCustomFieldValue( 'CVE ID' ), "Inalid CVE ID $cve is not defined" );
    }
}

done_testing;
