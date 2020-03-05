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
    $agent->follow_link_ok( { text => "Articles", url_regex => qr{/Articles/index\.html} },
        "followed 'Articles' overview link" );
    $agent->follow_link_ok( { text => "Templates", url_regex => qr{Article/Edit\.html} },
        "followed new article link" );

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

# TODO: Once incident+investigation creation is re-added, this should be put back
#foreach my $q_name ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
foreach my $q_name ( 'Incident Reports', 'Investigations', 'Countermeasures' ) {
    note( "testing article in '$q_name' ticket create" );

    my $queue = RT::Queue->new(RT->SystemUser);
    $queue->Load( $q_name );
    ok $agent->goto_create_ticket( $queue ), "UI -> create ticket";

    my $content_name = $queue->Name eq 'Incidents'? 'InvestigationContent': 'Content';
    my $prefix = $queue->Name eq 'Incidents'? 'InvestigationContent-': '';

    $agent->form_name('TicketCreate');
    like( $agent->field( $content_name ), qr/^\s*$/ );
    $agent->content_contains( $article_name, 'got article in dropdown' );
}


undef $agent;
done_testing;
