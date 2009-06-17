#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 18;

RT::Test->started_ok;
my $agent = default_agent();

my $incident = $agent->create_incident( {Subject => 'Incident to test Block editing'});
my $block = $agent->create_block( {Incident => $incident});

$agent->goto_edit_block( $block);

$agent->content_unlike(qr{<option (?:value=.*)?>Use system default\(\)</option>}, "The option 'Use system default()' does not exist.");


sub goto_edit_block {
	my $agent = shift;
	my $id = shift;
	
	$agent->display_ticket( $id);
	
	$agent->follow_link_ok({text => 'Edit', n => '1'}, "Followed 'Edit' (block) link");
}
