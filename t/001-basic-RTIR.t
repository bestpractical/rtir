#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

my $SUBJECT = "foo " . rand;

# Create a report
my $report = $agent->create_ir( {Subject => $SUBJECT, Content => "bla" });

{
    my $ir_obj = RT::Ticket->new(RT::SystemUser());

    $ir_obj->Load($report);
    is($ir_obj->Id, $report, "report has right ID");
    is($ir_obj->Subject, $SUBJECT, "subject is right");
}


# Create a new Incident from that report
my $first_incident_id = $agent->create_incident_for_ir( $report, {Subject => "first incident"},
                                               {Function => "IncidentCoord"});

# TODO: make sure subject and content come from Report

# TODO: create Incident with new subject/content

# TODO: make sure all fields are set properly in DB

# create a new incident
my $second_incident_id = $agent->create_incident( { Subject => "foo Incident", Content => "bar baz quux" } );

# link our report to that incident
$agent->LinkChildToIncident( $report, $second_incident_id);

# TODO: verify in DB that report has 1 parent, and the right parent

# Confirm we show the rich text editor for Incident comment since that is now
# default for RT
diag("Incident comment loaded rich text editor");
{
    ok($agent->display_ticket( $first_incident_id ), "Displayed incident ticket");
    $agent->follow_link_ok({text => "Comment"}, "Followed link to comment");
    $agent->content_contains("id=\"UpdateContentType\" value=\"text/html\"", "Update content type is html");
}


undef $agent;
done_testing;
