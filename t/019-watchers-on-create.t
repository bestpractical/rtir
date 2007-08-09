use strict;
use warnings;

use Test::WWW::Mechanize;
use Test::More tests => 50;

require "t/rtir-test.pl";

my $agent = default_agent();

my $ir = create_ir($agent, {Subject => 'IR to test watcher add bug', 
	Requestors => 'requestor@example.com', Cc => 'foo@example.com', AdminCc => 'bar@example.com'});


SKIP: {
	skip "No IR created", 19 if(!$ir);

	$agent->content_unlike(qr/permission denied/i, "No permissions problems");

	diag("Testing if incident report has all watchers") if($ENV{'TEST_VERBOSE'});
	has_watchers($agent, $ir);
	has_watchers($agent, $ir, 'Cc');
	has_watchers($agent, $ir, 'AdminCc');


	# Testing creating an incident and investigation from an Incident Report
	my ($ir_inc, $ir_inv) = create_incident_and_investigation($agent, 
		{Subject => "Incident linked with IR $ir to test adding watchers", 
		InvestigationSubject => "Investigation linked with Incident to test adding watchers",
		InvestigationRequestors => 'requestor@example.com',
		InvestigationCc => 'foo@example.com',
		InvestigationAdminCc => 'bar@example.com'}, "", $ir);


	
	SKIP: {
		skip "No investigation created", 7 if(!$ir_inv);

		$agent->content_unlike(qr/permission denied/i, "No permissions problems");

		diag("Testing if investigation from IR has all watchers") if($ENV{'TEST_VERBOSE'});
		has_watchers($agent, $ir_inv);
		has_watchers($agent, $ir_inv, 'Cc');
		has_watchers($agent, $ir_inv, 'AdminCc');
	}
}



# Testing creating an incident and investigation not from an incident report
my ($inc, $inv) = create_incident_and_investigation($agent, 
	{Subject => "Incident to test adding watchers", 
	InvestigationSubject => "Investigation linked to Incident to test adding watchers",
	InvestigationRequestors => 'requestor@example.com',
	InvestigationCc => 'foo@example.com',
	InvestigationAdminCc => 'bar@example.com'});

SKIP: {
	skip "No Investigation created with the Incident", 7 if (!$inv);

	$agent->content_unlike(qr/permission denied/i, "No permissions problems");

	diag("Testing if investigation has all watchers") if($ENV{'TEST_VERBOSE'});
	has_watchers($agent, $inv);
	has_watchers($agent, $inv, 'Cc');
	has_watchers($agent, $inv, 'AdminCc');

}


# Testing creating an investigation by itself
my $solo_inv = create_investigation($agent, 
	{Subject => 'Investigation created on its own to test adding watchers',
	Requestors => 'requestor@example.com',
	Cc => 'foo@example.com',
	AdminCc => 'bar@example.com'});

SKIP: {
	skip "No investigation created", 7 if(!$solo_inv);

	$agent->content_unlike(qr/permission denied/i, "No permissions problems");

	diag("Testing if solo investigation has all watchers") if($ENV{'TEST_VERBOSE'});
	has_watchers($agent, $solo_inv);
	has_watchers($agent, $solo_inv, 'Cc');
	has_watchers($agent, $solo_inv, 'AdminCc');
}


sub has_watchers {
	my $agent = shift;
	my $id = shift;
	my $type = shift || 'Correspondents';

	display_ticket($agent, $id);

	$agent->content_like(qr{<td class="labeltop">Correspondents:</td>\s*<td class="value">\s*([@\w\.]+)<br />}ms, "Found $type");
}
