#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

use_ok('RT::IR');

my %valid = (
    'abcd:' x 7 . 'abcd' => 'abcd:' x 7 . 'abcd',
    '034:' x 7 . '034'   => '0034:' x 7 . '0034',
    'abcd::'             => 'abcd:' . '0000:' x 6 . '0000',
    '::abcd'             => '0000:' x 7 . 'abcd',
    'abcd::034'          => 'abcd:' . '0000:' x 6 . '0034',
    'abcd::192.168.1.1'  => 'abcd:' . '0000:' x 5 . 'c0a8:0101',
    '::192.168.1.1'      => '0000:' x 6 . 'c0a8:0101',
);

my %test_set = (
    'abcd:' x 7 . 'abcd' => 'abcd:' x 7 . 'abcd',
    'abcd::034'          => 'abcd:' . '0000:' x 6 . '0034',
    '::192.168.1.1'      => '0000:' x 6 . 'c0a8:0101',

    # A trailing dot is allowed since it's commonly used as end of sentence,
    'abcd::034.'         => 'abcd::34',
    'abcd::192.168.1.1.' => 'abcd::c0a8:101',
);
my %test_cidr = (
    'abcd:' x 7 . 'abcd/32' => 'abcd:abcd'. ':0000' x 6 .'-'. 'abcd:abcd'. ':ffff' x 6,
    '::192.168.1.1/120'     => '0000:' x 6 . 'c0a8:0100' .'-'. '0000:' x 6 . 'c0a8:01ff',
);

my %abbrev_of = (
    'abcd:' x 7 . 'abcd' => 'abcd:' x 7 . 'abcd',
    '034:' x 7 . '034'   => '34:' x 7 . '34',
    'abcd::'             => 'abcd::',
    '::abcd'             => '::abcd',
    'abcd::034'          => 'abcd::34',
    'abcd::192.168.1.1'  => 'abcd::c0a8:101',
    '::192.168.1.1'      => '::c0a8:101',

    'abcd:' x 7 . 'abcd/32' => 'abcd:abcd::-abcd:abcd' . ':ffff' x 6,
    '::192.168.1.1/120' => '::c0a8:100-::c0a8:1ff',

    '0000:'x6 .'ac10:0001' => '::ac10:1',
    '0000:'x6 .'ac10:0002' => '::ac10:2',

    'abcd::034.'         => 'abcd::34',
    'abcd::192.168.1.1.' => 'abcd::c0a8:101',
);

my $cf;
diag "load and check basic properties of the IP CF" if $ENV{'TEST_VERBOSE'};
{
    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => 'IP', CASESENSITIVE => 0 );
    is( $cfs->Count, 1, "found one CF with name 'IP'" );

    $cf = $cfs->First;
    is( $cf->Type, 'IPAddressRange', 'type check' );
    is( $cf->LookupType, 'RT::Queue-RT::Ticket', 'lookup type check' );
    ok( !$cf->MaxValues, "unlimited number of values" );
    ok( !$cf->Disabled, "not disabled" );
}

diag "check that CF applies to all RTIR's queues" if $ENV{'TEST_VERBOSE'};
{
    foreach ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        my $queue = RT::Queue->new( $RT::SystemUser );
        $queue->Load( $_ );
        ok( $queue->id, 'loaded queue '. $_ );
        my $cfs = $queue->TicketCustomFields;
        $cfs->Limit( FIELD => 'id', VALUE => $cf->id, ENTRYAGGREGATOR => 'AND' );
        is( $cfs->Count, 1, 'field applies to queue' );
    }
}
my $rtir_user = RT::CurrentUser->new( rtir_user() );

diag "create a ticket via web and set IP" if $ENV{'TEST_VERBOSE'};
for my $short (sort keys %valid) {
    my $full = $valid{$short};
    my $abbrev = $abbrev_of{$short};
    my $incident_id; # countermeasure couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $id = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test ip",
                ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ),
            },
            { IP => $short },
        );
        $incident_id = $id if $queue eq 'Incidents';

        $agent->content_like( qr/\Q$abbrev/, "IP on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue('IP'), $abbrev, 'correct value' );
    }
}

diag "create a ticket via web with IP in message" if $ENV{'TEST_VERBOSE'};
for my $short (sort keys %test_set) {
    my $full = $valid{$short};
    my $abbrev = $abbrev_of{$short};
    my $incident_id; # countermeasure couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $id = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test ip in message",
                ($queue eq 'Countermeasures'? (Incident => $incident_id): ()),
                Content => "$short",
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        $agent->content_like( qr/\Q$abbrev/, "IP on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue('IP'), $abbrev, 'correct value' );
    }
}

