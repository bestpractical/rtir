use strict;

use Test::WWW::Mechanize;
use Test::More tests => 16;

require "rtir-test.pl";

my $agent = default_agent();

my $incident = create_incident($agent, {Subject => 'Incident to test Block editing'});
my $block = create_block($agent, {Incident => $incident});

goto_edit_block($agent, $block);

$agent->content_unlike(qr{<option (?:value=.*)?>Use system default\(\)</option>}, "The option 'Use system default()' does not exist.");


sub goto_edit_block {
	my $agent = shift;
	my $id = shift;
	
	display_ticket($agent, $id);
	
	$agent->follow_link_ok({text => 'Edit', n => '1'}, "Followed 'Edit' (block) link");
}
