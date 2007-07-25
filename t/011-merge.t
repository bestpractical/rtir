#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 116;

require "t/rtir-test.pl";

my $agent = default_agent();

diag "simple merge of IRs" if $ENV{'TEST_VERBOSE'};
{
    my $ir1_id = create_ir($agent, {Subject => "ir1 for merging"});
    my $ir2_id = create_ir($agent, {Subject => "ir2 for merging"});

    display_ticket($agent, $ir2_id);
    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(3);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    ok_and_content_like($agent, qr{Merge Successful}, 'Merge Successful');

    display_ticket($agent, $ir1_id);
    ok_and_content_like($agent, qr{Incident Report #$ir1_id:}, 'Opened the merged ticket');

    display_ticket($agent, $ir2_id);
    ok_and_content_like($agent, qr{Incident Report #$ir1_id:}, 'Second id points to the ticket we merged into');

}

diag "merge an IR into a linked IR, the product should have open state"
    if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = create_incident($agent, {Subject => "base inc for merging"});
    my $ir1_id = create_ir($agent, {Subject => "ir1 for merging", Incident => $inc_id});
    ok_and_content_like($agent, qr{Incident:.*$inc_id}ms, 'Created linked IR');
    ticket_state_is( $agent, $ir1_id, 'open' );

    my $ir2_id = create_ir($agent, {Subject => "ir2 for merging"});
    display_ticket($agent, $ir2_id);

    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(3);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    ok_and_content_like($agent, qr{Merge Successful}, 'Merge Successful');

    display_ticket($agent, $ir1_id);
    ok_and_content_like($agent, qr{Incident Report #$ir1_id:}, 'Opened the merged ticket');

    display_ticket($agent, $ir2_id);
    ok_and_content_like($agent, qr{Incident Report #$ir1_id:}, 'Second id points to the ticket we merged into');

    ticket_state_is( $agent, $ir2_id, 'open' );
}

{ # as previouse but with reversed merge operation
    my $ir1_id = create_ir($agent, {Subject => "ir2 for merging"});

    my $inc_id = create_incident($agent, {Subject => "base inc for merging"});
    my $ir2_id = create_ir($agent, {Subject => "ir2 for merging", Incident => $inc_id});
    ok_and_content_like($agent, qr{Incident:.*$inc_id}ms, 'Created linked IR');
    ticket_state_is( $agent, $ir2_id, 'open' );

    display_ticket($agent, $ir2_id);

    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(3);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    ok_and_content_like($agent, qr{Merge Successful}, 'Merge Successful');

    display_ticket($agent, $ir2_id);
    ok_and_content_like($agent, qr{Incident Report #$ir1_id:}, 'Second id points to the ticket we merged into');

    display_ticket($agent, $ir1_id);
    ok_and_content_like($agent, qr{Incident Report #$ir1_id:}, 'Opened the merged ticket');
    ticket_state_is( $agent, $ir1_id, 'open' );
}

{ # merge two IRs that are linked to different Incidents
    my $inc1_id = create_incident($agent, {Subject => "base inc1 for merging"});
    my $ir1_id = create_ir($agent, {Subject => "ir1 for merging", Incident => $inc1_id});

    my $inc2_id = create_incident($agent, {Subject => "base inc2 for merging"});
    my $ir2_id = create_ir($agent, {Subject => "ir2 for merging", Incident => $inc2_id});

    display_ticket($agent, $ir2_id);

    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(3);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    ok_and_content_like($agent, qr{Merge Successful}, 'Merge Successful');

    ticket_is_linked_to_inc( $agent, $ir1_id, [$inc1_id, $inc2_id] );
}