diag "create a ticket via web with CIDR" if $ENV{'TEST_VERBOSE'};
for my $short (sort keys %test_cidr) {
    my $full = $test_cidr{$short};
    my $abbrev = $abbrev_of{$short};
    my $incident_id; # countermeasure couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $id = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test ip",
                ($queue eq 'Countermeasures'? (Incident => $incident_id): ()),
            },
            { IP => $short },
        );
        $incident_id = $id if $queue eq 'Incidents';

        $agent->content_like( qr/\Q$abbrev/, "IP range on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        my $values = $ticket->CustomFieldValues('IP');
        my %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        ok( $has{ $abbrev }, "has value $abbrev" )
            or diag "but has values ". join ", ", keys %has;
    }
}

diag "create a ticket via web with CIDR in message" if $ENV{'TEST_VERBOSE'};
for my $short (sort keys %test_cidr) {
    my $full = $test_cidr{$short};
    my $abbrev = $abbrev_of{$short};

    my $incident_id; # countermeasure couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $id = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test ip in message",
                ($queue eq 'Countermeasures'? (Incident => $incident_id): ()),
                Content => "$short",
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        $agent->content_like( qr/\Q$abbrev/, "IP range on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        my $values = $ticket->CustomFieldValues('IP');
        my %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        ok( $has{ $abbrev }, "has value $abbrev" )
            or diag "but has values ". join ", ", keys %has;
    }
}

diag "create a ticket and edit IP field using Edit page" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;
    my $incident_id; # countermeasure couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $id = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test ip in message",
                ($queue eq 'Countermeasures'? (Incident => $incident_id): ()),
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        my $field_name = "Object-RT::Ticket-$id-CustomField:Networking-". $cf->id ."-Values";

diag "set IP" if $ENV{'TEST_VERBOSE'};
        my $val = 'abcd::192.168.1.1';
        $agent->submit_form_ok( { with_fields => { $field_name => $val } }, "Change IP to $val" );
        $agent->content_like( qr/\Q$abbrev_of{$val}/, "IP on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        my $values = $ticket->CustomFieldValues('IP');
        my %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        is( scalar values %has, 1, "one IP were added");
        ok( $has{ $abbrev_of{ $val } }, "has value $abbrev_of{$val}" )
            or diag "but has values ". join ", ", keys %has;

diag "set IP with spaces around" if $ENV{'TEST_VERBOSE'};
        $val = "  ::192.168.1.1  \n  ";
        $agent->submit_form_ok( { with_fields => { $field_name => $val } }, "Change IP to $val" );
        $agent->content_like( qr/\Q$abbrev_of{'::192.168.1.1'}/, "IP on the page" );

        $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        $values = $ticket->CustomFieldValues('IP');
        %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        is( scalar values %has, 1, "one IP were added");
        ok( $has{ $abbrev_of{'::192.168.1.1'} }, "has value ::192.168.1.1" )
            or diag "but has values ". join ", ", keys %has;

diag "replace IP with a range" if $ENV{'TEST_VERBOSE'};
        $val = '::192.168.1.1/120';
        $agent->submit_form_ok( { with_fields => { $field_name => $val } }, "Change IP to $val" );
        $agent->content_like( qr/\Q$abbrev_of{ $val }/, "IP on the page" );

        $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        $values = $ticket->CustomFieldValues('IP');
        %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
        is( scalar values %has, 1, "one IP were added");
        ok( $has{ $abbrev_of{ $val } }, "has value $abbrev_of{$val}" )
            or diag "but has values ". join ", ", keys %has;
    }
}

#diag "check that we parse correct IPs only" if $ENV{'TEST_VERBOSE'};
# XXX: waiting for regressions

diag "check that IPs in messages don't add duplicates" if $ENV{'TEST_VERBOSE'};
{
    my $id = $agent->create_ir( {
        Subject => "test ip",
        Content => 'abcd::192.168.1.1 abcd::192.168.1.1 abcd::192.168.1.1/128'
    } );
    ok($id, "created first ticket");

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    ok( $ticket->id, 'loaded ticket' );

    my $values = $ticket->CustomFieldValues('IP');
    my %has;
    $has{ $_->Content }++ foreach @{ $values->ItemsArrayRef };
    is(scalar values %has, 1, "one IP were added");
    ok(!grep( $_ != 1, values %has ), "no duplicated values")
        or diag "duplicates: ". join ',', grep $has{$_}>1, keys %has;
    ok($has{ $abbrev_of{ 'abcd::192.168.1.1' } }, "abcd::192.168.1.1 is there")
            or diag "but has values ". join ", ", keys %has;
}

