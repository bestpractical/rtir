#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 50;

sub tempfile {
    require File::Temp;
    my ($fh, $filename) = File::Temp::tempfile( 'rtir_test_XXXX', SUFFIX => '.txt');
    die "couldn't create temp file" unless $fh;
    diag("Created test file '$filename'") if $ENV{TEST_VERBOSE};
    print $fh @_;
    close $fh;
    return $filename;
}

require "t/rtir-test.pl";

my $agent = default_agent();

$agent->follow_link_ok({text => 'Incident Reports'}, "go to 'Incident Reports'");
$agent->follow_link_ok({text => 'New Report'}, "go to 'New Report'");

# let's try to create new IR with one attachment
{
    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Subject', 'ticket with attachment');
    $agent->field('Attachment', $filename);
    $agent->click('Create');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");
    my $attachment_link = $agent->find_link(
        tag       => 'a',
        url_regex => qr/\Q$filename/,
        text      => "Download $filename",
    );
    ok($attachment_link, "has link to attachment");

    SKIP: {
        skip "Inlined attachments are disabled", 1 if RT->Config->Get('MaxInlineBody')
                                                      && RT->Config->Get('MaxInlineBody') < 2*length($content);
        $agent->content_like( qr/\Q$content/, "text were inlined");
    }
    unlink $filename or die "couldn't delete file '$filename': $!";
}

$agent->follow_link_ok({text => 'Incident Reports'}, "go to 'Incident Reports'");
$agent->follow_link_ok({text => 'New Report'}, "go to 'New Report'");

# let's try to create new IR with two different attachments
{
    my $content1 = "this is test";
    my $content2 = "this is another test";

    my $fn1 = tempfile($content1);
    my $fn2 = tempfile($content2);

    $agent->form_number(3);
    $agent->field('Subject', 'ticket with attachments');
    $agent->field('Attachment', $fn1);
    $agent->click('AddAttachment');
    is($agent->status, 200, "request successful");

    $agent->form_number(3);
    is($agent->value('Subject'), 'ticket with attachments', "subject we put is there");
    $agent->field('Attachment', $fn2);
    $agent->click('Create');
    is($agent->status, 200, "request successful");

    $agent->content_like( qr/\Q$fn1/, "has file name on the page");
    $agent->content_like( qr/\Q$fn2/, "has file name on the page");
    $agent->content_like( qr/ticket with attachments/, "subject is there");

    my @links = $agent->find_all_links(
        tag        => 'a',
        url_regex  => qr/(?:\Q$fn1\E|\Q$fn2\E)/,
        text_regex => qr/Download (?:\Q$fn1\E|\Q$fn2\E)/,
    );
    is( scalar @links, 2, "has link to two attachments");
    unlink $fn1 or die "couldn't delete file '$fn1': $!";
    unlink $fn2 or die "couldn't delete file '$fn2': $!";
}

$agent->follow_link_ok({text => 'Incident Reports'}, "go to 'Incident Reports'");
$agent->follow_link_ok({text => 'New Report'}, "go to 'New Report'");

# let's try to create new IR
# and add then delete attachment to see that it works as expected
{
    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Subject', 'ticket with attachment');
    $agent->field('Attachment', $filename);
    $agent->click('AddAttachment');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");

    $agent->form_number(3);
    $agent->field('DeleteAttachments', $filename);
    $agent->click('AddAttachment');
    is($agent->status, 200, "request successful");

    $agent->form_number(3);
    $agent->click('Create');
    is($agent->status, 200, "request successful");

    my $attachment_link = $agent->find_link(
        tag       => 'a',
        url_regex => qr/\Q$filename/,
        text      => "Download $filename",
    );
    ok(!$attachment_link, "no link to attachment");

    unlink $filename or die "couldn't delete file '$filename': $!";
}

$agent->follow_link_ok({text => 'Incidents'}, "go to 'Incidents'");
$agent->follow_link_ok({text => 'New Incident'}, "go to 'New Incident'");

# let's try add attachment on Inc create page
{
    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Attachment', $filename);
    $agent->click('AddAttachment');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");
    $agent->form_number(3);
    ok($agent->value('CreateIncident'), "we still on the create page");
    unlink $filename or die "couldn't delete file '$filename': $!";
}

$agent->follow_link_ok({text => 'Investigations'}, "go to 'Investigations'");
$agent->follow_link_ok({text => 'New Investigation'}, "go to 'New Investigation'");

# let's try add attachment on Inv create page
{
    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Attachment', $filename);
    $agent->click('AddAttachment');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");
    $agent->form_number(3);
    ok($agent->value('Create'), "we still on the create page");
    unlink $filename or die "couldn't delete file '$filename': $!";
}

SKIP: {
    skip "Blocks queue is disabled", 5 if RT->Config->Get('DisableBlocksQueue');

    $agent->follow_link_ok({text => 'Blocks'}, "go to 'Blocks'");
    $agent->follow_link_ok({text => 'New Block'}, "go to 'New Block'");

    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Attachment', $filename);
    $agent->click('AddAttachment');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");
    $agent->form_number(3);
    ok($agent->value('Create'), "we still on the create page");
    unlink $filename or die "couldn't delete file '$filename': $!";
}

# let's check reply page
{
    my $tid = create_ir($agent, {Subject => "IR #xxx"});
    display_ticket($agent, $tid);
    $agent->follow_link_ok({text => 'Reply'}, "go to 'Reply'");

    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Attachment', $filename);
    $agent->click('AddAttachment');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");

    $agent->form_number(3);
    ok($agent->value('SubmitTicket'), "we still on the create page");
    
    # ok let's try put attachment with empty reply
    $agent->click('SubmitTicket');
    is($agent->status, 200, "request successful");
    my $attachment_link = $agent->find_link(
        tag       => 'a',
        url_regex => qr/\Q$filename/,
        text      => "Download $filename",
    );
    ok($attachment_link, "has link to attachment");

    unlink $filename or die "couldn't delete file '$filename': $!";
}

