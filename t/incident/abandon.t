#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 41;
require "t/rtir-test.pl";

use_ok('RT::IR');

my $agent = default_agent();

diag "abandon unlinked incident" if $ENV{'TEST_VERBOSE'};
{
    my $id = create_incident( $agent, { Subject => "test" } );
    $agent->follow_link( text => 'Abandon' );
    $agent->content_like(qr/Warning: no recipients!/mi, 'no recipients warning on the page');
    $agent->form_number(3);
    $agent->click('SubmitTicket');
    is ticket_state($agent, $id), 'abandoned', 'abandoned incident';
}

diag "abandon unlinked incident, but enter a message during abandoning" if $ENV{'TEST_VERBOSE'};
{
    my $id = create_incident( $agent, { Subject => "test" } );
    $agent->follow_link( text => 'Abandon' );
    $agent->content_like(qr/Warning: no recipients!/mi, 'no recipients warning on the page');
    $agent->form_number(3);
    $agent->field( UpdateContent => 'abandoning' );
    $agent->click('SubmitTicket');
    is ticket_state($agent, $id), 'abandoned', 'abandoned incident';
}

diag "simple abandon incident with IR" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = create_incident( $agent, { Subject => "test" } );
    my $ir_id = create_ir( $agent, { Subject => "test", Incident => $inc_id } );
    $agent->goto_ticket( $inc_id );
    $agent->follow_link( text => 'Abandon' );
    $agent->content_unlike(qr/Warning: no recipients!/mi, 'have no "no recipients" warning on the page');
    $agent->form_number(3);
    $agent->click('SubmitTicket');
    is ticket_state($agent, $inc_id), 'abandoned', 'abandoned incident';
    is ticket_state($agent, $ir_id), 'rejected', 'rejected ir';
}

diag "abandon incident with resolved IR" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = create_incident( $agent, { Subject => "test" } );
    my $ir_id = create_ir( $agent, { Subject => "test", Incident => $inc_id } );
    $agent->follow_link( text => 'Quick Resolve' );
    is ticket_state($agent, $ir_id), 'resolved', 'resolved ir';
    $agent->goto_ticket( $inc_id );
    $agent->follow_link( text => 'Abandon' );
    $agent->form_number(3);
    $agent->click('SubmitTicket');
    is ticket_state($agent, $inc_id), 'abandoned', 'abandoned incident';
    is ticket_state($agent, $ir_id), 'resolved', 'resolved ir';
}



