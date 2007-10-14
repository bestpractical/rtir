#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 62;

require "t/rtir-test.pl";

my $agent = default_agent();

my $inc_id   = create_incident($agent, {Subject => "incident with block"});
my $block_id = create_block($agent, {Subject => "block", Incident => $inc_id});

ticket_state_is($agent, $block_id, 'pending activation');

# XXX: Comment this tests as we don't allow to create blocks without an incident
# XXX: we need test for this fact
#$agent->follow_link_ok({ text => "[Link]" }, "Followed '[Link]' link");
#$agent->form_number(3);
#$agent->field('SelectedTicket', $inc_id);
#$agent->click('LinkChild');
#ok_and_content_like($agent, qr{$block_id.*block.*?pending activation}, 'have child link');
#
#$agent->follow_link_ok({ text => $block_id }, "Followed link back to block");
#ticket_state_is($agent, $block_id, 'pending activation');

$agent->has_tag('a', 'Remove', 'we have Remove action');
$agent->has_tag('a', 'Quick Remove', 'we have Quick Remove action');

my %state = (
    new      => 'pending activation',
    open     => 'active',
    stalled  => 'pending removal',
    resolved => 'removed',
    rejected => 'removed',
);

foreach my $status( qw(open stalled resolved) ) {
    $agent->follow_link_ok({ text => "Edit" }, "Goto edit page");
    $agent->form_number(3);
    $agent->field(Status => $status);
    $agent->click('SaveChanges');
    my $state = $state{ $status };
    ticket_state_is($agent, $block_id, $state);
}


$agent->follow_link_ok({ text => "Edit" }, "Goto edit page");

# Tests to make sure the unwanted option 'Use system default()' does not appear as an
# option in the State field (a reported M3 bug)
$agent->content_unlike(qr{<option (?:value=.*)?>Use system default\(\)</option>}, "The option 'Use system default()' does not exist.");

$agent->form_number(3);

$agent->field(Status => 'resolved');
$agent->click('SaveChanges');
ticket_state_is($agent, $block_id, 'removed');
$agent->has_tag('a', 'Activate', 'we have Activate action');

$agent->follow_link_ok({ text => 'Activate' }, "Reactivate block");
ticket_state_is($agent, $block_id, 'active');
$agent->has_tag('a', 'Pending Removal', 'we have Pending Removal action tab');

$agent->follow_link_ok({ text => 'Pending Removal' }, "Prepare block for remove");
$agent->form_number(3);
$agent->click('SubmitTicket');
ticket_state_is($agent, $block_id, 'pending removal');

diag "test activation after reply using 'Activate' link";
{
    my $block_id = create_block($agent, {Subject => "block", Incident => $inc_id});
    ticket_state_is($agent, $block_id, 'pending activation');

    $agent->follow_link_ok({ text => 'Reply' }, "Go to reply page");
    $agent->form_number(3);
    $agent->field( UpdateContent => 'reply' );
    $agent->click('SubmitTicket');

    ticket_state_is($agent, $block_id, 'pending activation');

    $agent->follow_link_ok({ text => 'Activate' }, "activate it");

    ticket_state_is($agent, $block_id, 'active');
}

diag "test activation after reply using Edit page";
{
    my $block_id = create_block($agent, {Subject => "block", Incident => $inc_id});
    ticket_state_is($agent, $block_id, 'pending activation');

    $agent->follow_link_ok({ text => 'Reply' }, "Go to reply page");
    $agent->form_number(3);
    $agent->field( UpdateContent => 'reply' );
    $agent->click('SubmitTicket');

    ticket_state_is($agent, $block_id, 'pending activation');

    $agent->follow_link_ok({ text => "Edit" }, "Goto edit page");
    $agent->form_number(3);
    $agent->field(Status => 'open');
    $agent->click('SaveChanges');

    ticket_state_is($agent, $block_id, 'active');
}

