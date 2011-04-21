#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 67;

# Test must be run wtih RT_SiteConfig:
# Set(@MailPlugins, 'Auth::MailFrom');

use_ok('RT::IR');

my $cf;
diag "load the field" if $ENV{'TEST_VERBOSE'};
{
    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => 'Constituency' );
    $cf = $cfs->First;
    ok $cf, 'have a field';
    ok $cf->id, 'with some ID';
}

diag "get list of values" if $ENV{'TEST_VERBOSE'};
my @values = map $_->Name, @{ $cf->Values->ItemsArrayRef };

RT::Test->started_ok;
my $agent = default_agent();
my $rtir_user = rtir_user();

diag "create a ticket via gate" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;
    my $val = RT->Config->Get('RTIR_CustomFieldsDefaults')->{'Constituency'}; # we have one default
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

        $agent->display_ticket( $id);
        $agent->content_like( qr/\Q$val/, "value on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok $ticket->id, 'loaded ticket';
        is $ticket->QueueObj->Name, $queue, 'correct queue';
        is $ticket->FirstCustomFieldValue('Constituency'), $val, 'correct value';
    }
}

diag "create a ticket via gate using Extension header" if $ENV{'TEST_VERBOSE'};
{
    my $i = 0;

    my $default = RT->Config->Get('RTIR_CustomFieldsDefaults')->{'Constituency'};
    my $val = (grep lc($_) ne lc($default), @values)[0];
    ok $val, 'find not default value';

    my $incident_id; # block couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $text = <<EOF;
From: @{[ $rtir_user->EmailAddress ]}
To: rt\@@{[RT->Config->Get('rtname')]}
X-RT-Mail-Extension: $val
Subject: This is a test of constituency functionality

Foob!
EOF
        my ($status, $id) = RT::Test->send_via_mailgate($text, queue => $queue );
        is $status >> 8, 0, "The mail gateway exited ok";
        ok $id, "created ticket $id";
        $incident_id = $id if $queue eq 'Incidents';

        $agent->display_ticket( $id);
        $agent->content_like( qr/\Q$val/, "value on the page" );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->QueueObj->Name, $queue, 'correct queue' );
        is( $ticket->FirstCustomFieldValue('Constituency'), $val, 'correct value' );
    }
}


