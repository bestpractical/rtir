#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

my $defaults = RT->Config->Get('RTIR_CustomFieldsDefaults');
$defaults->{'How Reported'}  = 'Telephone';   # IRs
$defaults->{'Description'}   = 'Bloody mess'; # Incs
$defaults->{'IP'}            = '127.0.0.1';   # Invs and all
$defaults->{'Where Blocked'} = 'On the Moon'; # Blocks

my %test_on = (
    'Incident Reports' => 'How Reported',
    'Incidents'        => 'Description',
    'Investigations'   => 'IP',
    'Blocks'           => 'Where Blocked',
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
    my $incident_id; # block couldn't be created without incident id
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
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
                    ( $queue eq 'Blocks' ? ( Incident => $incident_id ) : () ),
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
                    ( $queue eq 'Blocks' ? ( Incident => $incident_id ) : () ),
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


done_testing;
