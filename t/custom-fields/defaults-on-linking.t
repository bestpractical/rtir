#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 25;

my $cf_name = 'test';
{
    my $cf = RT::CustomField->new( $RT::SystemUser );
    my ($id, $status) = $cf->Create(
        Name       => $cf_name,
        LookupType => 'RT::Queue-RT::Ticket', 
        Type       => 'FreeformSingle',
    );

    for my $q ('Incident Reports', 'Investigation', 'Incidents', 'Blocks') {
        my $q_obj = RT::Queue->new($RT::SystemUser);
        $q_obj->Load($q);
        unless ( $q_obj->Id ) {
            $RT::Logger->error("Could not find queue ". $q );
            next;
        }
        my $OCF = RT::ObjectCustomField->new($RT::SystemUser);
        my ($status, $msg) = $OCF->Create(
            CustomField => $cf->id,
            ObjectId    => $q_obj->id,
        );
        $RT::Logger->error( $msg ) unless $status and $OCF->Id;
    }

    RT::IR::Test->add_rights( Principal => 'everyone', Right => ['SeeCustomField', 'ModifyCustomField']);
}


RT::Test->started_ok;
my $agent = default_agent();

{
    my $ir_id;
    {
        $ir_id = $agent->create_rtir_ticket_ok(
            'Incident Reports',
            { Subject => "test" },
            { $cf_name => 'cf value'},
        );

        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $ir_id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue($cf_name), 'cf value', 'correct value' );
    }

    {
        $agent->display_ticket( $ir_id );
        $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link")
            or diag $agent->content;
        $agent->form_number(3);

        my $input = $agent->custom_field_input( 'Incidents', $cf_name );
        ok $input, 'found input for the field';
        is $agent->value($input), 'cf value', "correct value";
    }

    my $inc_id;
    {
        $inc_id = $agent->create_incident_for_ir( $ir_id );
        
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $inc_id );
        ok( $ticket->id, 'loaded ticket' );
        is( $ticket->FirstCustomFieldValue($cf_name), 'cf value', 'correct value' );
    }
}


