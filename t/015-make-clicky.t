#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 33;

RT::Test->started_ok;
my $agent = default_agent();

my $rtir_user = RT::CurrentUser->new( rtir_user() );

my %clicky = map { lc $_ => 1 } RT->Config->Get('Active_MakeClicky');

diag "clicky ip" if $ENV{'TEST_VERBOSE'};
{
    my $id = $agent->create_ir( { Subject => 'clicky ip', Content => '1.0.0.0' } );
    $agent->display_ticket( $id);
    my @links = $agent->followable_links;
    if ( $clicky{'ip'} ) {
        my ($lookup_link) = grep lc $_->text eq 'lookup ip', @links;
        ok($lookup_link, "found link");
        ok($lookup_link->url =~ /(?<!\d)1\.0\.0\.0(?!\d)/, 'url has an ip' );
    } else {
        ok(!grep( lc $_->text eq 'lookup ip', @links ), "not found link");
    }

    $id = $agent->create_ir( { Subject => 'clicky ip', Content => '255.255.255.255' } );
    $agent->display_ticket( $id);
    @links = $agent->followable_links;
    if ( $clicky{'ip'} ) {
        my ($lookup_link) = grep lc $_->text eq 'lookup ip', @links;
        ok($lookup_link, "found link");
        ok($lookup_link->url =~ /(?<!\d)255\.255\.255\.255(?!\d)/, 'url has an ip' );
    } else {
        ok(!grep( lc $_->text eq 'lookup ip', @links ), "not found link");
    }

    $id = $agent->create_ir( { Subject => 'clicky ip', Content => '255.255.255.256' } );
    $agent->display_ticket( $id);
    @links = $agent->followable_links;
    ok(!grep( lc $_->text eq 'lookup ip', @links ), "not found link");

    $id = $agent->create_ir( { Subject => 'clicky ip', Content => '355.255.255.255' } );
    $agent->display_ticket( $id);
    @links = $agent->followable_links;
    ok(!grep( lc $_->text eq 'lookup ip', @links ), "not found link");
}

