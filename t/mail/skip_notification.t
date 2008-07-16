#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
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

RT->Config->Set( 'Plugins' => 'RT::FM', 'RT::IR' );
RT::InitPlugins();

RT::Test->set_mail_catcher;

my ($baseurl, $agent) = RT::Test->started_ok;
my $rtir_user = rtir_user();
$agent->login( rtir_test_user => 'rtir_test_pass' );

diag "create an IR and check that we have outgoing email";
{
    RT::Test->clean_caught_mails;

    my $email = $rtir_user->EmailAddress;

    my $id = create_ir( $agent, {
        Subject => "test", 
        Requestors => $email,
    } );
    ok $id, 'created a ticket #'. $id;


    my @mail = RT::Test->fetch_caught_mails;
    ok @mail, 'there are some outgoing emails';

    my $recipient_ok = 0;
    foreach my $mail ( @mail ) {
        next unless $mail =~ /^(To|Cc|Bcc):\s*.*?\Q$email/mi;
        $recipient_ok = 1;
        last;
    }
    ok $recipient_ok, 'at least one email to requestor';
}

diag "create an IR and check that 'SkipNotification' feature works";
{
    RT::Test->clean_caught_mails;

    my $email = $rtir_user->EmailAddress;

    my $id = create_ir( $agent, {
        Subject          => "test", 
        Requestors       => $email,
        SkipNotification => 'Requestors',
    } );
    ok $id, 'created a ticket #'. $id;

    my @mail = RT::Test->fetch_caught_mails;

    my $recipient_ok = 1;
    foreach my $mail ( @mail ) {
        next unless $mail =~ /^(To|Cc|Bcc):\s*.*?\Q$email/mi;
        $recipient_ok = 0;
        last;
    }
    ok $recipient_ok, 'no emails to requestor';
}

