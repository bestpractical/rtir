#!/usr/bin/perl

use Test::More qw(no_plan);

use strict;
use warnings;
use WWW::Mechanize;

# set things up
my $BASEURL = "http://localhost";
my $agent = WWW::Mechanize->new();


# Create a report
my $report = CreateReport(Subject => "foo", Content => "bar baz");

# Create a new Incident from that report
NewIncidentFromChild(id => $report);

# TODO: make sure subject and content come from Report

# TODO: create Incident with new subject/content

# TODO: make sure all fields are set properly in DB

# create a new incident
my $incident = CreateIncident(Subject => "foo Incident", Content => "bar baz quux");

# link our report to that incident
LinkChildToIncident(id => $report, incident => $incident);

# TODO: verify in DB that report has 1 parent, and the right parent

sub NewIncidentFromChild {
    my %args = ( @_ );

    my $id = $args{'id'};
    my $subject = $args{'Subject'};
    my $content = $args{'Content'};

    DisplayTicket($id);

    # Select the "New" link from the Display page
    $agent->follow_link(text => "[New]", n => "1");    
    is ($agent->status, 200, "Followed 'New (Incident)' link");

    $agent->form_number(2);

    $agent->field("Subject", $subject) if $subject;
    $agent->field("Content", $content) if $content;

    # TODO: this should not be hardcoded
    SetFunction("IncidentCoord");

    $agent->submit();

    is ($agent->status, 200, "Attempting to create new incident linked to child $id");

    ok ($agent->content =~ /.*Ticket (\d+) created in queue*/g, "Incident created from child $id.");

    return;
}

sub LinkChildToIncident {
    my %args = ( @_ );

    my $id = $args{'id'};
    my $incident = $args{'incident'};

    DisplayTicket($id);

    # Select the "Link" link from the Display page
    $agent->follow_link(text => "[Link]", n => "1");    
    is ($agent->status, 200, "Followed 'Link(to Incident)' link");

    # TODO: Make sure desired incident appears on page

    # Choose the incident and submit
    $agent->form_number(2);
    $agent->field("SelectedTicket", $incident);
    $agent->submit();

    is ($agent->status, 200, "Attempting to link child $id to Incident $incident");

    ok ($agent->content =~ /.*Ticket (\d+): Transaction Created.*/g, "Incident $incident linked successfully.");

    return;
}

sub CreateReport {
    my %args = ( @_ );

    $agent->get($BASEURL . "/RTIR/index.html");
    is ($agent->status, 200, "Loaded a page");

    LoginIfNecessary();
    
    $agent->follow_link(text => "Incident Reports", n => "1");
    is ($agent->status, 200, "Followed 'Incident Reports' link");
    
    $agent->follow_link(text => "New Report", n => "1");
    is ($agent->status, 200, "Followed 'New Report' link");
    
    # set the form
    $agent->form_number(2);

    # set the subject
    $agent->field("Subject", $args{'Subject'});

    # set the content
    $agent->field("Content", $args{'Content'});

    # Create it!
    $agent->submit();
    
    is ($agent->status, 200, "Attempted to create the ticket");

    # Now see if we succeeded
    my $content = $agent->content();
    my $id = -1;
    if ($content =~ /.*Ticket (\d+) created.*/g) {
	$id = $1;
    }

    ok ($id > 1, "Ticket $id created successfully.");

    return $id;
}

sub CreateIncident {
    my %args = ( @_ );

    $agent->get($BASEURL . "/RTIR/index.html");
    is ($agent->status, 200, "Loaded a page");

    LoginIfNecessary();
    
    $agent->follow_link(text => "Incidents", n => "1");
    is ($agent->status, 200, "Followed 'Incidents' link");
    
    $agent->follow_link(text => "New Incident", n => "1");
    is ($agent->status, 200, "Followed 'New Incident' link");
    
    # set the form
    $agent->form_number(2);

    # set the subject
    $agent->field("Subject", $args{'Subject'});

    # set the content
    $agent->field("Content", $args{'Content'});

    # TODO: this should not be hardcoded
    SetFunction("IncidentCoord");

    # Create it!
    $agent->submit();
    
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

sub SetReporterType {
    my $type = shift;

    $agent->field("CustomField-11-Values", $type);
}

sub SetHowReported {
    my $how = shift;

    $agent->field("CustomField-10-Values", $how);
}

sub SetSLA {
    my $sla = shift;

    $agent->field("CustomField-7-Values", $sla);
}
    
sub SetConstituency {
    my $cons = shift;
 
    $agent->field("CustomField-2-Values", $cons);
}

sub SetFunction {
    my $function = shift;

    $agent->field("CustomField-8-Values", $function);
}

sub LoginIfNecessary {

    if ($agent->title eq 'Login') {
	$agent->form_number(1);
	$agent->field("user", "root");
	$agent->field("pass", "password");
	$agent->submit_form(form_number => "1");
    }
    
}

sub DisplayTicket {
    my $id = shift;

    $agent->get($BASEURL . "/RTIR/Display.html?id=$id");
    is ($agent->status, 200, "Loaded Display page");
}
