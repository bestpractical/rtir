#!/usr/bin/perl

# Load this in test scripts with: require "t/rtir-test.pl";
# *AFTER* loading in Test::More.

# RTHOME must be set to run this.  Note that this runs on an
# *INSTALLED* copy of RTIR, with a running server.

use strict;
use warnings;

use Test::WWW::Mechanize;
use HTTP::Cookies;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt3/local/lib /opt/rt3/lib);

use RT;
ok(RT::LoadConfig);
ok(RT::Init, "Basic initialization and DB connectivity");

my $RTIR_TEST_USER = "rtir_test_user";
my $RTIR_TEST_PASS = "rtir_test_pass";


sub default_agent { 
    my $agent = Test::WWW::Mechanize->new();
    $agent->cookie_jar(HTTP::Cookies->new);

    go_home($agent);
    log_in($agent);
    return $agent;
}

sub set_custom_field {
    my $agent = shift;
    my $cf_name = shift;
    my $val = shift;

    my $field_name = $agent->value($cf_name);
#    diag("found $cf_name at $field_name");
    $agent->field($field_name, $val);
}

sub go_home {
    my $agent = shift;
    my $weburl = RT->Config->Get('WebURL');
    $agent->get_ok("$weburl/RTIR/index.html", "Loaded home page");
}

sub log_in {
    my $agent = shift;

    if ($agent->title eq 'Login') {
#        diag("logging in");
        $agent->form_number(1);
        $agent->field("user", $RTIR_TEST_USER);
        $agent->field("pass", $RTIR_TEST_PASS);
        $agent->submit_form(form_number => "1");
    }
}

sub display_ticket {
    my $agent = shift;
    my $id = shift;

    $agent->get_ok("$RT::WebURL/RTIR/Display.html?id=$id", "Loaded Display page");
}

sub create_user {
    my $user_obj = rtir_user();

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
    
    my $group_obj = RT::Group->new(RT::SystemUser());
    $group_obj->LoadUserDefinedGroup("DutyTeam");
    ok($group_obj->Id > 0, "Successfully found the DutyTeam group");

    $group_obj->AddMember($user_obj->Id);
    ok($group_obj->HasMember($user_obj->PrincipalObj), "user is in the group");
}

sub rtir_user {
    my $u = RT::User->new(RT::SystemUser());
    $u->Load($RTIR_TEST_USER);
    return $u;
}

sub create_ir {
    my $agent = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    go_home($agent);

    $agent->follow_link_ok({text => "Incident Reports", n => "1"}, "Followed 'Incident Reports' link");

    $agent->follow_link_ok({text => "New Report", n => "1"}, "Followed 'New Report' link");

    # set the form
    $agent->form_number(2);

    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }

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

sub create_investigation {
    my $agent = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    # Must specify a correspondant.
    $fields->{'Requestors'} ||= $RTIR_TEST_USER;

    go_home($agent);

    $agent->follow_link_ok({text => "Investigations", n => "1"}, "Followed 'Investigations' link");

    $agent->follow_link_ok({text => "New Investigation", n => "1"}, "Followed 'New Investigation' link");

    # set the form
    $agent->form_number(2);

    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }

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

sub create_incident_for_ir {
    my $agent = shift;
    my $ir_id = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    display_ticket($agent, $ir_id);

    # Select the "New" link from the Display page
    $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");

    $agent->form_number(2);

    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }

    $agent->click("CreateIncident");
    
    is ($agent->status, 200, "Attempting to create new incident linked to child $ir_id");

    ok ($agent->content =~ /.*Ticket (\d+) created in queue*/g, "Incident created from child $ir_id.");
    my $incident_id = $1;

#    diag("incident ID is $incident_id");
    return $incident_id;
}

sub ok_and_content_like {
    my $agent = shift;
    my $re = shift;
    my $desc = shift || "looks good";
    
    is($agent->status, 200, "request successful");
    like($agent->content, $re, $desc);
}

1;
