#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 45;

require "t/rtir-test.pl";

my $agent = default_agent();

# Create some reports

my $rtir_user = rtir_user();

# We are testing that the reject and quick reject buttons both work
# both for IRs that you own and IRs that are unowned.  So we make four IRs to work with.
my @irs;
for( my $i = 0; $i < 4; $i++ ) {
    push @irs, create_ir($agent, { Subject => "for bulk reject \#$i" });
}

go_home($agent);

{
    $agent->follow_link_ok({ text => '[Bulk Reject]' }, "Followed 'bulk reject' link");

    $agent->form_number(2);
    $agent->tick('SelectedTickets', $irs[0]);
    $agent->tick('SelectedTickets', $irs[2]);
    $agent->click('BulkReject');
    ok_and_content_like($agent, qr{Ticket $irs[0]: State changed from new to rejected}, 'reject notice');
    ok_and_content_like($agent, qr{Ticket $irs[2]: State changed from new to rejected}, 'reject notice');

    $agent->form_number(2);
    ok($agent->value('BulkReject'), 'still on reject page');
}

{
    $agent->form_number(2);
    ok($agent->value('BulkRejectAndReturn'), 'has reject and return button');

    $agent->tick('SelectedTickets', $irs[1]);
    $agent->tick('SelectedTickets', $irs[3]);
    $agent->click('BulkRejectAndReturn');
    ok_and_content_like($agent, qr{Ticket $irs[1]: State changed from new to rejected}, 'reject notice');
    ok_and_content_like($agent, qr{Ticket $irs[3]: State changed from new to rejected}, 'reject notice');
    ok_and_content_like($agent, qr{New unlinked Incident Reports}, 'we on the main page');
}

foreach( @irs ) {
    ticket_state_is( $agent, $_, 'rejected', "Ticket #$_ is rejected" );
}
