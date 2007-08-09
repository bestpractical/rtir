#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

require "t/rtir-test.pl";

# XXX: we should use new RT::Test features and start server with
# option we want.
if ( RT->Config->Get('_RTIR_Constituency_Propagation') eq 'no' ) {
    plan tests => 180;
} else {
    plan skip_all => 'constituency propagation algorithm is not "no"';
}

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

diag "create an incident with EDUNET and linked tickets with GOVNET"
    . " constituency shouldn't propagate back to tickets"
    if $ENV{'TEST_VERBOSE'};
{
    my $incident_id = create_rtir_ticket(
        $agent, 'Incidents',
        { Subject => "test" },
        { Constituency => 'EDUNET' },
    );
    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $incident_id );
        ok $ticket->id, 'loaded ticket';
        is $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
            'EDUNET', 'correct value';
    }

    foreach my $queue( 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $id = create_rtir_ticket(
            $agent, $queue,
            {
                Subject => "test ip",
                Incident => $incident_id,
            },
            { Constituency => 'GOVNET' },
        );

        display_ticket($agent, $id);
        $agent->content_like( qr/GOVNET/i, "value on the page" );
        DBIx::SearchBuilder::Record::Cachable::FlushCache();
        
        {
            my $ticket = RT::Ticket->new( $RT::SystemUser );
            $ticket->Load( $id );
            ok $ticket->id, 'loaded ticket';
            is uc $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
                'GOVNET', 'correct value';
        } {
            my $ticket = RT::Ticket->new( $RT::SystemUser );
            $ticket->Load( $incident_id );
            ok $ticket->id, 'loaded ticket';
            is $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
                'EDUNET', 'incident still has the same value';
        }

diag "check that if we edit value twice then incident's constituency is still the same"
    if $ENV{'TEST_VERBOSE'};

        $agent->follow_link( text => 'Edit' );
        $agent->form_number(3);
        $agent->select("Object-RT::Ticket-$id-CustomField-". $cf->id ."-Values" => 'EDUNET' ) or diag $agent->content;
        $agent->click('SaveChanges');
        $agent->content_like(qr/Constituency .* changed to EDUNET/mi, 'field is changed');

        $agent->follow_link( text => 'Edit' );
        $agent->form_number(3);
        $agent->select("Object-RT::Ticket-$id-CustomField-". $cf->id ."-Values" => 'GOVNET' );
        $agent->click('SaveChanges');
        $agent->content_like(qr/Constituency .* changed to GOVNET/mi, 'field is changed');

        DBIx::SearchBuilder::Record::Cachable::FlushCache();

        {
            my $ticket = RT::Ticket->new( $RT::SystemUser );
            $ticket->Load( $id );
            ok $ticket->id, 'loaded ticket';
            is uc $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
                'GOVNET', 'correct value';
        } {
            my $ticket = RT::Ticket->new( $RT::SystemUser );
            $ticket->Load( $incident_id );
            ok $ticket->id, 'loaded ticket';
            is $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
                'EDUNET', 'incident still has the same value';
        }
    }
}

diag "create an IR with GOVNET constituency and create a new "
    . "incident for the IR, we want it to inherit"
        if $ENV{'TEST_VERBOSE'};
{
    my $ir_id = create_ir(
        $agent, { Subject => "test" }, { Constituency => 'GOVNET' }
    );
    ok $ir_id, "created IR #$ir_id";
    display_ticket($agent, $ir_id);

    my $inc_id = create_incident_for_ir(
        $agent, $ir_id, { Subject => "test" },
    );

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok $ticket->id, 'loaded ticket';
    is uc $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
        'GOVNET', 'correct value';
}

diag "inheritance should be soft, so user can change constituency using ui"
        if $ENV{'TEST_VERBOSE'};
{
    my $ir_id = create_ir(
        $agent, { Subject => "test" }, { Constituency => 'GOVNET' }
    );
    ok $ir_id, "created IR #$ir_id";
    display_ticket($agent, $ir_id);

    my $inc_id = create_incident_for_ir(
        $agent, $ir_id, { Subject => "test" }, { Constituency => 'EDUNET' }
    );

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok $ticket->id, 'loaded ticket';
    is uc $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
        'EDUNET', 'correct value';
}

diag "create an incident under GOVNET and create a new IR "
    ."linked to the incident with different constituency"
        if $ENV{'TEST_VERBOSE'};
{
    diag "first of all create the incident" if $ENV{'TEST_VERBOSE'};

    my $inc_id = create_incident(
        $agent, { Subject => "test" }, { Constituency => 'GOVNET' }
    );
    ok( $inc_id, "created ticket #$inc_id" );
    display_ticket( $agent, $inc_id );
    $agent->content_like( qr/GOVNET/, "value on the page" );
    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $inc_id );
        ok $ticket->id, 'loaded ticket';
        is uc $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
            'GOVNET', 'correct value';
    }

    diag "then create the report" if $ENV{'TEST_VERBOSE'};
    my $ir_id = create_ir(
        $agent, { Subject => "test", Incident => $inc_id }, { Constituency => 'EDUNET' },
    );
    ticket_is_linked_to_inc( $agent, $ir_id => $inc_id );
    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $ir_id );
        ok $ticket->id, 'loaded ticket';
        is uc $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
            'EDUNET', 'correct value';
    } {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $inc_id );
        ok $ticket->id, 'loaded ticket';
        is uc $ticket->FirstCustomFieldValue('_RTIR_Constituency'),
            'GOVNET', 'correct value';
    }
}

