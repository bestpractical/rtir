#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 59;
require "t/rtir-test.pl";

my ($baseurl, $m) = RT::Test->started_ok;
ok(my $user = RT::User->new($RT::SystemUser));
ok($user->Load('root'), "Loaded user 'root'");
$user->SetEmailAddress('recipient@example.com');

for my $usage (qw/signed encrypted signed&encrypted/)
{
    for my $format (qw/MIME inline/)
    {
        for my $attachment (qw/plain text-attachment binary-attachment/)
        {
            my $ok = run_test($usage, $format, $attachment);
            ok($ok, "$usage, $attachment email with $format key");
        }
    }
}

sub run_test
{
    my ($usage, $format, $attachment) = @_;

    my $mail = '...';

    my $mailgate = RT::Test->open_mailgate_ok($baseurl);
    print $mailgate <<EOF;
From: recipient\@example.com
To: general\@$RT::rtname
Subject: $usage, $attachment email with $format key

text goes here
EOF
    RT::Test->close_mailgate_ok($mailgate);
    return 0;
}

