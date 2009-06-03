#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";
use RT::IR::Test tests => 19;

RT::Test->started_ok;
my $agent = default_agent();

my $ir_id  = create_ir($agent, {Subject => "looking for rtfm"});

display_ticket($agent, $ir_id);

$agent->follow_link_ok({text => "RTFM"}, "followed 'RTFM' overview link");
$agent->title_like(qr/Overview/);

$agent->back();

$agent->follow_link_ok({text => "New", url_regex => qr/RTFM/}, "followed new RTFM article link");

$agent->follow_link_ok({text => "in class Templates"}, "chose a class");

$agent->form_name("EditArticle");

my $article_name = "some article".rand();

$agent->field(Name => $article_name);
$agent->field(Summary => "this is a summary");
$agent->submit();

is($agent->status, 200, "attempt to create succeeded");

like($agent->content, qr/Incident Report #\d+: looking for rtfm/, "back on IR page");

$agent->follow_link_ok({text => $article_name}, "back to article");
like($agent->content, qr/this is a summary/, "found the summary of the article");
