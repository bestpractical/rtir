#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent     = default_agent();
my $rtir_user = rtir_user();

# create incident, incident report, investigation, and countermeasure
my $incident_id        = $agent->create_rtir_ticket_ok( 'Incidents',        { Subject => 'test incident' } );
my $incident_report_id = $agent->create_rtir_ticket_ok( 'Incident Reports', { Subject => 'test incident report' } );
my $investigation_id   = $agent->create_rtir_ticket_ok( 'Investigations',   { Subject => 'test investigation',  Requestors => $rtir_user->EmailAddress } );
my $countermeasure_id  = $agent->create_rtir_ticket_ok( 'Countermeasures',  { Subject => 'test countermeasure', Incident   => $incident_id } );

# link them as members of the incident
my $incident = RT::Ticket->new( RT->SystemUser );
$incident->Load( $incident_id );
ok( $incident->AddLink( Type => 'MemberOf', Base => $incident_report_id ), 'Linked Incident Report to Incident' );
ok( $incident->AddLink( Type => 'MemberOf', Base => $investigation_id   ), 'Linked Investigation to Incident'   );

# ensure the default portlets are visible in the incident ticket
$agent->display_ticket( $incident_id );
$agent->content_contains( 'tickets-list-report',         'Incident Reports portlet is visible on the Incident' );
$agent->content_contains( 'tickets-list-investigation',  'Investigations portlet is visible on the Incident'   );
$agent->content_contains( 'tickets-list-countermeasure', 'Countermeasures portlet is visible on the Incident'  );

# ensure they all show up on the incident page in their specific portlet
$agent->display_ticket( $incident_id );
is( $agent->dom->find( 'div.tickets-list-report .collection-as-table a' )->first->attr('href'),
    "/Ticket/Display.html?id=$incident_report_id",
    'Incident Report portlet contains link to Incident Report' );
is( $agent->dom->find( 'div.tickets-list-investigation .collection-as-table a' )->first->attr('href'),
    "/Ticket/Display.html?id=$investigation_id",
    'Investigation portlet contains link to Investigation' );
is( $agent->dom->find( 'div.tickets-list-countermeasure .collection-as-table a' )->first->attr('href'),
    "/Ticket/Display.html?id=$countermeasure_id",
    'Countermeasure portlet contains link to Countermeasure' );

done_testing();
