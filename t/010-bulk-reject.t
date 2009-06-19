#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 50;

RT::Test->started_ok;
my $agent = default_agent();

# Create some reports

my $rtir_user = rtir_user();

# We are testing that the reject and quick reject buttons both work
# both for IRs that you own and IRs that are unowned.  So we make four IRs to work with.
my @irs;
for( my $i = 0; $i < 4; $i++ ) {
    push @irs, $agent->create_ir( { Subject => "for bulk reject \#$i" });
}

$agent->get_ok('/RTIR/index.html', 'open rtir at glance');
{
    $agent->follow_link_ok({ text => 'Bulk Reject' }, "Followed 'bulk reject' link");

	# Check that the desired incident report occurs in the list of available incident reports; if not, keep
	# going to the next page until you find it (or get to the last page and don't find it,
	# whichever comes first)
	
	# Note that this method assumes both IRs to be rejected are on the same page, but if they're not, we can't check both in any way.
    while($agent->content() !~ qr{<td class="collection-as-table">\s*<b>\s*<a href="/Ticket/Display.html?id=$irs[0]">$irs[0]</a>\s*</b>\s*</td>}) {
    	last unless $agent->follow_link(text => 'Next');
    }

    $agent->form_number(3);
    $agent->tick('SelectedTickets', $irs[0]);  
    $agent->tick('SelectedTickets', $irs[2]);
    $agent->click('BulkReject');
    $agent->ok_and_content_like( qr{Ticket $irs[0]: State changed from \w+ to rejected}, 'reject notice');
    $agent->ok_and_content_like( qr{Ticket $irs[2]: State changed from \w+ to rejected}, 'reject notice');

    $agent->form_number(3);
    ok($agent->value('BulkReject'), 'still on reject page');
}

{
	while($agent->content() !~ qr{<td class="collection-as-table">\s*<b>\s*<a href="/Ticket/Display.html?id=$irs[1]">$irs[1]</a>\s*</b>\s*</td>}) {
    	last unless $agent->follow_link(text => 'Next');
    }
	
    $agent->form_number(3);
    ok($agent->value('BulkRejectAndReturn'), 'has reject and return button');

    $agent->tick('SelectedTickets', $irs[1]);
    $agent->tick('SelectedTickets', $irs[3]);
    $agent->click('BulkRejectAndReturn');
    $agent->ok_and_content_like( qr{Ticket $irs[1]: State changed from new to rejected}, 'reject notice');
    $agent->ok_and_content_like( qr{Ticket $irs[3]: State changed from new to rejected}, 'reject notice');
    $agent->ok_and_content_like( qr{New unlinked Incident Reports}, 'we are on the main page');
}

foreach( @irs ) {
    $agent->ticket_state_is( $_, 'rejected', "Ticket #$_ is rejected" );
}
