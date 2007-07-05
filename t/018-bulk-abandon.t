use strict;

use Test::WWW::Mechanize;
use Test::More tests => 99;

require "rtir-test.pl";

my $agent = default_agent();
#create_user();

my @ir_ids;

for(my $i = 1; $i < 5; $i++) {
	push @ir_ids, create_ir($agent, {Subject => "IR number $i for RTIR testing"});
	my $ir_obj = RT::Ticket->new(RT::SystemUser());
	my $ir_id = $ir_ids[-1];

    $ir_obj->Load($ir_id);
    is($ir_obj->Id, ($ir_id), "IR $i has the right ID");
    is($ir_obj->Subject, "IR number $i for RTIR testing", "IR $i has the right subject")
}

my @incident_ids;

push @incident_ids, create_incident_for_ir($agent, $ir_ids[0], {Subject => "Incident number 1"}, {Function => "IncidentCoord"});
my $inc_obj = RT::Ticket->new(RT::SystemUser());

$inc_obj->Load($incident_ids[0]);
is($inc_obj->Id, $incident_ids[0], "Incident has the right ID");
is($inc_obj->Subject, "Incident number 1", "Incident has the right subject");

LinkChildToIncident(id => $ir_ids[1], incident => $incident_ids[0]);

ticket_is_linked_to_inc($agent, $ir_ids[0], [$incident_ids[0]]);
ticket_is_linked_to_inc($agent, $ir_ids[1], [$incident_ids[0]]);

push @incident_ids, create_incident_for_ir($agent, $ir_ids[2], {Subject => 'Incident number 2'}, {Function => 'IncidentCoord'});

$inc_obj->Load($incident_ids[0]);
is($inc_obj->Id, $incident_ids[0], "Incident has the right ID");
is($inc_obj->Subject, "Incident number 1", "Incident has the right subject");

LinkChildToIncident(id => $ir_ids[3], incident => $incident_ids[1]);

ticket_is_linked_to_inc($agent, $ir_ids[2], [$incident_ids[1]]);
ticket_is_linked_to_inc($agent, $ir_ids[3], [$incident_ids[1]]);

resolve_ir($agent, $ir_ids[0]);

my @invests;

push @invests, create_investigation($agent, {Incident => $incident_ids[0], Subject => 'Investigation 1 for incident ' . $incident_ids[0]});
push @invests, create_investigation($agent, {Incident => $incident_ids[0], Subject => 'Investigation 2 for incident ' . $incident_ids[0]});

push @invests, create_investigation($agent, {Incident => $incident_ids[1], Subject => 'Investigation 1 for incident ' . $incident_ids[1]});
push @invests, create_investigation($agent, {Incident => $incident_ids[0], Subject => 'Investigation 2 for incident ' . $incident_ids[1]});

resolve_inv($agent, $invests[0]);

bulk_abandon($agent, @incident_ids);

foreach(@incident_ids) {
	ticket_state_is($agent, $_, 'abandoned', "Incident #$_ is abandoned");
}

foreach(@ir_ids ) {
	$agent->get(RT->Config->Get('WebURL') . "/RTIR/Display.html?id=$_");
	$agent->content =~ qr{State:\s*</td>\s*<td[^>]*?>\s*<span class="cf-value">([\w ]+)</span>}ism;
	diag("IR #$_ state is " . $1);
}
foreach(@invests) {
	$agent->get(RT->Config->Get('WebURL') . "/RTIR/Display.html?id=$_");
	$agent->content =~ qr{State:\s*</td>\s*<td[^>]*?>\s*<span class="cf-value">([\w ]+)</span>}ism;
	diag("Investigation #$_ state is " . $1);
}


sub bulk_abandon {
	my $agent = shift;
	my @toAbandon = @_;
	
	go_home($agent);
	$agent->follow_link_ok({text => "Incidents", n => '1'}, "Followed 'Incidents' link");
	$agent->follow_link_ok({text => "Bulk Abandon", n => '1'}, "Followed 'Bulk Abandon' link");
	
	$agent->form_number(3);
	foreach my $id (@toAbandon) {
		$agent->tick('SelectedTickets', $id);
	}
	
	$agent->click('BulkAbandon');
	
	foreach my $id (@toAbandon) {
		ok_and_content_like($agent, qr/Ticket $id: State changed from \w+ to abandoned/, "Incident $id abandoned");
	}
	
	$agent->form_number(3);
	ok($agent->value('BulkAbandon'), "Still on Bulk Abandon page");
}

sub resolve_ir {
	my $agent = shift;
	my $id = shift;	
	
	display_ticket($agent, $id);
	$agent->follow_link_ok({text => "Quick Resolve", n => "1"}, "Followed 'Quick Resolve' link");
	
	is($agent->status, 200, "Attempting to resolve IR $id");
	
	$agent->content_like(qr/.*State changed from \w+ to resolved.*/, "Successfully resolved IR $id")
}


sub resolve_inv {
	my $agent = shift;
	my $id = shift;	
	
	display_ticket($agent, $id);
	$agent->follow_link_ok({text => "Quick Resolve", n => "1"}, "Followed 'Quick Resolve' link");
	
	is($agent->status, 200, "Attempting to resolve Investigation $id");
	
	$agent->content_like(qr/.*State changed from \w+ to resolved.*/, "Successfully resolved Investigation $id")
}

#Copied straight from t/001-basic-RTIR.t

sub LinkChildToIncident {
    my %args = ( @_ );

    my $id = $args{'id'};
    my $incident = $args{'incident'};

    display_ticket($agent, $id);

    # Select the "Link" link from the Display page
    $agent->follow_link_ok({text => "[Link]", n => "1"}, "Followed 'Link(to Incident)' link");

    # TODO: Make sure desired incident appears on page

    # Choose the incident and submit
    $agent->form_number(3);
    $agent->field("SelectedTicket", $incident);
    $agent->click("LinkChild");

    is ($agent->status, 200, "Attempting to link child $id to Incident $incident");

    ok ($agent->content =~ /Ticket $id: Link created/g, "Incident $incident linked successfully.");

    return;
}
