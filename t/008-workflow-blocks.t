#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 118;

RT::Test->started_ok;
my $agent = default_agent();

my $inc_id   = $agent->create_incident( {Subject => "incident with block"});
my $block_id = $agent->create_block( {Subject => "block", Incident => $inc_id});

$agent->ticket_status_is( $block_id, 'pending activation');

# XXX: Comment this tests as we don't allow to create blocks without an incident
# XXX: we need test for this fact
#$agent->follow_link_ok({ text => "[Link]" }, "Followed '[Link]' link");
#$agent->form_number(3);
#$agent->field('SelectedTicket', $inc_id);
#$agent->click('LinkChild');
#$agent->ok_and_content_like( qr{$block_id.*block.*?pending activation}, 'have child link');
#
#$agent->follow_link_ok({ text => $block_id }, "Followed link back to block");
#$agent->ticket_status_is( $block_id, 'pending activation');

$agent->has_tag('a', 'Remove', 'we have Remove action');
$agent->has_tag('a', 'Quick Remove', 'we have Quick Remove action');

foreach my $status( 'pending activation', 'active', 'pending removal', 'removed' ) {
    $agent->follow_link_ok({ text => "Edit" }, "Goto edit page");
    $agent->form_number(3);
    $agent->field(Status => $status);
    $agent->click('SaveChanges');
    $agent->ticket_status_is( $block_id, $status);
}

diag "remove using edit";
{
    $agent->follow_link_ok({ text => "Edit" }, "Goto edit page");

    # Tests to make sure the unwanted option 'Use system default()' does not appear as an
    # option in the Status field (a reported M3 bug)
    $agent->content_unlike(qr{<option (?:value=.*)?>Use system default\(\)</option>}, "The option 'Use system default()' does not exist.");

    $agent->form_number(3);

    $agent->field(Status => 'removed');
    $agent->click('SaveChanges');
    $agent->ticket_status_is( $block_id, 'removed');
}

diag "reactivate the block using the link";
{
    $agent->has_tag('a', 'Activate', 'we have Activate action');
    $agent->follow_link_ok({ text => 'Activate' }, "Reactivate block");

    $agent->form_number(3);
    $agent->field( UpdateContent => 'activating block' );
    $agent->click('SubmitTicket');
    $agent->ticket_status_is( $block_id, 'active');
}

diag "prepare for removing using the link";
{
    $agent->has_tag('a', 'Pending Removal', 'we have Pending Removal action tab');
    $agent->follow_link_ok({ text => 'Pending Removal' }, "Prepare block for remove");
    $agent->form_number(3);
    $agent->click('SubmitTicket');
    $agent->ticket_status_is( $block_id, 'pending removal');
}

diag "test activation after reply using 'Activate' link";
{
    my $block_id = $agent->create_block( {Subject => "block", Incident => $inc_id});
    $agent->ticket_status_is( $block_id, 'pending activation');

    $agent->follow_link_ok({ text => 'Reply' }, "Go to reply page");
    $agent->form_number(3);
    $agent->field( UpdateContent => 'reply' );
    $agent->click('SubmitTicket');

    $agent->ticket_status_is( $block_id, 'pending activation');

    $agent->follow_link_ok({ text => 'Activate' }, "activate it");

    $agent->form_number(3);
    $agent->field( UpdateContent => 'activating block' );
    $agent->click('SubmitTicket');

    $agent->ticket_status_is( $block_id, 'active');
}

diag "test activation after reply using Edit page";
{
    my $block_id = $agent->create_block( {Subject => "block", Incident => $inc_id});
    $agent->ticket_status_is( $block_id, 'pending activation');

    $agent->follow_link_ok({ text => 'Reply' }, "Go to reply page");
    $agent->form_number(3);
    $agent->field( UpdateContent => 'reply' );
    $agent->click('SubmitTicket');

    $agent->ticket_status_is( $block_id, 'pending activation');

    $agent->follow_link_ok({ text => "Edit" }, "Goto edit page");
    $agent->form_number(3);
    $agent->field(Status => 'active');
    $agent->click('SaveChanges');

    $agent->ticket_status_is( $block_id, 'active');
}

my $re = RT->Config->Get('RTIR_BlockAproveActionRegexp');

SKIP: {
    skip "RTIR_BlockAproveActionRegexp is defined", 19 if $re;

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
}

SKIP: {
    skip "'TestPendingBlock' doesn't match RTIR_BlockAproveActionRegexp", 27
        unless $re && 'TestPendingBlock' =~ /$re/;
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

some text
EOF
        my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Blocks');
        is $status >> 8, 0, "The mail gateway exited ok";
        is $id, $block_id, "replied to the ticket";
        $agent->ticket_status_is( $block_id, 'pending activation');
    }

    {
        my $text = <<EOF;
From: rt-test\@example.com
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: [$rtname #$block_id] This is a test

TestPendingBlock

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
        $agent->ticket_status_is( $block_id, 'pending removal');
    }

    {
        my $text = <<EOF;
From: rt-test\@example.com
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: [$rtname #$block_id] This is a test

TestPendingBlock

EOF
        my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Blocks');
        is $status >> 8, 0, "The mail gateway exited ok";
        is $id, $block_id, "replied to the ticket";
        $agent->ticket_status_is( $block_id, 'removed');
    }
}

