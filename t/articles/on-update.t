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
    $agent->get_ok('/', "followed 'Articles' overview link");
    $agent->follow_link_ok({text => "Articles"}, "followed 'Articles' overview link");
    $agent->follow_link_ok({text => "New Article" }, "followed new article link");
    if ($agent->content =~ /in class Templates/) { 
        $agent->follow_link_ok({text => "in class Templates"}, "chose a class");
    }

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
foreach my $queue ( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
    my $id = $agent->create_rtir_ticket_ok(
        $queue,
        {
            Subject => "test",
            ( $queue eq 'Blocks' ? ( Incident => $incident_id ) : () ),
        },
    );
    $incident_id = $id if $queue eq 'Incidents';

    my $reply_text = $queue eq 'Incidents'? 'Reply to Reporters' : 'Reply';

    $agent->follow_link_ok({text => "$reply_text"}, "followed '$reply_text' link");
    $agent->form_name('TicketUpdate');
    is( $agent->field('UpdateContent'), '' );
    $agent->field('Articles-Include-Article-Named' => $article_name);
    $agent->click('Go');
    $agent->form_name('TicketUpdate');
    like( $agent->field('UpdateContent'), qr/this is a content/ );

    $agent->goto_ticket( $id );
    $agent->follow_link_ok({text => "$reply_text"}, "followed '$reply_text' link");
    $agent->form_name('TicketUpdate');
    is( $agent->field('UpdateContent'), '' );
    $agent->select('Articles-Include-Article-Named-Hotlist' => $article_id);
    $agent->click('Go');
    $agent->form_name('TicketUpdate');
    like( $agent->field('UpdateContent'), qr/this is a content/ );

    $agent->goto_ticket( $id );
    $agent->follow_link_ok({text => "$reply_text"}, "followed '$reply_text' link");
    $agent->form_name('TicketUpdate');
    is( $agent->field('UpdateContent'), '' );
    $agent->field('Articles_Content' => $article_name);
    $agent->click('Go');
    $agent->form_name('TicketUpdate');
    is( $agent->field('UpdateContent'), '' );
    $agent->click('Articles-Include-Article-'. $article_id);
    $agent->form_name('TicketUpdate');
    like( $agent->field('UpdateContent'), qr/this is a content/ );
}

undef $agent;
done_testing;
