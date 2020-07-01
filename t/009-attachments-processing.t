#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

sub tempfile {
    require File::Temp;
    my ($fh, $filename) = File::Temp::tempfile( 'rtir_test_XXXX', SUFFIX => '.txt');
    die "couldn't create temp file" unless $fh;
    diag("Created test file '$filename'") if $ENV{TEST_VERBOSE};
    print $fh @_;
    close $fh;
    return $filename;
}

$agent->goto_create_rtir_ticket('Incident Reports');

# let's try to create new IR with one attachment
{
    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Subject', 'ticket with attachment');
    $agent->field('Attach', $filename);
    $agent->click('Create');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");
    my $attachment_link = $agent->find_link(
        tag       => 'a',
        url_regex => qr/\Q$filename/,
        text_regex => qr/\Q$filename/,
    );
    ok($attachment_link, "has link to attachment");

    SKIP: {
        skip "Inlined attachments are disabled", 1 if RT->Config->Get('MaxInlineBody')
                                                      && RT->Config->Get('MaxInlineBody') < 2*length($content);
        $agent->content_like( qr/\Q$content/, "text were inlined");
    }
    unlink $filename or die "couldn't delete file '$filename': $!";
}

$agent->goto_create_rtir_ticket('Incident Reports');

# let's try to create new IR with two different attachments
{
    my $content1 = "this is test";
    my $content2 = "this is another test";

    my $fn1 = tempfile($content1);
    my $fn2 = tempfile($content2);

    $agent->form_number(3);
    $agent->field('Subject', 'ticket with attachments');
    $agent->field('Attach', $fn1);
    $agent->click('AddMoreAttach');
    is($agent->status, 200, "request successful");

    $agent->form_number(3);
    is($agent->value('Subject'), 'ticket with attachments', "subject we put is there");
    $agent->field('Attach', $fn2);
    $agent->click('Create');
    is($agent->status, 200, "request successful");

    $agent->content_like( qr/\Q$fn1/, "has file name on the page");
    $agent->content_like( qr/\Q$fn2/, "has file name on the page");
    $agent->content_like( qr/ticket with attachments/, "subject is there");

    my @links = $agent->find_all_links(
        tag        => 'a',
        url_regex  => qr/(?:\Q$fn1\E|\Q$fn2\E)/,
        text_regex => qr/(?:\Q$fn1\E|\Q$fn2\E)/,
    );
    is( scalar @links, 2, "has link to two attachments");
    unlink $fn1 or die "couldn't delete file '$fn1': $!";
    unlink $fn2 or die "couldn't delete file '$fn2': $!";
}

$agent->goto_create_rtir_ticket('Incident Reports');

SKIP: {
    skip "delete attach function is ajaxified, no checkbox anymore", 4;
# let's try to create new IR
# and add then delete attachment to see that it works as expected
{
    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Subject', 'ticket with attachment');
    $agent->field('Attach', $filename);
    $agent->click('AddMoreAttach');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");

    $agent->form_number(3);
    $agent->tick('DeleteAttach', $filename);
    $agent->click('AddMoreAttach');
    is($agent->status, 200, "request successful");

    $agent->form_number(3);
    $agent->click('Create');
    is($agent->status, 200, "request successful");

    my $attachment_link = $agent->find_link(
        tag       => 'a',
        url_regex => qr/\Q$filename/,
        text_regex => qr/\Q$filename/,
    );
    ok(!$attachment_link, "no link to attachment");

    unlink $filename or die "couldn't delete file '$filename': $!";
}
}

$agent->goto_create_rtir_ticket('Incidents');

# let's try add attachment on Inc create page
{
    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Attach', $filename);
    $agent->click('AddMoreAttach');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");
    $agent->form_number(3);
    ok($agent->value('CreateIncident'), "we still on the create page");
    unlink $filename or die "couldn't delete file '$filename': $!";
}

$agent->goto_create_rtir_ticket('Investigations');

# let's try add attachment on Inv create page
{
    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Attach', $filename);
    $agent->click('AddMoreAttach');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");
    $agent->form_number(3);
    ok($agent->value('Create'), "we still on the create page");
    unlink $filename or die "couldn't delete file '$filename': $!";
}

$agent->goto_create_rtir_ticket('Countermeasures');

{
    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Attach', $filename);
    $agent->click('AddMoreAttach');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");
    $agent->form_number(3);
    ok($agent->value('Create'), "we still on the create page");
    unlink $filename or die "couldn't delete file '$filename': $!";
}

# let's check reply page
{
    my $tid = $agent->create_ir( {Subject => "IR #xxx"});
    $agent->display_ticket( $tid);
    $agent->follow_link_ok({text => 'Reply'}, "go to 'Reply'");

    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Attach', $filename);
    $agent->click('AddMoreAttach');
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
        text_regex => qr/\Q$filename/,
    );
    ok($attachment_link, "has link to attachment");

    unlink $filename or die "couldn't delete file '$filename': $!";
}

# incident reply page, make sure attachments attached to all tickets
{

    my $inc_id = $agent->create_incident( {Subject => "ir1 for merging"} );
    my $ir1_id = $agent->create_ir( {Subject => "ir1 for merging", Incident => $inc_id} );
    my $ir2_id = $agent->create_ir( {Subject => "ir1 for merging", Incident => $inc_id} );

    $agent->display_ticket( $inc_id);
    $agent->follow_link_ok({text => 'Reply to Reporters'}, "go to 'Reply to Reporters'");
    $agent->content_contains( "<input type=\"checkbox\" name=\"SelectedReportsAll\" value=\"1\" checked=\"checked\"",
                              'Checkboxes checked for reply all');

    my $content = "this is test";
    my $filename = tempfile($content);
    $agent->form_number(3);
    $agent->field('Attach', $filename);
    $agent->click('AddMoreAttach');
    is($agent->status, 200, "request successful");
    $agent->content_like( qr/\Q$filename/, "has file name on the page");

    $agent->form_number(3);
    ok($agent->value('SubmitTicket'), "we still on the create page");
    $agent->click('SubmitTicket');
    is($agent->status, 200, "request successful");

    foreach my $tid ( $ir1_id, $ir2_id ) {
        $agent->display_ticket( $tid );
        my $attachment_link = $agent->find_link(
            tag       => 'a',
            url_regex => qr/\Q$filename/,
            text_regex => qr/\Q$filename/,
        );
        ok($attachment_link, "has link to attachment");
    }

    unlink $filename or die "couldn't delete file '$filename': $!";
}

undef $agent;
done_testing;
