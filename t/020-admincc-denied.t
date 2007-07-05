use strict;

use Test::WWW::Mechanize;
use Test::More tests => 14;

require "rtir-test.pl";

my $agent = default_agent();

my $ir = create_ir($agent, {Subject => 'IR to test AdminCC Denied bug'});

my ($inc, $inv) = create_incident_and_investigation_for_ir($agent, $ir, 
	{Subject => "Incident linked with IR $ir to test AdminCC Denied bug", 
	InvestigationSubject => "Investigation linked with Incident to test AdminCC Denied bug",
	InvestigationAdminCc => 'foo@bar.tld'});

$agent->content_unlike(qr/permission denied/i, "No permissions problems");




sub create_incident_and_investigation_for_ir {
	my $agent = shift;
	my $ir_id = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    display_ticket($agent, $ir_id);

    # Select the "New" link from the Display page
    $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");

	# Fill out forms
    $agent->form_number(3);

    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }

    $agent->click("CreateWithInvestigation");
    
    is ($agent->status, 200, "Attempting to create new incident and investigation linked to child $ir_id");
    ok ($agent->content =~ /.*Ticket (\d+) created in queue &#39;Incidents&#39;/g, "Incident created from child $ir_id.");
    my $incident_id = $1;
    
    ok ($agent->content =~ /.*Ticket (\d+) created in queue &#39;Investigations&#39;/g, "Investigation created for Incident $incident_id.");
    my $investigation_id = $1;

#    diag("incident ID is $incident_id");
    return ($incident_id, $investigation_id);
}
