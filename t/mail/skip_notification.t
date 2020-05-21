#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

my ($baseurl) = RT::Test->started_ok;
my $agent = default_agent();
my $rtir_user = rtir_user();
$agent->login( rtir_test_user => 'rtir_test_pass' );

diag "create an IR and check that we have outgoing email";
{
    RT::Test->clean_caught_mails;

    my $email = $rtir_user->EmailAddress;

    my $id = $agent->create_ir( {
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

    my $id = $agent->create_ir( {
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

undef $agent;
done_testing;
