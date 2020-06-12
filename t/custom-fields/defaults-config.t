#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

my $defaults = {};
$defaults->{'How Reported'}  = 'Telephone';   # IRs
$defaults->{'Description'}   = 'Bloody mess'; # Incs
$defaults->{'IP'}            = '127.0.0.1';   # Invs and all
$defaults->{'Where Blocked'} = 'On the Moon'; # Countermeasures

my $custom_field = RT::CustomField->new( RT->SystemUser );
foreach my $cf_name ( keys %{$defaults} ) {

    my ($ret, $msg) = $custom_field->LoadByName( Name => $cf_name );
    ok $ret, "Load custom field '$cf_name'";

    ($ret, $msg) = $custom_field->SetDefaultValues( Values => $defaults->{$cf_name} );
    ok $ret, "Set custom field $cf_name default value to $defaults->{$cf_name}"
}

my %test_on = (
    'Incident Reports' => 'How Reported',
    'Incidents'        => 'Description',
    'Investigations'   => 'IP',
    'Countermeasures'  => 'Where Blocked',
);

my %replace_with = (
    'How Reported'  => 'Email',
    'Description'   => 'Lucky Incident',
    'IP'            => '172.16.0.1',
    'Where Blocked' => 'On the Sun',
);

RT::Test->started_ok;
my $agent = default_agent();

{
    my $incident_id; # countermeasure couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        my $cf_name = $test_on{ $queue };
        my $cf_default = $defaults->{ $cf_name };
        my $cf_replace = $replace_with{ $cf_name };

        diag "goto ${queue}' create page and check fields' defaults" if $ENV{'TEST_VERBOSE'};
        {
            $agent->goto_create_rtir_ticket( $queue );
            my $input = $agent->custom_field_input( $queue, $cf_name );
            ok $input, 'found input for the field';
            is $agent->value($input), $cf_default, "correct value";
        }

        diag "create a ticket in ${queue} queue and check fields' values" if $ENV{'TEST_VERBOSE'};
        {
            my $id = $agent->create_rtir_ticket_ok(
                $queue,
                {
                    Subject => "test",
                    ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ),
                },
            );
            $incident_id = $id if $queue eq 'Incidents';

            my $ticket = RT::Ticket->new( $RT::SystemUser );
            $ticket->Load( $id );
            ok( $ticket->id, 'loaded ticket' );
            is( $ticket->FirstCustomFieldValue($cf_name), $cf_default, 'correct value' );
        }

        diag "create a ticket in ${queue} queue and check fields' values" if $ENV{'TEST_VERBOSE'};
        {
            my $id = $agent->create_rtir_ticket_ok(
                $queue,
                {
                    Subject => "test",
                    ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ),
                },
                { $cf_name => $cf_replace }
            );
            $incident_id = $id if $queue eq 'Incidents';

            my $ticket = RT::Ticket->new( $RT::SystemUser );
            $ticket->Load( $id );
            ok( $ticket->id, 'loaded ticket' );
            is( $ticket->FirstCustomFieldValue($cf_name), $cf_replace, 'correct value' );
        }
    }
}


undef $agent;
done_testing;
