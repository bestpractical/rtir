#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

my $inc_id   = $agent->create_incident( {Subject => "incident with countermeasure"});
my $countermeasure_id = $agent->create_countermeasure( {Subject => "countermeasure", Incident => $inc_id});

$agent->ticket_status_is( $countermeasure_id, 'pending activation');

$agent->has_tag('a', 'Remove', 'we have Remove action');
$agent->has_tag('a', 'Quick Remove', 'we have Quick Remove action');

diag "change status using inline edit";
foreach my $status( 'pending activation', 'active', 'pending removal', 'removed' ) {
    $agent->submit_form_ok( { with_fields => { Status => $status } }, "Change status to $status" );
    $agent->ticket_status_is( $countermeasure_id, $status);
}

# Tests to make sure the unwanted option 'Use system default()' does not appear as an
# option in the Status field (a reported M3 bug)
$agent->content_unlike(qr{<option (?:value=.*)?>Use system default\(\)</option>}, "The option 'Use system default()' does not exist.");

diag "reactivate the countermeasure using the link";
{
    $agent->has_tag('a', 'Activate', 'we have Activate action');
    $agent->follow_link_ok({ text => 'Activate' }, "Reactivate countermeasure");

    $agent->form_number(3);
    $agent->field( UpdateContent => 'activating countermeasure' );
    $agent->click('SubmitTicket');
    $agent->ticket_status_is( $countermeasure_id, 'active');
}

diag "prepare for removing using the link";
{
    $agent->has_tag('a', 'Pending Removal', 'we have Pending Removal action tab');
    $agent->follow_link_ok({ text => 'Pending Removal' }, "Prepare countermeasure for remove");
    $agent->form_number(3);
    $agent->click('SubmitTicket');
    $agent->ticket_status_is( $countermeasure_id, 'pending removal');
}

diag "test activation after reply using 'Activate' link";
{
    my $countermeasure_id = $agent->create_countermeasure( {Subject => "countermeasure", Incident => $inc_id});
    $agent->ticket_status_is( $countermeasure_id, 'pending activation');

    $agent->follow_link_ok({ text => 'Reply' }, "Go to reply page");
    $agent->form_number(3);
    $agent->field( UpdateContent => 'reply' );
    $agent->click('SubmitTicket');

    $agent->ticket_status_is( $countermeasure_id, 'pending activation');

    $agent->follow_link_ok({ text => 'Activate' }, "activate it");

    $agent->form_number(3);
    $agent->field( UpdateContent => 'activating countermeasure' );
    $agent->click('SubmitTicket');

    $agent->ticket_status_is( $countermeasure_id, 'active');
}

diag "test activation after reply using inline edit";
{
    my $countermeasure_id = $agent->create_countermeasure( {Subject => "countermeasure", Incident => $inc_id});
    $agent->ticket_status_is( $countermeasure_id, 'pending activation');

    $agent->follow_link_ok({ text => 'Reply' }, "Go to reply page");
    $agent->form_number(3);
    $agent->field( UpdateContent => 'reply' );
    $agent->click('SubmitTicket');

    $agent->ticket_status_is( $countermeasure_id, 'pending activation');

    $agent->submit_form_ok({ with_fields => { Status => 'active' } }, "Change status to active");
    $agent->ticket_status_is( $countermeasure_id, 'active');
}


done_testing;
