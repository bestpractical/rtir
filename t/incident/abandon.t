#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 55;

RT::Test->started_ok;
my $agent = default_agent();

diag "abandon unlinked incident" if $ENV{'TEST_VERBOSE'};
{
    my $id = $agent->create_incident( { Subject => "test" } );
    $agent->follow_link( text => 'Abandon' );
    $agent->content_like(qr/Warning: no recipients!/mi, 'no recipients warning on the page');
    $agent->form_number(3);
    $agent->click('SubmitTicket');
    is $agent->ticket_status( $id), 'abandoned', 'abandoned incident';
}

diag "abandon unlinked incident, but enter a message during abandoning" if $ENV{'TEST_VERBOSE'};
{
    my $id = $agent->create_incident( { Subject => "test" } );
    $agent->follow_link( text => 'Abandon' );
    $agent->content_like(qr/Warning: no recipients!/mi, 'no recipients warning on the page');
    $agent->form_number(3);
    $agent->field( UpdateContent => 'abandoning' );
    $agent->click('SubmitTicket');
    is $agent->ticket_status( $id), 'abandoned', 'abandoned incident';
}

diag "simple abandon incident with IR" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( { Subject => "test" } );
    my $ir_id = $agent->create_ir( { Subject => "test", Incident => $inc_id } );
    $agent->goto_ticket( $inc_id );
    $agent->follow_link( text => 'Abandon' );
    $agent->content_unlike(qr/Warning: no recipients!/mi, 'have no "no recipients" warning on the page');
    $agent->form_number(3);
    $agent->click('SubmitTicket');
    is $agent->ticket_status( $inc_id), 'abandoned', 'abandoned incident';
    is $agent->ticket_status( $ir_id), 'rejected', 'rejected ir';
}

diag "abandon incident with resolved IR" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( { Subject => "test" } );
    my $ir_id = $agent->create_ir( { Subject => "test", Incident => $inc_id } );
    $agent->follow_link( text => 'Quick Resolve' );
    is $agent->ticket_status( $ir_id), 'resolved', 'resolved ir';
    $agent->goto_ticket( $inc_id );
    $agent->follow_link( text => 'Abandon' );
    $agent->form_number(3);
    $agent->click('SubmitTicket');
    is $agent->ticket_status( $inc_id), 'abandoned', 'abandoned incident';
    is $agent->ticket_status( $ir_id), 'resolved', 'resolved ir';
}



