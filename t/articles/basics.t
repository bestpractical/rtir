#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

my $ir_id  = $agent->create_ir( {Subject => "looking for articles"});

$agent->display_ticket( $ir_id);

$agent->follow_link_ok({text => "Articles"}, "followed 'Articles' overview link");
$agent->title_like(qr/^Search for articles$/);

$agent->back();

$agent->follow_link_ok({text => "Create", url_regex => qr/Articles/, n => 1}, "followed new article link");

# RT 4.2.11 forward skip 'pick a class' if there's only one
if ($agent->content =~ /in class Templates/) {
    $agent->follow_link_ok({text => "in class Templates"}, "chose a class");
}

$agent->form_name("EditArticle");

my $article_name = "some article".rand();

$agent->field(Name => $article_name);
$agent->field(Summary => "this is a summary");
$agent->field('RefersTo-new' => "t:$ir_id");
$agent->submit();

is($agent->status, 200, "attempt to create succeeded");

$agent->display_ticket( $ir_id);

$agent->follow_link_ok({text => $article_name}, "back to article");
$agent->content_like( qr/this is a summary/, "found the summary of the article");

done_testing();
