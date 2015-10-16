#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

my $incident = $agent->create_incident( {Subject => 'Incident to test Block editing'});
my $block = $agent->create_block( {Incident => $incident});

$agent->goto_edit_block( $block);

$agent->content_unlike(qr{<option (?:value=.*)?>Use system default\(\)</option>}, "The option 'Use system default()' does not exist.");

undef $agent;
done_testing();
