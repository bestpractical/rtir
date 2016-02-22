#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

my @ir_ids;

for(my $i = 1; $i < 5; $i++) {
	push @ir_ids, $agent->create_ir( {Subject => "IR number $i for RTIR testing"});
	my $ir_obj = RT::Ticket->new(RT::SystemUser());
	my $ir_id = $ir_ids[-1];

    $ir_obj->Load($ir_id);
    is($ir_obj->Id, ($ir_id), "IR $i has the right ID");
    is($ir_obj->Subject, "IR number $i for RTIR testing", "IR $i has the right subject")
}

my @incident_ids;

push @incident_ids, $agent->create_incident_for_ir( $ir_ids[0], {Subject => "Incident number 1"}, {Function => "IncidentCoord"});
my $inc_obj = RT::Ticket->new(RT::SystemUser());

$inc_obj->Load($incident_ids[0]);
is($inc_obj->Id, $incident_ids[0], "Incident has the right ID");
is($inc_obj->Subject, "Incident number 1", "Incident has the right subject");

$agent->LinkChildToIncident( $ir_ids[1], $incident_ids[0]);

$agent->ticket_is_linked_to_inc( $ir_ids[0], [$incident_ids[0]]);
$agent->ticket_is_linked_to_inc( $ir_ids[1], [$incident_ids[0]]);

push @incident_ids, $agent->create_incident_for_ir( $ir_ids[2], {Subject => 'Incident number 2'}, {Function => 'IncidentCoord'});

$inc_obj->Load($incident_ids[0]);
is($inc_obj->Id, $incident_ids[0], "Incident has the right ID");
is($inc_obj->Subject, "Incident number 1", "Incident has the right subject");

$agent->LinkChildToIncident( $ir_ids[3], $incident_ids[1]);

$agent->ticket_is_linked_to_inc( $ir_ids[2], [$incident_ids[1]]);
$agent->ticket_is_linked_to_inc( $ir_ids[3], [$incident_ids[1]]);

$agent->resolve_rtir_ticket( $ir_ids[0], 'Incident Report');

my @invests;

push @invests, $agent->create_investigation( {Incident => $incident_ids[0], Subject => 'Inv 1 for inc ' . $incident_ids[0]});
push @invests, $agent->create_investigation( {Incident => $incident_ids[0], Subject => 'Inv 2 for inc ' . $incident_ids[0]});

push @invests, $agent->create_investigation( {Incident => $incident_ids[1], Subject => 'Inv 1 for inc ' . $incident_ids[1]});
push @invests, $agent->create_investigation( {Incident => $incident_ids[0], Subject => 'Inv 2 for inc ' . $incident_ids[1]});

$agent->resolve_rtir_ticket( $invests[0], 'Investigation');

$agent->bulk_abandon( @incident_ids);

foreach my $id (@incident_ids) {
	$agent->ticket_status_is( $id, 'abandoned', "Incident $id is abandoned");
}

foreach my $id ($ir_ids[0]) {
    $agent->ticket_status_is( $id, 'resolved', 'correct status' );
}
foreach my $id (@ir_ids[ 1 .. $#invests ] ) {
    $agent->ticket_status_is( $id, 'rejected', 'correct status' );
}
foreach my $id (@invests) {
    $agent->ticket_status_is( $id, 'resolved', 'correct status' );
}

undef $agent;
done_testing;
