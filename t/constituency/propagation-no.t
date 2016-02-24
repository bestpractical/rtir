#!/usr/bin/perl

use strict;
use warnings;

use Test::More skip_all => 'constituencies being rebuilt';
use RT::IR::Test tests => undef;

use_ok('RT::IR');
RT->Config->Set('_RTIR_Constituency_Propagation' => 'no');

my $cf;
diag "load the field" if $ENV{'TEST_VERBOSE'};
{
    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => 'Constituency', CASESENSITIVE => 0 );
    $cf = $cfs->First;
    ok $cf, 'have a field';
    ok $cf->id, 'with some ID';
}

RT::Test->started_ok;
my $agent = default_agent();
my $rtir_user = rtir_user();

diag "create an incident with EDUNET and then linked tickets with GOVNET,"
    . " constituency shouldn't propagate back to tickets"
    if $ENV{'TEST_VERBOSE'};
{
    my $incident_id = $agent->create_rtir_ticket_ok(
        'Incidents',
        { Subject => "test" },
        { Constituency => 'EDUNET' },
    );
    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $incident_id );
        ok $ticket->id, 'loaded ticket';
        is $ticket->FirstCustomFieldValue('Constituency'),
            'EDUNET', 'correct value';
    }

    foreach my $queue( 'Incident Reports', 'Investigations', 'Countermeasures' ) {
        diag "create a ticket in the '$queue' queue" if $ENV{'TEST_VERBOSE'};

        my $id = $agent->create_rtir_ticket_ok(
            $queue,
            {
                Subject => "test ip",
                Incident => $incident_id,
            },
            { Constituency => 'GOVNET' },
        );

        $agent->display_ticket( $id);
        $agent->content_like( qr/GOVNET/i, "value on the page" );
        DBIx::SearchBuilder::Record::Cachable::FlushCache();
        
        {
            my $ticket = RT::Ticket->new( $RT::SystemUser );
            $ticket->Load( $id );
            ok $ticket->id, 'loaded ticket';
            is uc $ticket->FirstCustomFieldValue('Constituency'),
                'GOVNET', 'correct value';
        } {
            my $ticket = RT::Ticket->new( $RT::SystemUser );
            $ticket->Load( $incident_id );
            ok $ticket->id, 'loaded ticket';
            is $ticket->FirstCustomFieldValue('Constituency'),
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
            is uc $ticket->FirstCustomFieldValue('Constituency'),
                'GOVNET', 'correct value';
        } {
            my $ticket = RT::Ticket->new( $RT::SystemUser );
            $ticket->Load( $incident_id );
            ok $ticket->id, 'loaded ticket';
            is $ticket->FirstCustomFieldValue('Constituency'),
                'EDUNET', 'incident still has the same value';
        }
    }
}

diag "create an IR with GOVNET constituency and create a new "
    . "incident for the IR, we want it to inherit"
        if $ENV{'TEST_VERBOSE'};
{
    my $ir_id = $agent->create_ir(
        { Subject => "test" }, { Constituency => 'GOVNET' }
    );
    ok $ir_id, "created IR #$ir_id";
    $agent->display_ticket( $ir_id);

    my $inc_id = $agent->create_incident_for_ir(
        $ir_id, { Subject => "test" },
    );

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok $ticket->id, 'loaded ticket';
    is uc $ticket->FirstCustomFieldValue('Constituency'),
        'GOVNET', 'correct value';
}

diag "inheritance should be soft, so user can change constituency using ui"
        if $ENV{'TEST_VERBOSE'};
{
    my $ir_id = $agent->create_ir(
        { Subject => "test" }, { Constituency => 'GOVNET' }
    );
    ok $ir_id, "created IR #$ir_id";
    $agent->display_ticket( $ir_id);

    my $inc_id = $agent->create_incident_for_ir(
        $ir_id, { Subject => "test" }, { Constituency => 'EDUNET' }
    );

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $inc_id );
    ok $ticket->id, 'loaded ticket';
    is uc $ticket->FirstCustomFieldValue('Constituency'),
        'EDUNET', 'correct value';
}

diag "create an incident under GOVNET and create a new IR "
    ."linked to the incident with different constituency"
        if $ENV{'TEST_VERBOSE'};
{
    diag "first of all create the incident" if $ENV{'TEST_VERBOSE'};

    my $inc_id = $agent->create_incident(
        { Subject => "test" }, { Constituency => 'GOVNET' }
    );
    ok( $inc_id, "created ticket #$inc_id" );
    $agent->display_ticket( $inc_id );
    $agent->content_like( qr/GOVNET/, "value on the page" );
    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $inc_id );
        ok $ticket->id, 'loaded ticket';
        is uc $ticket->FirstCustomFieldValue('Constituency'),
            'GOVNET', 'correct value';
    }

    diag "then create the report" if $ENV{'TEST_VERBOSE'};
    my $ir_id = $agent->create_ir(
        { Subject => "test", Incident => $inc_id }, { Constituency => 'EDUNET' },
    );
    $agent->ticket_is_linked_to_inc( $ir_id => $inc_id );
    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $ir_id );
        ok $ticket->id, 'loaded ticket';
        is uc $ticket->FirstCustomFieldValue('Constituency'),
            'EDUNET', 'correct value';
    } {
        my $ticket = RT::Ticket->new( $RT::SystemUser );
        $ticket->Load( $inc_id );
        ok $ticket->id, 'loaded ticket';
        is uc $ticket->FirstCustomFieldValue('Constituency'),
            'GOVNET', 'correct value';
    }
}


undef $agent;
done_testing;
