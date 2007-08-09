#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 21;

require "t/rtir-test.pl";

my $agent = default_agent();

my $SUBJECT = "foo " . rand;

# Create a report
my $report = create_ir($agent, {Subject => $SUBJECT, Content => "bla" });

{
    my $ir_obj = RT::Ticket->new(RT::SystemUser());

    $ir_obj->Load($report);
    is($ir_obj->Id, $report, "report has right ID");
    is($ir_obj->Subject, $SUBJECT, "subject is right");
}


# Create a new Incident from that report
my $first_incident_id = create_incident_for_ir($agent, $report, {Subject => "first incident"},
                                               {Function => "IncidentCoord"});

# TODO: make sure subject and content come from Report

# TODO: create Incident with new subject/content

# TODO: make sure all fields are set properly in DB

# create a new incident
my $second_incident_id = create_incident( $agent, { Subject => "foo Incident", Content => "bar baz quux" } );

# link our report to that incident
LinkChildToIncident($agent, $report, $second_incident_id);

# TODO: verify in DB that report has 1 parent, and the right parent




