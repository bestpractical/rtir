#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

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

my $incident_id;
foreach my $queue ( 'Incidents', 'Incident Reports', 'Investigations', 'Countermeasures' ) {
    note( "testing article in '$queue' ticket update" );

    my $id = $agent->create_rtir_ticket_ok(
        $queue,
        {
            Subject => "test",
            ( $queue eq 'Countermeasures' ? ( Incident => $incident_id ) : () ),
        },
    );
    $incident_id = $id if $queue eq 'Incidents';

    my $reply_text = $queue eq 'Incidents'? 'Reply to Reporters' : 'Reply';

    $agent->follow_link_ok({text => "$reply_text"}, "followed '$reply_text' link");
    $agent->form_name('TicketUpdate');
    like( $agent->field('UpdateContent'), qr/^\s*$/ );
    $agent->content_contains( $article_name, 'got article in dropdown' );
}

done_testing;
