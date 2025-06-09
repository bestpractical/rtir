#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

diag "simple merge of IRs" if $ENV{'TEST_VERBOSE'};
{
    my $ir1_id = $agent->create_ir( {Subject => "ir1 for merging"});
    my $ir2_id = $agent->create_ir( {Subject => "ir2 for merging"});

    $agent->display_ticket( $ir2_id);
    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(3);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    $agent->ok_and_content_like( qr{Merge Successful}, 'Merge Successful');

    $agent->display_ticket( $ir1_id);
    $agent->ok_and_content_like( qr{Incident Report #$ir1_id:}, 'Opened the merged ticket');

    $agent->display_ticket( $ir2_id);
    $agent->ok_and_content_like( qr{Incident Report #$ir1_id:}, 'Second id points to the ticket we merged into');

}

diag "merge an IR into a linked IR, the product should have open state" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( {Subject => "base inc for merging"});
    my $ir1_id = $agent->create_ir( {Subject => "ir1 for merging", Incident => $inc_id});
    is($agent->status, 200, 'Created linked IR');
    ok( $agent->dom->at(".incidents [data-record-id=$inc_id]"), 'IR is linked correctly' );
    $agent->ticket_status_is( $ir1_id, 'open' );

    my $ir2_id = $agent->create_ir( {Subject => "ir2 for merging"});
    $agent->display_ticket( $ir2_id);

    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(3);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    $agent->ok_and_content_like( qr{Merge Successful}, 'Merge Successful');

    $agent->display_ticket( $ir1_id);
    $agent->ok_and_content_like( qr{Incident Report #$ir1_id:}, 'Opened the merged ticket');

    $agent->display_ticket( $ir2_id);
    $agent->ok_and_content_like( qr{Incident Report #$ir1_id:}, 'Second id points to the ticket we merged into');

    $agent->ticket_status_is( $ir2_id, 'open' );
}

diag "merge a linked IR into an IR, the product should have open state"
    if $ENV{'TEST_VERBOSE'};
{ # as previouse but with reversed merge operation
    my $ir1_id = $agent->create_ir( {Subject => "ir2 for merging"});

    my $inc_id = $agent->create_incident( {Subject => "base inc for merging"});
    my $ir2_id = $agent->create_ir( {Subject => "ir2 for merging", Incident => $inc_id});
    is($agent->status, 200, 'Created linked IR');
    ok( $agent->dom->at(".incidents [data-record-id=$inc_id]"), 'IR is linked correctly' );
    $agent->ticket_status_is( $ir2_id, 'open' );

    $agent->display_ticket( $ir2_id);

    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(3);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    $agent->ok_and_content_like( qr{Merge Successful}, 'Merge Successful');

    $agent->display_ticket( $ir2_id);
    $agent->ok_and_content_like( qr{Incident Report #$ir1_id:}, 'Second id points to the ticket we merged into');

    $agent->display_ticket( $ir1_id);
    $agent->ok_and_content_like( qr{Incident Report #$ir1_id:}, 'Opened the merged ticket');
    $agent->ticket_status_is( $ir1_id, 'open' );
}

diag "merge two IRs that are linked to different Incidents" if $ENV{'TEST_VERBOSE'};
{
    my $inc1_id = $agent->create_incident( {Subject => "base inc1 for merging"});
    my $ir1_id = $agent->create_ir( {Subject => "ir1 for merging", Incident => $inc1_id});

    my $inc2_id = $agent->create_incident( {Subject => "base inc2 for merging"});
    my $ir2_id = $agent->create_ir( {Subject => "ir2 for merging", Incident => $inc2_id});

    $agent->display_ticket( $ir2_id);

    $agent->has_tag('a', 'Merge', 'we have Merge link');
    $agent->follow_link_ok({ text => 'Merge' }, "Followed merge link");

    $agent->form_number(3);
    $agent->field('SelectedTicket', $ir1_id);
    $agent->submit;
    $agent->ok_and_content_like( qr{Merge Successful}, 'Merge Successful');

    $agent->ticket_is_linked_to_inc( $ir1_id, [$inc1_id, $inc2_id] );
}

undef $agent;
done_testing;
