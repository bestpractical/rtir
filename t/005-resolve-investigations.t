#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 27;

RT::Test->started_ok;
my $agent = default_agent();

my $inv_id  = $agent->create_investigation( {Subject => "i want to quick-resolve this"});

$agent->display_ticket( $inv_id);

$agent->follow_link_ok({text => "Quick Resolve"}, "followed 'RTFM' overview link");
like($agent->content, qr/Status changed from \S*open\S* to \S*resolved\S*/, "it got resolved");

$inv_id = $agent->create_investigation( {Subject => "resolve me slower"});

$agent->display_ticket( $inv_id);

$agent->follow_link_ok({text => "Resolve"}, "Followed 'Resolve' link");

$agent->form_name("TicketUpdate");
$agent->field(UpdateContent => "why you are resolved");
$agent->click("SubmitTicket");

is ($agent->status, 200, "attempt to resolve inv succeeded");

like($agent->content, qr/Status changed from \S*open\S* to \S*resolved\S*/, "site says ticket got resolved");

$agent->follow_link_ok({text => "Open"}, "Followed 'open' link");
like($agent->content, qr/Status changed from \S*resolved\S* to \S*open\S*/, "site says ticket got re-opened");