diag "search tickets by IP" if $ENV{'TEST_VERBOSE'};
{
    my $id = $agent->create_ir( {
        Subject => "test ip",
        Content => '::192.168.1.1/120',
    } );
    ok($id, "created first ticket");

    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("id = $id AND CF.{IP} = '::192.168.1.1'");
    ok( $tickets->Count, "found tickets" );

    my $flag = 1;
    while ( my $ticket = $tickets->Next ) {
        my %has = map { $_->Content => 1 } @{ $ticket->CustomFieldValues('IP')->ItemsArrayRef };
        next if $has{ $abbrev_of{'::192.168.1.1/120'} };
        $flag = 0;
        ok(0, "ticket #". $ticket->id ." has no range ::192.168.1.1/120, but should")
            or diag "but has values ". join ", ", keys %has;
        last;
    }
    ok(1, "all tickets has IP ::192.168.1.1/120") if $flag;
}

diag "search tickets by IP range" if $ENV{'TEST_VERBOSE'};
{
    my $id = $agent->create_ir( {
        Subject => "test ip",
        Content => '::c0a8:01a0'
    } );
    ok($id, "created first ticket");

    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("id = $id AND CF.{IP} = '::c0a8:0101-::c0a8:01ff'");
    ok( $tickets->Count, "found tickets" );

    my $flag = 1;
    while ( my $ticket = $tickets->Next ) {
        my %has = map { $_->Content => 1 } @{ $ticket->CustomFieldValues('IP')->ItemsArrayRef };
        next if $has{'::c0a8:1a0'};
        $flag = 0;
        diag 'has IPs: ' . join ', ', sort keys %has;
        ok(0, "ticket #". $ticket->id ." has no IP from '::c0a8::-::c0a8:01ff', but should");
        last;
    }
    ok(1, "all tickets have at least one IP from the range") if $flag;
}

diag "create two tickets with different IPs and check several searches" if $ENV{'TEST_VERBOSE'};
{
    my $id1 = $agent->create_ir( { Subject => "test ip" }, { IP => '::c0a8:3310' } );
    ok($id1, "created first ticket");
    my $id2 = $agent->create_ir( { Subject => "test ip" }, { IP => '::c0a8:aa10' } );
    ok($id2, "created second ticket");

    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("id = $id1 OR id = $id2");
    is( $tickets->Count, 2, "found both tickets by 'id = x OR y'" );

    # IP
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:3310'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:aa10'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );

    # IP/32 - one address
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:3310/128'");
    is( $tickets->Count, 1, "found one ticket" ) or diag $tickets->BuildSelectQuery;
    is( $tickets->First->id, $id1, "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:aa10/128'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );

    # IP range
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:3300-::c0a8:33ff'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:aa00-::c0a8:aaff'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );

    # IP range, with start IP greater than end
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:33ff-::c0a8:3300'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:aaff-::c0a8:aa00'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );

    # CIDR/120
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:3300/120'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:aa00/120'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );

    # IP is not in CIDR/120
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} != '::c0a8:3300/120'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} != '::c0a8:aa00/120'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );

    # CIDR or CIDR
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND "
        ."(CF.{IP} = '::c0a8:3300/120' OR CF.{IP} = '::c0a8:aa00/120')");
    is( $tickets->Count, 2, "found both tickets" );

    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::c0a8:0000/0'");
    is( $tickets->Count, 2, "found both tickets" ) or diag $tickets->BuildSelectQuery;
}

diag "create two tickets with different IP ranges and check several searches" if $ENV{'TEST_VERBOSE'};
{
    my $id1 = $agent->create_ir( { Subject => "test ip" }, { IP => '::192.168.21.0-::192.168.21.127' } );
    ok($id1, "created first ticket");
    my $id2 = $agent->create_ir( { Subject => "test ip" }, { IP => '::192.168.21.128-::192.168.21.255' } );
    ok($id2, "created second ticket");

    my $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("id = $id1 OR id = $id2");
    is( $tickets->Count, 2, "found both tickets by 'id = x OR y'" );

    # IP
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.0'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.64'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.127'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.128'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.191'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.255'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );

    # IP/32 - one address
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.63/128'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.191/128'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id2, "correct value" );

    # IP range, lower than both
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.20.0-::192.168.20.255'");
    is( $tickets->Count, 0, "didn't finnd ticket" ) or diag "but found ". $tickets->First->id;

    # IP range, intersect with the first range
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.20.0-::192.168.21.63'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );

    # IP range, equal to the first range
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.0-::192.168.21.127'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );

    # IP range, lay inside the first range
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.31-::192.168.21.63'");
    is( $tickets->Count, 1, "found one ticket" );
    is( $tickets->First->id, $id1, "correct value" );

    # IP range, intersect with the ranges
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.31-::192.168.21.191'");
    is( $tickets->Count, 2, "found both tickets" );

    # IP range, equal to range from the starting IP of the first ticket to the ending IP of the second
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.21.0-::192.168.21.255'");
    is( $tickets->Count, 2, "found both tickets" );

    # IP range, has the both ranges inside it
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.0.0/112'");
    is( $tickets->Count, 2, "found both tickets" );

    # IP range, greater than both
    $tickets = RT::Tickets->new( $rtir_user );
    $tickets->FromSQL("(id = $id1 OR id = $id2) AND CF.{IP} = '::192.168.22.0/120'");
    is( $tickets->Count, 0, "didn't finnd ticket" ) or diag "but found ". $tickets->First->id;
}

