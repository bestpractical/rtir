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
        ok($lookup_link, "Found link for IP address");
        ok($lookup_link->url =~ /(?<!\d)1\.0\.0\.0(?!\d)/, 'Found IP address in URL' );
    } else {
        ok(!grep( lc $_->text eq 'lookup ip', @links ), "Didn't find link for IP address");
    }

    $id = $agent->create_ir( { Subject => 'clicky ip', Content => '255.255.255.255' } );
    $agent->display_ticket( $id);
    @links = $agent->followable_links;
    if ( $clicky{'ip'} ) {
        my ($lookup_link) = grep lc($_->text||'') eq 'lookup ip', @links;
        ok($lookup_link, "Found link for IP address");
        ok($lookup_link->url =~ /(?<!\d)255\.255\.255\.255(?!\d)/, 'Found IP address in URL' );
    } else {
        ok(!grep( lc $_->text eq 'lookup ip', @links ), "Didn't find link for IP address");
    }

    $id = $agent->create_ir( { Subject => 'clicky ip', Content => '255.255.255.256' } );
    $agent->display_ticket( $id);
    @links = $agent->followable_links;
    ok(!grep( lc($_->text||'') eq 'lookup ip', @links ), "Didn't find link for IP address");

    $id = $agent->create_ir( { Subject => 'clicky ip', Content => '355.255.255.255' } );
    $agent->display_ticket( $id);
    @links = $agent->followable_links;
    ok(!grep( lc($_->text||'') eq 'lookup ip', @links ), "Didn't find link for IP address");
}

diag "clicky email" if $ENV{'TEST_VERBOSE'};
{

    for my $create_method_ref (
        sub { $agent->create_ir( $_[0] ) },
        sub { $agent->create_incident( $_[0] ) },
        sub { $agent->create_investigation( $_[0] ) },
        sub {
            $_[0]{Incident} = $agent->create_incident(@_);
            $agent->create_countermeasure( $_[0] );
        },
      )
    {
        for my $email (
            'foo@example.com',  'foo-bar+baz@example.me',
            'foo@example.mobi', 'foo@localhost.localhost',
            )
        {
            diag "test valid email $email" if $ENV{TEST_VERBOSE};
            my ( $name, $domain ) = split /@/, $email, 2;
            my $uri_escaped_email = $email;
            RT::Interface::Web::EscapeURI(\$uri_escaped_email);

            my $id =
              $create_method_ref->( { Subject => 'clicky email', Content => $email } );
            $agent->display_ticket($id);

            my $is_incident = $agent->text() =~ qr/Queue: Incidents/;

            my $email_link = $agent->find_link( url_regex => qr/\Qq=$email\E/, text_regex => qr/\Qlookup email\E$/ );
            my $domain_link = $agent->find_link( text_regex => qr/^\Qlookup "$domain"\E$/i );

            my $investigate_link = $agent->find_link( url_regex => qr/\QRequestors=$uri_escaped_email\E/,
                                                   text_regex => qr/^\Qinvestigate to\E$/i ) if $is_incident;

            if ( $clicky{'email'} ) {
                ok( $email_link,                                   "Found link for $email_link" );
                ok( $email_link->url =~ /(?<!\w)\Qq=$email\E(?!\w)/, 'URL link '.$email_link->url.' has an email address: '.$email );
                ok( $domain_link,                                    "Found link for URL domain" );
                ok( $domain_link->url =~ /(?<!\w)\Q$domain\E(?!\w)/, 'URL link has a domain' );

                # Test that 'Investigate to' links go to the queue selection page for creating incidents.
                # Then test that the new investigation form on that page loads the investigation creation page.
                # Then test taht the Correspondents field is populated with the given email address.
                if ( $is_incident ) {
                    ok( $investigate_link, "found investigate link" );
                    ok( $investigate_link->url =~ /(?<!\w)\QRequestors=$uri_escaped_email\E(?!\w)/,
                        'url '.$investigate_link->url.' has Requestors email' );
                    $agent->follow_link_ok( { url => $investigate_link->url }, 'followed "investigate to" link' );
                    $agent->title_is( 'Launch a new investigation', 'launching a new investigation' );
                    $agent->form_name( 'TicketCreate' );
                    my @correspondents = $agent->find_all_inputs(
                        name => 'Requestors',
                        type => 'text',
                        value => $email,
                    );
                    ok($correspondents[0], 'Found an email address');
                    is($correspondents[0]->value, $email, 'Email is correct: ' . $correspondents[0]->value);
                }
            }
            else {
                ok( !$email_link, "Didn't find link for email address" );
                ok( !$domain_link, "Didn't find link for domain" );
                ok( !$investigate_link, "Didn't find 'Investigate to' link") if $is_incident;
            }

        }

        for my $email ( 'foo@example') {
            diag "test invalid email (invalid domain) $email" if $ENV{TEST_VERBOSE};

            my ( $name, $domain );
            if ($email =~ /^(.*)@(.*)$/) {
                ($name,$domain) = ($1,$2);
            }
            my $id = $create_method_ref->( { Subject => 'clicky email', Content => $email } );
            $agent->display_ticket($id);
            my $is_incident = $agent->text() =~ qr/Queue: Incidents/;
            my $email_link = $agent->find_link( url_regex => qr/\Qq=$email\E/, text_regex => qr/\Qlookup email\E$/ );
            ok( !$email_link, "Didn't find an email link for $email" );
            my $domain_link = $agent->find_link( text_regex => qr/^\Qlookup "$domain"\E$/i );
            ok( !$domain_link, "Didn't find a domain link for $domain" );

            my $investigate_link = $agent->find_link( url_regex => qr/\QRequestors=$email\E/,
                                                      text_regex => qr/^\Qinvestigate to\E$/i )
                if $is_incident;
            ok( !$investigate_link, "Didn't find 'Investigate to' link for $email" );
        }

        for my $email ( '@example.com' ) {
            diag "test invalid email (no local part) $email" if $ENV{TEST_VERBOSE};

            my ( $name, $domain );
            if ($email =~ /^(.*)@(.*)$/) {
                ($name,$domain) = ($1,$2);
            }
            my $id = $create_method_ref->( { Subject => 'clicky email', Content => $email } );
            $agent->display_ticket($id);
            my $is_incident = $agent->text() =~ qr/Queue: Incidents/;
            my $email_link = $agent->find_link( url_regex => qr/\Qq=$email\E/, text_regex => qr/\Qlookup email\E$/ );
            ok( !$email_link, "Didn't find link for $email" );
            my $domain_link = $agent->find_link( text_regex => qr/^\Qlookup "$domain"\E$/i );
            ok( $domain_link, "Found the bare domain for $domain" );
            my $investigate_link = $agent->find_link( url_regex => qr/\QRequestors=$email\E/,
                                                      text_regex => qr/^\Qinvestigate to\E$/i )
                if $is_incident;
            ok( !$investigate_link, "Didn't find 'Investigate to' link for $email" );
        }
    }
}

diag "utf8 caching " if $ENV{'TEST_VERBOSE'};
{
    my $content = "snowman \N{U+2603}";
    my $id = $agent->create_ir( { Subject => 'utf-8 snowman caching', Content => $content } );
    $agent->display_ticket( $id);
    $agent->content_contains($content,"Found snowman");

}

done_testing;

