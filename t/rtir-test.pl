#!/usr/bin/perl

# Load this in test scripts with: require "t/rtir-test.pl";
# *AFTER* loading in Test::More.

# RTHOME must be set to run this.  Note that this runs on an
# *INSTALLED* copy of RTIR, with a running server.

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
    diag("found $cf_name at $field_name");
    $agent->field($field_name, $val);
}

sub go_home {
    my $agent = shift;
    $agent->get_ok("$RT::WebURL/RTIR/index.html", "Loaded home page");
}

sub log_in {
    my $agent = shift;

    if ($agent->title eq 'Login') {
        diag("logging in");
        $agent->form_number(1);
        $agent->field("user", $RTIR_TEST_USER);
        $agent->field("pass", $RTIR_TEST_PASS);
        $agent->submit_form(form_number => "1");
    }
}

sub display_ir {
    my $agent = shift;
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

1;