diag "merge ticket, IPs should be merged";
{
    my $incident_id = $agent->create_rtir_ticket_ok(
        'Incidents',
        { Subject => "test" },
    );
    my $b1_id = $agent->create_countermeasure(
        {
            Subject => "test ip",
            Incident => $incident_id,
        },
        { IP => '::172.16.0.1' },
    );
    my $b2_id = $agent->create_countermeasure(
        {
            Subject => "test ip",
            Incident => $incident_id,
        },
        { IP => '::172.16.0.2' },
    );

    $agent->display_ticket( $b1_id);
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");
    $agent->form_number(3);
    $agent->field('SelectedTicket', $b2_id);
    $agent->submit;
    $agent->ok_and_content_like( qr{Merge Successful}, 'Merge Successful');

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $b1_id );
    ok $ticket->id, 'loaded ticket';
    my $values = $ticket->CustomFieldValues('IP');
    my %has = map { $_->Content => 1 } @{ $values->ItemsArrayRef };
    is( scalar values %has, 2, "both IPs are there");
    ok( $abbrev_of{ '0000:'x6 .'ac10:0001' }, "has value" )
        or diag "but has values ". join ", ", keys %has;
    ok( $abbrev_of{ '0000:'x6 .'ac10:0002' }, "has value" )
        or diag "but has values ". join ", ", keys %has;
}

diag "merge ticket with the same IP";
{
    my $incident_id = $agent->create_rtir_ticket_ok(
        'Incidents',
        { Subject => "test" },
    );
    my $b1_id = $agent->create_countermeasure(
        {
            Subject => "test ip",
            Incident => $incident_id,
        },
        { IP => '::172.16.0.1' },
    );
    my $b2_id = $agent->create_countermeasure(
        {
            Subject => "test ip",
            Incident => $incident_id,
        },
        { IP => '::172.16.0.1' },
    );

    $agent->display_ticket( $b1_id);
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");
    $agent->form_number(3);
    $agent->field('SelectedTicket', $b2_id);
    $agent->submit;
    $agent->ok_and_content_like( qr{Merge Successful}, 'Merge Successful');

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $b1_id );
    ok $ticket->id, 'loaded ticket';
    my $values = $ticket->CustomFieldValues('IP');
    my @has = map $_->Content, @{ $values->ItemsArrayRef };
    is( scalar @has, 1, "only one IP") or diag "values: @has";
    is( $has[0], '::ac10:1', "has value" );
}

diag "create a ticket via web with invalid IPv6 addresses" if $ENV{'TEST_VERBOSE'};

my @invalid = (
    'Scan::Address_Scan', 'scan::add', 'z::a',  'a::z',
    '::z',                'Foo::Bar',  'Foo::', '::Bar',
    'RT::',               'RT::IR',

    # A trailing dot is allowed but not if there are words right after it
    'abcd::34.3', 'abcd::192.168.1.2.3', '::add.z',

    # ensure all zero addresses do not get added as IPs
    '::',    '0000:0000:0000:0000:0000:0000:0000:0000',
    '::/0',  '0000:0000:0000:0000:0000:0000:0000:0000/0',
    '::/64', '0000:0000:0000:0000:0000:0000:0000:0000/64',
    'abcd:0000:0000:0000:0000:0000:0000:0000/0',
);


for my $content ( @invalid ) {

    my $incident_id;
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $id = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test invalid IPv6 in message",
                ($queue eq 'Countermeasures'? (Incident => $incident_id): ()),
                Content => "$content",
            },
        );
        $incident_id = $id if $queue eq 'Incidents';

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue('IP'), undef, 'correct value' );
    }
}
done_testing();
