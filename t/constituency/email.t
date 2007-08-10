#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 61;
require "t/rtir-test.pl";

# Test must be run wtih RT_SiteConfig:
# Set(@MailPlugins, 'Auth::MailFrom');

use_ok('RT');
RT::LoadConfig();
RT::Init();

use_ok('RT::IR');

my $cf;
diag "load the field" if $ENV{'TEST_VERBOSE'};
{
    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => '_RTIR_Constituency' );
    $cf = $cfs->First;
    ok $cf, 'have a field';
    ok $cf->id, 'with some ID';
}

my $agent = default_agent();
my $rtir_user = rtir_user();

diag "create a ticket via gate" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;
    my $val = RT->Config->Get('_RTIR_Constituency_default'); # we have one default
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $text = <<EOF;
From: @{[ $rtir_user->EmailAddress ]}
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: This is a test of constituency functionality

Foob!
EOF
        my ($status, $id) = RT::Test->send_via_mailgate($text, queue => $queue);
        is $status >> 8, 0, "The mail gateway exited ok";
        ok $id, "created ticket $id";

        display_ticket($agent, $id);
        $agent->content_like( qr/\Q$val/, "value on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok $ticket->id, 'loaded ticket';
        is $ticket->QueueObj->Name, $queue, 'correct queue';
        is $ticket->FirstCustomFieldValue('_RTIR_Constituency'), $val, 'correct value';
    }
}

diag "create a ticket via gate using EXTENSION" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;
    my $incident_id; # block couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $text = <<EOF;
From: @{[ $rtir_user->EmailAddress ]}
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: This is a test of constituency functionality

Foob!
EOF
        my $val = 'GOVNET';
        local $ENV{'EXTENSION'} = $val;
        my ($status, $id) = RT::Test->send_via_mailgate($text, queue => $queue);
        is $status >> 8, 0, "The mail gateway exited ok";
        ok $id, "created ticket $id";
        $incident_id = $id if $queue eq 'Incidents';

        display_ticket($agent, $id);
        $agent->content_like( qr/\Q$val/, "value on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->QueueObj->Name, $queue, 'correct queue' );
        is( $ticket->FirstCustomFieldValue('_RTIR_Constituency'), $val, 'correct value' );
    }
}


