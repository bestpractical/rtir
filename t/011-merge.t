#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan); #tests => 38;

require "t/rtir-test.pl";

my $agent = default_agent();

{ # simple merge of IRs
    my $ir1_id = create_ir($agent, {Subject => "ir1 for merging"});
    my $ir2_id = create_ir($agent, {Subject => "ir2 for merging"});
    display_ticket($agent, $ir2_id);

    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(2);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    ok_and_content_like($agent, qr{Merge Successful}, 'Merge Successful');

    display_ticket($agent, $ir1_id);
    ok_and_content_like($agent, qr{Incident Report #$ir2_id:}, 'Opened the merged ticket');

    display_ticket($agent, $ir2_id);
    ok_and_content_like($agent, qr{Incident Report #$ir2_id:}, 'Second id points to the ticket we merged into');
}

{ # merge an IR into a linked IR, the product should have open state
    my $inc_id = create_incident($agent, {Subject => "base inc for merging"});
    my $ir1_id = create_ir($agent, {Subject => "ir1 for merging", Incident => $inc_id});
    ok_and_content_like($agent, qr{Incident:.*$inc_id}ms, 'Created linked IR');
    ticket_state_is( $agent, $ir1_id, 'open' );

    my $ir2_id = create_ir($agent, {Subject => "ir2 for merging"});
    display_ticket($agent, $ir2_id);

    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(2);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    ok_and_content_like($agent, qr{Merge Successful}, 'Merge Successful');

    display_ticket($agent, $ir1_id);
    ok_and_content_like($agent, qr{Incident Report #$ir2_id:}, 'Opened the merged ticket');

    display_ticket($agent, $ir2_id);
    ok_and_content_like($agent, qr{Incident Report #$ir2_id:}, 'Second id points to the ticket we merged into');

    ticket_state_is( $agent, $ir2_id, 'open' );
}

{ # as previouse but with reversed merge operation
    my $ir1_id = create_ir($agent, {Subject => "ir2 for merging"});

    my $inc_id = create_incident($agent, {Subject => "base inc for merging"});
    my $ir2_id = create_ir($agent, {Subject => "ir1 for merging", Incident => $inc_id});
    ok_and_content_like($agent, qr{Incident:.*$inc_id}ms, 'Created linked IR');
    ticket_state_is( $agent, $ir2_id, 'open' );

    display_ticket($agent, $ir2_id);

    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(2);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    ok_and_content_like($agent, qr{Merge Successful}, 'Merge Successful');

    display_ticket($agent, $ir2_id);
    ok_and_content_like($agent, qr{Incident Report #$ir2_id:}, 'Second id points to the ticket we merged into');

    display_ticket($agent, $ir1_id);
    ok_and_content_like($agent, qr{Incident Report #$ir2_id:}, 'Opened the merged ticket');
    ticket_state_is( $agent, $ir1_id, 'open' );
}
