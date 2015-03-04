#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT->Config->Set('RTIR_BlockAproveActionRegexp', undef);

RT::Test->started_ok;
my $agent = default_agent();

my $inc_id   = $agent->create_incident( {Subject => "incident with block"});
my $rtname = RT->Config->Get('rtname');
my $block_id = $agent->create_block( {
    Subject => "block",
    Incident => $inc_id,
    Requestors => 'rt-test@example.com',
} );
$agent->ticket_status_is( $block_id, 'pending activation');

{
    my $text = <<EOF;
From: rt-test\@example.com
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: [$rtname #$block_id] This is a test

test
EOF
    my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Blocks');
    is $status >> 8, 0, "The mail gateway exited ok";
    is $id, $block_id, "replied to the ticket";
    $agent->ticket_status_is( $block_id, 'active');
}

{
    $agent->display_ticket( $block_id);
    $agent->follow_link_ok({ text => 'Pending Removal' }, "-> pending removal");
    $agent->form_number(3);
    $agent->field( UpdateContent => 'going to remove' );
    $agent->click('SubmitTicket');
    $agent->ticket_status_is( $block_id, 'pending removal');
}

{
    my $text = <<EOF;
From: rt-test\@example.com
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: [$rtname #$block_id] This is a test

some text
EOF
    my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Blocks');
    is $status >> 8, 0, "The mail gateway exited ok";
    is $id, $block_id, "replied to the ticket";
    $agent->ticket_status_is( $block_id, 'removed');
}

done_testing;
