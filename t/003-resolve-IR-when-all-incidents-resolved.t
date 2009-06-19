#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 36;

RT::Test->started_ok;
my $agent = default_agent();

my $ir_id  = $agent->create_ir( {Subject => "resolves slowly"});

my $subj1 = "inc1_" . rand;
my $subj2 = "inc2_" . rand;

my $inc_1 = $agent->create_incident_for_ir( $ir_id, {Subject => $subj1});
my $inc_2 = $agent->create_incident_for_ir( $ir_id, {Subject => $subj2});

$agent->display_ticket( $ir_id);

like($agent->content, qr/\Q$subj1/, "we're linked to the first incident");
like($agent->content, qr/\Q$subj2/, "we're linked to the second incident");

ir_status('open');

$agent->display_ticket( $inc_1);
$agent->follow_link_ok({text => "Quick Resolve"}, "followed 'Quick Resolve' link for first incident");
like($agent->content, qr/State changed from open to resolved/, "resolved the first incident");

ir_status('open');

$agent->display_ticket( $inc_2);
$agent->follow_link_ok({text => "Quick Resolve"}, "followed 'Quick Resolve' link for second incident");
like($agent->content, qr/State changed from open to resolved/, "resolved the second incident");

ir_status('resolved');


sub ir_status {
    my $status = shift;

    use DBIx::SearchBuilder::Record::Cachable;
    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    my $ir = RT::Ticket->new(RT::SystemUser());
    $ir->Load($ir_id);
    is($ir->Id, $ir_id, "loaded ticket $ir_id OK");
    is($ir->Status, $status, "ticket $ir_id has status $status");
}
