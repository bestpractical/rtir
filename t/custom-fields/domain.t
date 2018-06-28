#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

my $cf;
diag "load and check basic properties of the Domain CF";
{
    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => 'Domain', CASESENSITIVE => 0 );
    is( $cfs->Count, 1, "found one CF with name 'Domain'" );

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

diag "create a ticket via web and set Domain";
{
    my $i = 0;
    my $incident_id;    # countermeasure couldn't be created without incident id
    foreach my $queue ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue";

        my $val = ++$i . '.example.com';
        my $id  = $agent->create_rtir_ticket_ok(
            $queue,
            { Subject => "test domain", ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ), },
            { Domain => $val },
        );
        $incident_id = $id if $queue eq 'Incidents';

        $agent->content_like( qr/\Q$val/, "Domain on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue( 'Domain' ), $val, 'correct value' );
    }
}

diag "create a ticket via web with Domain in message";
{
    my $i = 0;
    my $incident_id;    # countermeasure couldn't be created without incident id
    foreach my $queue ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue";

        my $val = ++$i . '.example.com';
        my $id  = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test domain in message",
                ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ), Content => "$val",
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        $agent->content_like( qr/\Q$val/, "Domain on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue( 'Domain' ), $val, 'correct value' );
    }
}

diag "create a ticket and edit Domain field using Edit page";
{
    my $i = 0;
    my $incident_id;    # countermeasure couldn't be created without incident id
    foreach my $queue ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue";

        my $id = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test domain in message",
                ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ),
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        my $field_name = "Object-RT::Ticket-$id-CustomField:Networking-" . $cf->id . "-Values";

        diag "set Domain";
        my $val = 'example.com';
        $agent->follow_link_ok( { text => 'Edit', n => "1" }, "Followed 'Edit' link" );
        $agent->form_number( 3 );
        like( $agent->value( $field_name ), qr/^\s*$/, 'Domain is empty' );
        $agent->field( $field_name => $val );
        $agent->click( 'SaveChanges' );

        $agent->content_like( qr/\Q$val/, "Domain on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        my $values = $ticket->CustomFieldValues( 'Domain' );
        my %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        is( scalar values %has, 1, "one Domain were added" );
        ok( $has{$val}, "has value" ) or diag "but has values " . join ", ", keys %has;

        diag "set Domain with spaces around";
        $val = "  example.net  \n  ";
        $agent->follow_link_ok( { text => 'Edit', n => "1" }, "Followed 'Edit' link" );
        $agent->form_number( 3 );
        like( $agent->value( $field_name ), qr/^\s*\Qexample.com\E\s*$/, 'Domain is in input box' );
        $agent->field( $field_name => $val );
        $agent->click( 'SaveChanges' );

        $agent->content_like( qr/\Qexample.com/, "Domain on the page" );

        $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        $values = $ticket->CustomFieldValues( 'Domain' );
        %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        is( scalar values %has, 1, "one Domain were added" );
        ok( $has{'example.net'}, "has value" ) or diag "but has values " . join ", ", keys %has;
    }
}

diag "check that Domains in messages don't add duplicates";
{
    my $id = $agent->create_ir( { Subject => "test domain", Content => 'example.com example.com' } );
    ok( $id, "created first ticket" );

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    ok( $ticket->id, 'loaded ticket' );

    my $values = $ticket->CustomFieldValues( 'Domain' );
    my %has;
    $has{ $_->Content }++ foreach @{ $values->ItemsArrayRef };
    is( scalar values %has, 1, "one Domain were added" );
    ok( !grep( $_ != 1, values %has ), "no duplicated values" );
    ok( $has{'example.com'}, "Domain is there" );
}

diag "search tickets by Domain";
{
    my $id = $agent->create_ir( { Subject => "test domain", Content => 'search.example.com' } );
    ok( $id, "created first ticket" );

    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL( "id = $id AND CF.{Domain} = 'search.example.com'" );
    ok( $tickets->Count, "found tickets" );

    my $flag = 1;
    while ( my $ticket = $tickets->Next ) {
        my %has = map { $_->Content => 1 } @{ $ticket->CustomFieldValues( 'Domain' )->ItemsArrayRef };
        next if $has{'search.example.com'};
        $flag = 0;
        ok( 0, "ticket #" . $ticket->id . " has no Domain search.example.com, but should" )
          or diag "but has values " . join ", ", keys %has;
        last;
    }
    ok( 1, "all tickets has Domain search.example.com" ) if $flag;
}

diag "merge ticket, Domains should be merged";
{
    my $incident_id = $agent->create_rtir_ticket_ok( 'Incidents', { Subject => "test" }, );
    my $b1_id = $agent->create_countermeasure(
        { Subject => "test domain", Incident => $incident_id, },
        { Domain  => 'example.com' },
    );
    my $b2_id = $agent->create_countermeasure(
        { Subject => "test domain", Incident => $incident_id, },
        { Domain  => 'foobar.net' },
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
    my $values = $ticket->CustomFieldValues( 'Domain' );
    my %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
    is( scalar values %has, 2, "both Domains are there" );
    ok( $has{'example.com'}, "has value" ) or diag "but has values " . join ", ", keys %has;
    ok( $has{'foobar.net'},  "has value" ) or diag "but has values " . join ", ", keys %has;
}

diag "merge ticket with the same Domain";
{
    my $incident_id = $agent->create_rtir_ticket_ok( 'Incidents', { Subject => "test" }, );
    my $b1_id = $agent->create_countermeasure(
        { Subject => "test domain", Incident => $incident_id, },
        { Domain  => 'example.com' },
    );
    my $b2_id = $agent->create_countermeasure(
        { Subject => "test domain", Incident => $incident_id, },
        { Domain  => 'example.com' },
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
    my $values = $ticket->CustomFieldValues( 'Domain' );
    my @has = map $_->Content, @{ $values->ItemsArrayRef };
    is( scalar @has, 1, "only one Domain" ) or diag "values: @has";
    is( $has[ 0 ], 'example.com', "has value" );
}

diag "test various valid domains";
{
    my @valid_domains = (
        'example.com', 'foo.example.net', 'bar.example.org',    # classical tld
        'test.example', 'test.us', 'test.cc', 'test.edu',       # newer tld
        'foo-bar.com',                                          # dash
        'foo-bar-baz.com',                                      # multiple dashes
        'xn--0zwm56d.com',                                      # international domain with punycode
        't' x 63 . '.com',                                      # part with 63 chars
        't.' x 125 . 'com',                                     # 253 chars
    );

    for my $domain ( @valid_domains ) {
        my $id = $agent->create_rtir_ticket_ok( 'Incident Reports', { Subject => "test", Content => $domain }, );
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue( 'Domain' ), $domain, "Domain $domain is extracted" );
    }
}

diag "test various invalid domains";
{
    my @invalid_domains = (
        'test.bla',            # invalid tld
        '.com',                # top domain only
        '-.com',               # part starts with a dash
        't' x 64 . '.com',     # part exceeds 63 chars
        't.' x 126 . 'com',    # exceeds 253 chars
    );

    for my $domain ( @invalid_domains ) {
        my $id = $agent->create_rtir_ticket_ok( 'Incident Reports', { Subject => "test", Content => $domain }, );
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id,                                 'loaded ticket' );
        ok( !$ticket->FirstCustomFieldValue( 'Domain' ), "Inalid domain $domain is not defined" );
    }
}

done_testing;
