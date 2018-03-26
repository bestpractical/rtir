#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;
use Test::Warn;

RT::Test->started_ok;
my $agent = default_agent();

# Tests the creation of inventory-and-investigation from an IR

my $ir = $agent->create_ir( {Subject => 'IR for testing creation of a linked Investigation with no correspondents'});
$agent->display_ticket( $ir);


# The following is adapted from create_incident_and_investigation() in t/rtir-test.pl. The reason
# that function is not used here is that we want to check that the creation failed in the case
# of an empty correspondents field, while the above function tests if the creation succeeded,
# and thus will fail if we get the result we want, and succeed if we don't!
{
    $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");
    $agent->form_number(3);
    $agent->field('Subject', 'Incident for testing empty Investigation correspondent');
    $agent->field('InvestigationSubject', 'Investigation for testing empty Investigation correspondent');
    $agent->click("CreateWithInvestigation");

    is ($agent->status, 200, "Attempting to create new incident and investigation linked to child $ir");

    $agent->content_like(qr{<ul class="action-results">\s*<li>You must enter a correspondent for the investigation</li>\s*</ul>}, "RT did not allow an empty correspondent field");
}


# Okay, enough funny business. Now for some straightforward tests, how it should work
{
    my ($inc_id, $inv_id) = $agent->create_incident_and_investigation( 
        {Subject => 'Incident for testing Incident-and-investigation-from-IR creation',
        InvestigationSubject => 'Investigation for testing Incident-and-Investigation-from-IR creation', 
        InvestigationRequestors => 'foo@example.com'}, {Classification => 'Spam', IP => '172.16.0.1'},
        $ir
    );
    # regression test
    $agent->content_unlike(qr{<li>Custom field (\d+) does not apply to this object</li>}, "Custom field allowed");
    for ( 1 .. 4 ) {
        $agent->next_warning_like( qr/Invalid context object RT::Queue \(5\) for CF \d+; skipping CF/,
            "Investigations queue doesn't have incidents' all CFs" );
    }

    my $inc = RT::Ticket->new( $RT::SystemUser );
    $inc->Load( $inc_id );
    ok $inc->id, 'loaded incident';
    is $inc->FirstCustomFieldValue('Classification'), 'Spam', 'CF value is in place';
    is $inc->FirstCustomFieldValue('IP'), '172.16.0.1', 'CF value is in place';

    my $inv = RT::Ticket->new( $RT::SystemUser );
    $inv->Load( $inv_id );
    ok $inv->id, 'loaded investigation';
    warning_like {
        is $inv->FirstCustomFieldValue('Classification'), undef, 'no classification CF for Invs';
    } qr/Couldn't load custom field by 'Classification' identifier/, "Loading a non-applied CF warns";
    is $inv->FirstCustomFieldValue('IP'), '172.16.0.1', 'IP is here';
}

diag('Tests the creation of investigation from an incident') if $ENV{TEST_VERBOSE};
my $incident_foo = $agent->create_incident(
    {
        Subject => 'Incident foo for testing creation of a linked Investigation'
    }
);
my $incident_bar = $agent->create_incident(
    {
        Subject => 'Incident bar for testing creation of a linked Investigation'
    }
);
$agent->display_ticket($incident_foo);

$agent->follow_link_ok({text => 'Launch', n => 2}, "Followed 'Launch' link");
$agent->form_name('TicketCreate');
is($agent->value('Incident'), $incident_foo, 'Incident foo is checked');
$agent->field('Incident', $incident_bar);
$agent->click('MoreIncident');
$agent->form_name('TicketCreate');
is($agent->value('Incident'), $incident_bar, 'Incident bar is checked');

$agent->field('Subject', 'Investigation from Incident');
$agent->field('Requestors', 'root@localhost');
$agent->click('Create');
ok(
    $agent->find_link(
        text => 'Incident bar for testing creation of a linked Investigation'
    ),
    'linked to incident bar'
);

diag('Tests the creation of investigation with multiple incidents') if $ENV{TEST_VERBOSE};

RT::Test->stop_server;
my %config = RT->Config->Get('RTIR_IncidentChildren');
$config{Investigation}{Multiple} = 1;
RT->Config->Set(RTIR_IncidentChildren => %config);
RT::Test->started_ok;

$agent = default_agent();
$agent->goto_create_rtir_ticket('Investigations');
$agent->form_name('TicketCreate');
$agent->field('Incident', $incident_foo);
$agent->click('MoreIncident');
$agent->form_name('TicketCreate');
$agent->field('Incident', $incident_bar, 2);
$agent->field('Subject', 'Investigation with multiple Incidents');
$agent->field('Requestors', 'root@localhost');
$agent->click('Create');
for my $incident( qw/foo bar/ ) {
    ok(
        $agent->find_link(
            text => "Incident $incident for testing creation of a linked Investigation"
        ),
        "linked to incident $incident"
    );
}

diag 'Test the creation of investigation without incidents' if $ENV{TEST_VERBOSE};

RT::Test->stop_server;
$config{Investigation}{Required} = 1;
RT->Config->Set(RTIR_IncidentChildren => %config);
RT::Test->started_ok;
$agent->goto_create_rtir_ticket('Investigations');
$agent->form_name('TicketCreate');
$agent->field('Subject', 'Investigation without Incidents');
$agent->field('Requestors', 'root@localhost');
$agent->click('Create');
like( $agent->uri, qr/RTIR\/Create.html/, 'still in the create page' );
$agent->content_contains('Creation failed', 'failed to create');
$agent->content_contains('You must enter an Incident ID');

done_testing;
