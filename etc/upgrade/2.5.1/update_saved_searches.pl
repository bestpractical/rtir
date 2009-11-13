#!/usr/bin/env perl 
use strict;
use warnings;
use lib '/opt/rt/local/lib', '/opt/rt/3.8/lib';
use RT;
RT->LoadConfig;
RT->Init;

my %special_rename = (
    howreported => 'How Reported',
    resportertype => 'Reporter Type',
    whereblocked => 'Where Blocked',
);

my $saved_searches = RT::Attributes->new($RT::SystemUser);
$saved_searches->Limit( FIELD => 'Name', VALUE => 'SavedSearch' );
while ( my $s = $saved_searches->Next ) {
    my $content    = $s->Content;
    my $old_query  = $content->{Query};
    my $old_format = $content->{Format};
    my $special = join '|', keys %special_rename;
    foreach ( $content->{Query}, $content->{Format} ) {
        s/(?<=CF\.{)_RTIR_//ig;
        s/(?<=CustomField\.{)_RTIR_//ig;
        s/(?<=CF\.{)_RTIR_//ig;
        s/(?<=CustomField\.{)_RTIR_//ig;
        s/\b($special)\b/$special_rename{$1}/ige;
    }

    if ( $old_query ne $content->{Query} || $old_format ne $content->{Format} )
    {
        my ( $status, $msg ) = $s->SetContent($content);
        if ($status) {
            print 'update content of saved search ' . $s->Description . ' with
                success';
        }
        else {
            print 'failed to update content of saved search '
              . $s->Description
              . ": $msg";
        }
        print "\n";
    }
}

