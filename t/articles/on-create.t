#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT->Config->Set( ArticleOnTicketCreate => 1 );

RT::Test->started_ok;
my $agent = default_agent();

my $article_id = 1;
my $article_name = 'some article';

diag "create an article" if $ENV{'TEST_VERBOSE'};
{
    $agent->get_ok('/', "followed 'Articles' overview link");
    $agent->follow_link_ok({text => "Articles"}, "followed 'Articles' overview link");
    $agent->follow_link_ok({text => "New Article" }, "followed new article link");
    $agent->follow_link_ok({text => "in class Templates"}, "chose a class")
        if $agent->uri =~ /PreCreate/;

    my $cf = RT::CustomField->new( RT->SystemUser );
    $cf->Load('Response');
    ok($cf->id, 'found respone custom field');

    $agent->form_name("EditArticle");
    $agent->field(Name => $article_name);
    $agent->field(Summary => "this is a summary");
    $agent->field( 'Object-RT::Article--CustomField-'. $cf->id .'-Values' => 'this is a content' );
    $agent->submit;

    is($agent->status, 200, "attempt to create succeeded");
}

foreach ( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
    my $queue = RT::Queue->new(RT->SystemUser);
    $queue->Load( $_ );
    ok $agent->goto_create_ticket( $queue ), "UI -> create ticket";

    my $content_name = $queue->Name eq 'Incidents'? 'InvestigationContent': 'Content';
    my $prefix = $queue->Name eq 'Incidents'? 'InvestigationContent-': '';

    $agent->form_name('TicketCreate');
    is( $agent->field( $content_name ), '' );
    $agent->field($prefix.'Articles-Include-Article-Named' => $article_name);
    $agent->click('Go');
    $agent->form_name('TicketCreate');
    like( $agent->field( $content_name ), qr/this is a content/ );

    ok $agent->goto_create_ticket( $queue ), "UI -> create ticket";
    $agent->form_name('TicketCreate');
    is( $agent->field( $content_name ), '' );
    $agent->select($prefix .'Articles-Include-Article-Named-Hotlist' => $article_id);
    $agent->click('Go');
    $agent->form_name('TicketCreate');
    like( $agent->field( $content_name ), qr/this is a content/ );

    ok $agent->goto_create_ticket( $queue ), "UI -> create ticket";
    $agent->form_name('TicketCreate');
    is( $agent->field( $content_name ), '' );
    $agent->field($prefix .'Articles_Content' => $article_name);
    $agent->click('Go');
    $agent->form_name('TicketCreate');
    is( $agent->field( $content_name ), '' );
    $agent->click($prefix .'Articles-Include-Article-'. $article_id);
    $agent->form_name('TicketCreate');
    like( $agent->field( $content_name ), qr/this is a content/ );
}

undef $agent;
done_testing;
