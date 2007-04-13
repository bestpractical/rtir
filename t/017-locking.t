#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 16;
require "t/rtir-test.pl";
use RT::IR::Ticket;

my $agent = default_agent();

my $SUBJECT = "foo " . rand;

# Create a report
my $report = create_ir($agent, {Subject => $SUBJECT, Content => "bla" });

{
    my $ir_obj = RT::Ticket->new(RT::SystemUser());

    $ir_obj->Load($report);
    is($ir_obj->Id, $report, "report has right ID");
    is($ir_obj->Subject, $SUBJECT, "subject is right");

    ok(!RT::IR::Ticket::Locked($ir_obj), "Starts off unlocked");
    ok(RT::IR::Ticket::Lock($ir_obj), "Then we lock it");
    ok(RT::IR::Ticket::Locked($ir_obj), "Then it's locked");
    ok(!RT::IR::Ticket::Lock($ir_obj), "Can't lock a locked ticket");
    ok(RT::IR::Ticket::Unlock($ir_obj), "Then we unlock it");
    ok(!RT::IR::Ticket::Locked($ir_obj), "Ends unlocked");

}

1;

__DATA__

TODO: think about testing locking on other object types

# Create a new Incident from that report
my $first_incident_id = create_incident_for_ir($agent, $report, {Subject => "first incident"},
                                               {Function => "IncidentCoord"});

# TODO: make sure subject and content come from Report

# TODO: create Incident with new subject/content

# TODO: make sure all fields are set properly in DB

# create a new incident
my $second_incident_id = create_incident( $agent, { Subject => "foo Incident", Content => "bar baz quux" } );

