# Tests the creation of inventory-and-investigation from an IR

use strict;

use Test::WWW::Mechanize;
use Test::More tests => 24;

require "t/rtir-test.pl";
require RT::IR;

my $agent = default_agent();


my $ir = create_ir($agent, {Subject => 'IR for testing creation of a linked Investigation with no correspondents'});
display_ticket($agent, $ir);


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
    my ($inc_id, $inv_id) = create_incident_and_investigation($agent, 
        {Subject => 'Incident for testing Incident-and-investigation-from-IR creation',
        InvestigationSubject => 'Investigation for testing Incident-and-Investigation-from-IR creation', 
        InvestigationRequestors => 'foo@example.com'}, {Classification => 'Spam', IP => '172.16.0.1'},
        $ir
    );
    # regression test
    $agent->content_unlike(qr{<li>Custom field (\d+) does not apply to this object</li>}, "Custom field allowed");

    my $inc = RT::Ticket->new( $RT::SystemUser );
    $inc->Load( $inc_id );
    ok $inc->id, 'loaded incident';
    is $inc->FirstCustomFieldValue('_RTIR_Classification'), 'Spam', 'CF value is in place';
    is $inc->FirstCustomFieldValue('_RTIR_IP'), '172.16.0.1', 'CF value is in place';

    my $inv = RT::Ticket->new( $RT::SystemUser );
    $inv->Load( $inv_id );
    ok $inv->id, 'loaded investigation';
    is $inv->FirstCustomFieldValue('_RTIR_Classification'), undef, 'no classification CF for Invs';
    is $inv->FirstCustomFieldValue('_RTIR_IP'), '172.16.0.1', 'IP is here';
}

