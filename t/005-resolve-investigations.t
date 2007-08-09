#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 20;

require "t/rtir-test.pl";

my $agent = default_agent();

my $inv_id  = create_investigation($agent, {Subject => "i want to quick-resolve this"});

display_ticket($agent, $inv_id);

$agent->follow_link_ok({text => "Quick Resolve"}, "followed 'RTFM' overview link");
like($agent->content, qr/State changed from open to resolved/, "it got resolved");

$inv_id = create_investigation($agent, {Subject => "resolve me slower"});

display_ticket($agent, $inv_id);

$agent->follow_link_ok({text => "Resolve"}, "Followed 'Resolve' link");

$agent->form_name("TicketUpdate");
$agent->field(UpdateContent => "why you are resolved");
$agent->click("SubmitTicket");

is ($agent->status, 200, "attempt to resolve inv succeeded");

like($agent->content, qr/State changed from open to resolved/, "site says ticket got resolved");

$agent->follow_link_ok({text => "Open"}, "Followed 'open' link");
like($agent->content, qr/State changed from resolved to open/, "site says ticket got re-opened");
