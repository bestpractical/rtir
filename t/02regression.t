#!/usr/bin/perl

# RTHOME must be set to run this.  Note that this runs on an
# *INSTALLED* copy of RTIR, with a running server.

use Test::More tests => 23;

use strict;
use warnings;
use Test::WWW::Mechanize;
use HTTP::Cookies;

BEGIN {
  unless ($ENV{RTHOME}) {
    die "\n\nYou must set the RTHOME environment variable to the root of your RT install.\n\n";
  }
}

use lib "$ENV{RTHOME}/lib";
use lib "$ENV{RTHOME}/local/lib";

use RT;
ok(RT::LoadConfig);
ok(RT::Init, "Basic initialization and DB connectivity");


# set things up
my $RTIR_TEST_USER = "rtir_test_user";
my $RTIR_TEST_PASS = "rtir_test_pass";

create_user();


my $agent = Test::WWW::Mechanize->new();
$agent->cookie_jar(HTTP::Cookies->new);

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

    DisplayTicket($id);

    # Select the "New" link from the Display page
    $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");

    $agent->form_number(2);

    $agent->field("Subject", $subject) if $subject;
    $agent->field("Content", $content) if $content;

    set_custom_field(Function => "IncidentCoord");
    
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

    DisplayTicket($id);

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

    $agent->get_ok("$RT::WebURL/RTIR/index.html", "loaded front page");

    LoginIfNecessary();
    
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

    $agent->get_ok("$RT::WebURL/RTIR/index.html", "Loaded home page");

    LoginIfNecessary();
    
    $agent->follow_link_ok({text => "Incidents", n => "1"}, "Followed 'Incidents' link");
    
    $agent->follow_link_ok({text => "New Incident", n => "1"}, "Followed 'New Incident' link");
    
    # set the form
    $agent->form_number(2);

    # set the subject
    $agent->field("Subject", $args{'Subject'});

    # set the content
    $agent->field("Content", $args{'Content'});

    set_custom_field(Function => "IncidentCoord");

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
 
sub set_custom_field {
    my $cf_name = shift;
    my $val = shift;

    my $field_name = $agent->value($cf_name);
    diag("found $cf_name at $field_name");
    $agent->field($field_name, $val);
}

sub LoginIfNecessary {

  if ($agent->title eq 'Login') {
    diag("logging in");
    $agent->form_number(1);
    $agent->field("user", $RTIR_TEST_USER);
    $agent->field("pass", $RTIR_TEST_PASS);
    $agent->submit_form(form_number => "1");
  }
}

sub DisplayTicket {
    my $id = shift;

    $agent->get_ok("$RT::WebURL/RTIR/Display.html?id=$id", "Loaded Display page");
}

sub create_user {
    my $user_obj = RT::User->new($RT::SystemUser);
    $user_obj->Load($RTIR_TEST_USER);
    if ($user_obj->Id) {
        $user_obj->SetPassword($RTIR_TEST_PASS);
    } else {
        $user_obj->Create(Name => $RTIR_TEST_USER,
                          Password => $RTIR_TEST_PASS,
                          EmailAddress => "$RTIR_TEST_USER\@example.com",
                          RealName => "$RTIR_TEST_USER Smith",
                          Privileged => 1);
    }

    ok($user_obj->Id > 0, "Successfully found the user");
    
    my $group_obj = RT::Group->new($RT::SystemUser);
    $group_obj->LoadUserDefinedGroup("DutyTeam");
    ok($group_obj->Id > 0, "Successfully found the DutyTeam group");

    $group_obj->AddMember($user_obj->Id);
    ok($group_obj->HasMember($user_obj->PrincipalObj), "user is in the group");
}
