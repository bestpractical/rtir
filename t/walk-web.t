#!/usr/bin/perl

use strict;
use warnings;

use HTML::TreeBuilder;

use RT::IR::Test tests => 486;

RT::Test->started_ok;
my $m = default_agent();

my %viewed = ( '/NoAuth/Logout.html' => 1 );    # in case logout

my @tickets;
push @tickets, $m->create_incident({ Subject => "test Incident" });
push @tickets, $m->create_ir({ Subject => "test IR" });
push @tickets, $m->create_investigation({ Subject => "test Inv", Requestor => 'root@example.com' });
push @tickets, $m->create_block({ Subject => "test Block", Incident => $tickets[0] });

my @links = (
    '/RTIR/',
    (map "/RTIR/Display.html?id=$_", @tickets),
);

for my $link (@links) {
    test_page($m, $link);
}

$m->get_ok('/NoAuth/Logout.html');

sub test_page {
    my $m = shift;
    my $link = shift;
    $m->get_ok( $link, $link );
    $m->no_warnings_ok($link);

    my $tree = HTML::TreeBuilder->new();
    $tree->parse( $m->content );
    $tree->elementify;
    my ($top_menu)  = $tree->look_down( id => 'main-navigation' );
    my ($page_menu) = $tree->look_down( id => 'page-navigation' );

    my (@links) =
      grep { m{^/*RTIR/*} && /^[^#]/ && !$viewed{$_}++ }
      map { $_->attr('href') || () } ( $top_menu ? $top_menu->find('a') : () ),
      ( $page_menu ? $page_menu->find('a') : () );

    for my $link (@links) {
        test_page($m, $link);
    }
}

