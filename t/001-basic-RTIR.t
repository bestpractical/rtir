#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 19;

require "t/rtir-test.pl";

my $agent = default_agent();

# Create a report
my $report = CreateReport(Subject => "foo", Content => "bar baz");

# Create a new Incident from that report
my $first_incident_id = NewIncidentFromChild(id => $report);

# TODO: make sure subject and content come from Report

# TODO: create Incident with new subject/content

# TODO: make sure all fields are set properly in DB

# create a new incident
my $second_incident_id = CreateIncident(Subject => "foo Incident", Content => "bar baz quux");

# link our report to that incident
LinkChildToIncident(id => $report, incident => $second_incident_id);

# TODO: verify in DB that report has 1 parent, and the right parent

sub NewIncidentFromChild {
    my %args = ( @_ );

    my $id = $args{'id'};
    my $subject = $args{'Subject'};
    my $content = $args{'Content'};

    display_ir($agent, $id);

    # Select the "New" link from the Display page
    $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");

    $agent->form_number(2);

    $agent->field("Subject", $subject) if $subject;
    $agent->field("Content", $content) if $content;

    set_custom_field($agent, Function => "IncidentCoord");
    
    $agent->click("CreateIncident");
    
    is ($agent->status, 200, "Attempting to create new incident linked to child $id");

    ok ($agent->content =~ /.*Ticket (\d+) created in queue*/g, "Incident created from child $id.");
    my $incident_id = $1;

    diag("incident ID is $incident_id");
    return $incident_id;
}

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

sub CreateReport {
    my %args = ( @_ );

    $agent->follow_link_ok({text => "Incident Reports", n => "1"}, "Followed 'Incident Reports' link");
    
    $agent->follow_link_ok({text => "New Report", n => "1"}, "Followed 'New Report' link");
    
    # set the form
    $agent->form_number(2);

    # set the subject
    $agent->field("Subject", $args{'Subject'});

    # set the content
    $agent->field("Content", $args{'Content'});

    # Create it!
    $agent->click("Create");
    
    is ($agent->status, 200, "Attempted to create the ticket");

    # Now see if we succeeded
    my $content = $agent->content();
    my $id = -1;
    if ($content =~ /.*Ticket (\d+) created.*/g) {
	$id = $1;
    }

    ok ($id > 0, "Ticket $id created successfully.");

    return $id;
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
