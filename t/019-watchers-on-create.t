#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 54;

RT::Test->started_ok;
my $agent = default_agent();

my $ir = $agent->create_ir( {Subject => 'IR to test watcher add bug', 
	Requestors => 'requestor@example.com', Cc => 'foo@example.com', AdminCc => 'bar@example.com'});


SKIP: {
	skip "No IR created", 19 if(!$ir);

	$agent->content_unlike(qr/permission denied/i, "No permissions problems");

	diag("Testing if incident report has all watchers") if($ENV{'TEST_VERBOSE'});
	$agent->has_watchers( $ir);
	$agent->has_watchers( $ir, 'Cc');
	$agent->has_watchers( $ir, 'AdminCc');


	# Testing creating an incident and investigation from an Incident Report
	my ($ir_inc, $ir_inv) = $agent->create_incident_and_investigation( 
		{Subject => "Incident linked with IR $ir to test adding watchers", 
		InvestigationSubject => "Investigation linked with Incident to test adding watchers",
		InvestigationRequestors => 'requestor@example.com',
		InvestigationCc => 'foo@example.com',
		InvestigationAdminCc => 'bar@example.com'}, "", $ir);


	
	SKIP: {
		skip "No investigation created", 7 if(!$ir_inv);

		$agent->content_unlike(qr/permission denied/i, "No permissions problems");

		diag("Testing if investigation from IR has all watchers") if($ENV{'TEST_VERBOSE'});
		$agent->has_watchers( $ir_inv);
		$agent->has_watchers( $ir_inv, 'Cc');
		$agent->has_watchers( $ir_inv, 'AdminCc');
	}
}



# Testing creating an incident and investigation not from an incident report
my ($inc, $inv) = $agent->create_incident_and_investigation( 
	{Subject => "Incident to test adding watchers", 
	InvestigationSubject => "Investigation linked to Incident to test adding watchers",
	InvestigationRequestors => 'requestor@example.com',
	InvestigationCc => 'foo@example.com',
	InvestigationAdminCc => 'bar@example.com'});

SKIP: {
	skip "No Investigation created with the Incident", 7 if (!$inv);

	$agent->content_unlike(qr/permission denied/i, "No permissions problems");

	diag("Testing if investigation has all watchers") if($ENV{'TEST_VERBOSE'});
	$agent->has_watchers( $inv);
	$agent->has_watchers( $inv, 'Cc');
	$agent->has_watchers( $inv, 'AdminCc');

}


# Testing creating an investigation by itself
my $solo_inv = $agent->create_investigation( 
	{Subject => 'Investigation created on its own to test adding watchers',
	Requestors => 'requestor@example.com',
	Cc => 'foo@example.com',
	AdminCc => 'bar@example.com'});

SKIP: {
	skip "No investigation created", 7 if(!$solo_inv);

	$agent->content_unlike(qr/permission denied/i, "No permissions problems");

	diag("Testing if solo investigation has all watchers") if($ENV{'TEST_VERBOSE'});
	$agent->has_watchers( $solo_inv);
	$agent->has_watchers( $solo_inv, 'Cc');
	$agent->has_watchers( $solo_inv, 'AdminCc');
}

