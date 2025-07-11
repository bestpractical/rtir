#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT->Config->Set('RTIR_CountermeasureApproveActionRegexp', qr/TestPendingCountermeasure/);

RT::Test->started_ok;
my $agent = default_agent();

my $rtname = RT->Config->Get('rtname');

my $inc_id   = $agent->create_incident( {Subject => "incident with countermeasure"});
my $countermeasure_id = $agent->create_countermeasure( {
    Subject => "countermeasure",
    Incident => $inc_id,
    Requestors => 'rt-test@example.com',
} );
$agent->ticket_status_is( $countermeasure_id, 'pending activation');

{
    my $text = <<EOF;
From: rt-test\@example.com
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: [$rtname #$countermeasure_id] This is a test

some text
EOF
    my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Countermeasures');
    is $status >> 8, 0, "The mail gateway exited ok";
    is $id, $countermeasure_id, "replied to the ticket";
    $agent->ticket_status_is( $countermeasure_id, 'pending activation');
}

{
    my $text = <<EOF;
From: rt-test\@example.com
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: [$rtname #$countermeasure_id] This is a test

TestPendingCountermeasure

EOF
    my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Countermeasures');
    is $status >> 8, 0, "The mail gateway exited ok";
    is $id, $countermeasure_id, "replied to the ticket";
    $agent->ticket_status_is( $countermeasure_id, 'active');
}

{
    $agent->display_ticket( $countermeasure_id);
    $agent->follow_link_ok({ text => 'Pending Removal' }, "-> pending removal");
    $agent->form_number(3);
    $agent->field( UpdateContent => 'going to remove' );
    $agent->click('SubmitTicket');
    $agent->ticket_status_is( $countermeasure_id, 'pending removal');
}

{
    my $text = <<EOF;
From: rt-test\@example.com
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: [$rtname #$countermeasure_id] This is a test

some text
EOF
    my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Countermeasures');
    is $status >> 8, 0, "The mail gateway exited ok";
    is $id, $countermeasure_id, "replied to the ticket";
    $agent->ticket_status_is( $countermeasure_id, 'pending removal');
}

{
    my $text = <<EOF;
From: rt-test\@example.com
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: [$rtname #$countermeasure_id] This is a test

TestPendingCountermeasure

EOF
    my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Countermeasures');
    is $status >> 8, 0, "The mail gateway exited ok";
    is $id, $countermeasure_id, "replied to the ticket";
    $agent->ticket_status_is( $countermeasure_id, 'removed');
}

done_testing;
