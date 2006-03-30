#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 22;

require "t/rtir-test.pl";

my $agent = default_agent();

my $SUBJECT = "foo " . rand;

# Create a report
my $report = create_ir($agent, {Subject => $SUBJECT, Content => "bla" });

{
    my $ir_obj = RT::Ticket->new($RT::SystemUser);
    my $stifle_warnings = $RT::SystemUser;

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
my $second_incident_id = CreateIncident(Subject => "foo Incident", Content => "bar baz quux");

# link our report to that incident
LinkChildToIncident(id => $report, incident => $second_incident_id);

# TODO: verify in DB that report has 1 parent, and the right parent


sub LinkChildToIncident {
    my %args = ( @_ );

    my $id = $args{'id'};
    my $incident = $args{'incident'};

    display_ir($agent, $id);

    # Select the "Link" link from the Display page
    $agent->follow_link_ok({text => "[Link]", n => "1"}, "Followed 'Link(to Incident)' link");

    # TODO: Make sure desired incident appears on page

    # Choose the incident and submit
    $agent->form_number(2);
    $agent->field("SelectedTicket", $incident);
    $agent->click("LinkChild");

    is ($agent->status, 200, "Attempting to link child $id to Incident $incident");

    ok ($agent->content =~ /Ticket $id: Link created/g, "Incident $incident linked successfully.");

    return;
}

sub CreateIncident {
    my %args = ( @_ );

    $agent->follow_link_ok({text => "Incidents", n => "1"}, "Followed 'Incidents' link");
    
    $agent->follow_link_ok({text => "New Incident", n => "1"}, "Followed 'New Incident' link");
    
    # set the form
    $agent->form_number(2);

    # set the subject
    $agent->field("Subject", $args{'Subject'});

    # set the content
    $agent->field("Content", $args{'Content'});

    set_custom_field($agent, Function => "IncidentCoord");

    # Create it!
    $agent->click("CreateIncident");
    is ($agent->status, 200, "Attempted to create the Incident");

    # Now see if we succeeded
    my $content = $agent->content();
    my $id = -1;
    if ($content =~ /.*Ticket (\d+) created.*/g) {
	$id = $1;
    }

    ok ($id > 1, "Incident $id created successfully.");

    return $id;
}
