#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 20;

RT::Test->started_ok;
my $agent = default_agent();

my $ir_id  = $agent->create_ir( {Subject => "looking for articles"});

$agent->display_ticket( $ir_id);

$agent->follow_link_ok({text => "Articles"}, "followed 'Articles' overview link");
$agent->title_like(qr/^Articles$/);

$agent->back();

$agent->follow_link_ok({text => "Create", url_regex => qr/Articles/}, "followed new article link");

$agent->follow_link_ok({text => "in class Templates"}, "chose a class");

$agent->form_name("EditArticle");

my $article_name = "some article".rand();

$agent->field(Name => $article_name);
$agent->field(Summary => "this is a summary");
$agent->submit();

is($agent->status, 200, "attempt to create succeeded");

like($agent->content, qr/Incident Report #\d+: looking for articles/, "back on IR page");

$agent->follow_link_ok({text => $article_name}, "back to article");
like($agent->content, qr/this is a summary/, "found the summary of the article");
