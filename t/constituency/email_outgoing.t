#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 55;
use File::Temp qw(tempdir);

use lib qw(/opt/rt3/local/lib /opt/rt3/lib);
require RT::Test; import RT::Test;
require "t/rtir-test.pl";

{
    $RT::Handle->InsertSchema(undef, '/opt/rt3/local/etc/FM');
    $RT::Handle->InsertACL(undef, '/opt/rt3/local/etc/FM');

    $RT::Handle = new RT::Handle;
    $RT::Handle->dbh( undef );
    RT->ConnectToDatabase;

    local @INC = ('/opt/rt3/local/etc', '/opt/rt3/etc', @INC);
    RT->Config->LoadConfig(File => "IR/RTIR_Config.pm");
    $RT::Handle->InsertData('IR/initialdata');

    $RT::Handle = new RT::Handle;
    $RT::Handle->dbh( undef );
    RT->ConnectToDatabase;
}

RT->Config->Set( '_RTIR_Constituency_default' => 'EDUNET' );

my $queue_ir = RT::Test->load_or_create_queue(
    Name              => 'Incident Reports',
    CorrespondAddress => 'reports@example.com',
    CommentAddress    => 'reports-comment@example.com',
);
ok $queue_ir && $queue_ir->id, 'loaded or created queue_ir';

my $queue_ir_edunet = RT::Test->load_or_create_queue(
    Name              => 'Incident Reports - EDUNET',
    CorrespondAddress => 'edu-reports@example.com',
    CommentAddress    => 'edu-reports-comment@example.com',
);
ok $queue_ir_edunet && $queue_ir_edunet->id, 'loaded or created queue';

RT::Test->set_mail_catcher;

my ($baseurl, $agent) = RT::Test->started_ok;
my $rtir_user = rtir_user();
$agent->login( rtir_test_user => 'rtir_test_pass' );

{
    unlink "t/mailbox";

        my $text = <<EOF;
From: @{[ $rtir_user->EmailAddress ]}
To: reports\@example.com
Subject: This is a test of constituency functionality

Foob!
EOF
    my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Incident Reports');
    is $status >> 8, 0, "The mail gateway exited ok";
    ok $id, "created ticket $id";

    display_ticket($agent, $id);
    $agent->content_like( qr/\QEDUNET/, "value on the page" );

    my @mail = RT::Test->fetch_caught_mails;
    ok @mail, 'there are some outgoing emails';
    
    my $from_ok = 1;
    foreach my $mail ( @mail ) {
        next if $mail =~ /^From:\s*.*?\Qedu-reports-comment\@example.com/mi;
        $from_ok = 0;
        last;
    }
    ok $from_ok, 'all From addresses are correct';
}

