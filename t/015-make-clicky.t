#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

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
        my ($lookup_link) = grep lc($_->text||'') eq 'lookup ip', @links;
        ok($lookup_link, "found link");
        ok($lookup_link->url =~ /(?<!\d)1\.0\.0\.0(?!\d)/, 'url has an ip' );
    } else {
        ok(!grep( lc $_->text eq 'lookup ip', @links ), "not found link");
    }

    $id = $agent->create_ir( { Subject => 'clicky ip', Content => '255.255.255.255' } );
    $agent->display_ticket( $id);
    @links = $agent->followable_links;
    if ( $clicky{'ip'} ) {
        my ($lookup_link) = grep lc($_->text||'') eq 'lookup ip', @links;
        ok($lookup_link, "found link");
        ok($lookup_link->url =~ /(?<!\d)255\.255\.255\.255(?!\d)/, 'url has an ip' );
    } else {
        ok(!grep( lc $_->text eq 'lookup ip', @links ), "not found link");
    }

    $id = $agent->create_ir( { Subject => 'clicky ip', Content => '255.255.255.256' } );
    $agent->display_ticket( $id);
    @links = $agent->followable_links;
    ok(!grep( lc($_->text||'') eq 'lookup ip', @links ), "not found link");

    $id = $agent->create_ir( { Subject => 'clicky ip', Content => '355.255.255.255' } );
    $agent->display_ticket( $id);
    @links = $agent->followable_links;
    ok(!grep( lc($_->text||'') eq 'lookup ip', @links ), "not found link");
}

diag "clicky email" if $ENV{'TEST_VERBOSE'};
{

    for my $email (
        'foo@example.com',  'foo-bar+baz@example.me',
        'foo@example.mobi', 'foo@localhost.localhost',
      )
    {
        diag "test valid email $email" if $ENV{TEST_VERBOSE};
        my ( $name, $domain ) = split /@/, $email, 2;
        my $id =
          $agent->create_ir( { Subject => 'clicky email', Content => $email } );
        $agent->display_ticket($id);
        my $email_link = $agent->find_link( url_regex => qr/\Qq=$email\E/, text_regex => qr/\Qlookup email\E$/ );
        my $domain_link = $agent->find_link( text_regex => qr/^\Qlookup "$domain"\E$/i );
        $agent->save_content('/tmp/x.html');
        if ( $clicky{'email'} ) {
            ok( $email_link,                                   "found link $email_link" );
            ok( $email_link->url =~ /(?<!\w)\Qq=$email\E(?!\w)/, 'url '.$email_link->url.' has an email - '.$email );
            ok( $domain_link,                                    "found link" );
            ok( $domain_link->url =~ /(?<!\w)\Q$domain\E(?!\w)/, 'url has a domain' );
        }
        else {
            ok( !$email_link, "not found email link" );
            ok( !$domain_link, "not found domain link" );
        }

    }

    for my $email ( 'foo@example') {
        diag "test invalid email (invalid domain) $email" if $ENV{TEST_VERBOSE};

        my ( $name, $domain );
        if ($email =~ /^(.*)@(.*)$/) {
            ($name,$domain) = ($1,$2);
        }
        my $id = $agent->create_ir( { Subject => 'clicky email', Content => $email } );
        $agent->display_ticket($id);
        my $email_link = $agent->find_link( url_regex => qr/\Qq=$email\E/, text_regex => qr/\Qlookup email\E$/ );
        ok( !$email_link, "not found email link for $email" );
        my $domain_link = $agent->find_link( text_regex => qr/^\Qlookup "$domain"\E$/i );
        ok( !$domain_link, "not found domain link for $domain" );

    }


    for my $email ( '@example.com' ) {
        diag "test invalid email (no local part) $email" if $ENV{TEST_VERBOSE};

        my ( $name, $domain );
        if ($email =~ /^(.*)@(.*)$/) {
            ($name,$domain) = ($1,$2);
        }
        my $id = $agent->create_ir( { Subject => 'clicky email', Content => $email } );
        $agent->display_ticket($id);
        my $email_link = $agent->find_link( url_regex => qr/\Qq=$email\E/, text_regex => qr/\Qlookup email\E$/ );
        ok( !$email_link, "not found email link for $email" );
        my $domain_link = $agent->find_link( text_regex => qr/^\Qlookup "$domain"\E$/i );
        ok( $domain_link, "still found the bare domain for $domain" );
    }


}

diag "utf8 caching " if $ENV{'TEST_VERBOSE'};
{
    my $content = "snowman \N{U+2603}";
    my $id = $agent->create_ir( { Subject => 'utf-8 snowman caching', Content => $content } );
    $agent->display_ticket( $id);
    $agent->content_contains($content,"Found snowman");

}

undef $agent;
done_testing;

