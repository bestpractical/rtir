#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 17;

require "t/rtir-test.pl";

my $agent = default_agent();

# Create some reports

my $rtir_user = rtir_user();

# regression: split an inc, launch an inv on the new inc => the inv is linked
# to both incidents, which is wrong, should be linked to one only
{
    my $id = create_incident($agent, {Subject => "split incident"});
    display_ticket($agent, $id);
    $agent->follow_link_ok({text => "Split"}, "Followed link");
    $agent->form_number(3);
    $agent->click('CreateIncident');
    is ($agent->status, 200, "Attempted to create the ticket");
    my $new_id = ($agent->content =~ /.*Ticket (\d+) created.*/i )[0];
    ok ($new_id, "Ticket created successfully: #$new_id.");

    $agent->follow_link_ok({text => "Launch"}, "Followed link");
    $agent->form_number(3);
    $agent->field('Requestors', $rtir_user->EmailAddress);
    $agent->click('Create');
    
    is ($agent->status, 200, "Attempted to create the ticket");
    my $inv_id = ($agent->content =~ /.*Ticket (\d+) created.*/i )[0];
    ok ($inv_id, "Ticket created successfully: #$inv_id.");

    ticket_is_linked_to_inc($agent, $inv_id, [$new_id]);
    ticket_is_not_linked_to_inc($agent, $inv_id, [$id]);
}

