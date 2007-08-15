#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 109;
use HTTP::Cookies;

require "t/rtir-test.pl";
use lib qw(/opt/rt3/local/lib /opt/rt3/lib);

my $agent = default_agent();

my $root = new RT::Test::Web;
$root->cookie_jar( HTTP::Cookies->new );
$root->login('root', 'password');

my $SUBJECT = "foo " . rand;

diag("Testing Incident Report locking");
# Create a report
my $report = create_ir($agent, {Subject => $SUBJECT, Content => "bla", Owner => 'Nobody in particular &#40;Nobody&#41;' });
    


my $ir_obj = RT::Ticket->new(RT::SystemUser());
my $lock;

$ir_obj->Load($report);
is($ir_obj->Id, $report, "report has right ID");
is($ir_obj->Subject, $SUBJECT, "subject is right");

#Hard lock
diag("Testing hard lock") if $ENV{'TEST_VERBOSE'};

$agent->goto_ticket($report);
$agent->follow_link_ok({text => 'Lock', n => '1'}, "Followed 'Lock' link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket\.}ims, "Added a hard lock on ticket $report");
$lock = $ir_obj->Locked();
ok(($lock->Content->{'Type'} eq 'Hard'), "Lock is a Hard lock");

###Testing lock expiration###
###Be sure to set LockExpiry to a short time (say, 30) in RT_SiteConfig.pm, or you'll be waiting
###for a while for this test to finish###

my $expire = RT->Config->Get('LockExpiry');

SKIP: {
    skip 'Not testing lock expiry--expiration feature turned off', 4 unless $expire;
    sleep $expire;

    $agent->follow_link_ok({text => 'Display', n =>'1'}, "Going back to display page for IR #$report");
    $agent->content_unlike(qr{<div class="locked-by-you">}, "IR #$report not locked anymore (lock expired)");
    ok(!$ir_obj->Locked(), "Lock not in the database");


    $agent->follow_link_ok({text => 'Lock', n => '1'}, "Followed 'Lock' link again");
}

sleep 5;    #Otherwise, we run the risk of getting "You have locked this ticket" (see /Elements/ShowLock)

###Testing Update.html locking###

$agent->follow_link_ok({text => 'Comment', n => '1'}, "Followed Comment link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have had this ticket locked for \d+}ims, "Comment page is locked");
$agent->form_number(3);
$agent->submit();
diag("Submitted Comment form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">}, "IR $report is still locked");

###Testing Edit.html locking###

$agent->follow_link_ok({text => 'Edit', n => '1'}, "Followed Edit link");

$agent->content_like(qr{<div class="locked-by-you">\s*You have had this ticket locked for \d+}ims, "Edit page is locked");
$agent->form_number(3);
$agent->submit();
diag("Submitted Edit form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">}, "IR $report is still locked");

$agent->follow_link_ok({text => 'Unlock', n => '1'}, "Unlocking IR $report");
$agent->content_like(qr{<div class="locked-by-you">\s*You had this ticket locked for \d+ \w+\. It is now unlocked\.}ims, "IR $report is not locked");
$agent->follow_link_ok({text => 'Lock', n => '1'}, "Followed 'Lock' link again");
sleep 5;    #Otherwise, we run the risk of getting "You have locked this ticket" (see /Elements/ShowLock)


###Testing Split.html locking###

$agent->follow_link_ok({text => 'Split', n => '1'}, "Followed Split link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have had this ticket locked for \d+}ims, "Split page is still locked");
$agent->form_number(3);
my $nobody;
if($agent->content =~ qr{<option.+?value="(\d+)"\s*>Nobody in particular &#40;Nobody&#41;</option>}ims) {
    $nobody = $1;
    $agent->field('Owner', $nobody);
}
$agent->click('Create');
diag("Submitted Split form") if $ENV{'TEST_VERBOSE'};
my $ir_id2;
if($agent->content =~ qr{<li>Ticket (\d+) created in queue.*</li>}i) {
    $ir_id2 = $1;
}
$agent->content_like(qr{<div class="locked-by-you">\s*You have had Ticket #$report locked for \d+ \w+\.}ims, "IR $report is still locked");

###Testing Merge.html locking###

display_ticket($agent, $report);
$agent->follow_link_ok({text => 'Merge', n => '1'}, "Followed Merge link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have had this ticket locked for \d+}ims, "Merge page is still locked");
$agent->form_number(3);

$agent->field("SelectedTicket", $ir_id2);
$agent->submit();
diag("Submitted Merge form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket\.}ims, "Lock from $report moved to $ir_id2");
$report = $ir_id2;
$agent->follow_link_ok({text => 'Unlock', n => '1'}, "Removing hard lock on IR $report");


#Auto lock
diag("Testing auto lock") if $ENV{'TEST_VERBOSE'};

###Testing Update.html locking###

$agent->follow_link_ok({text => 'Comment', n => '1'}, "Followed Comment link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket}ims, "Comment page is auto locked");
# Without this, the lock type doesn't seem to refresh, even on successive calls to Locked()
$ir_obj->Load($report);
$lock = $ir_obj->Locked();
ok(($lock->Content->{'Type'} eq 'Auto'), "Lock is an Auto lock");
sleep 5;
$agent->form_number(3);
$agent->click('SubmitTicket');
diag("Submitted Comment form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">.+\. It is now unlocked\.}ims, "IR $report is still locked");


###Testing Edit.html locking###

$agent->follow_link_ok({text => 'Edit', n => '1'}, "Followed Edit link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket}ims, "Edit page is auto locked");
$agent->form_number(3);
sleep 5;
$agent->click('SaveChanges');
diag("Submitted Edit form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">.+\. It is now unlocked\.}ims, "IR $report is not locked");

$agent->follow_link_ok({text => 'Split', n => '1'}, "Followed Split link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket}ims, "Split page is auto locked");
$agent->form_number(3);
sleep 5;
$agent->click('Create');
diag("Submitted Split form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">\s*You had Ticket #$report locked for \d+ \w+. It is now unlocked\.}ims, "IR $report is not locked");
if($agent->content =~ qr{<li>Ticket (\d+) created in queue.*</li>}i) {
    $ir_id2 = $1;
}
display_ticket($agent, $report);
$agent->follow_link_ok({text => 'Merge', n => '1'}, "Followed Merge link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket\.}ims, "Merge page is locked");
$agent->form_number(3);

$agent->field("SelectedTicket", $ir_id2);
$agent->submit();
diag("Submitted Merge form") if $ENV{'TEST_VERBOSE'};
$agent->content_unlike(qr{<div class="locked-by-you">}ims, "Lock from $report not moved to $ir_id2");
$report = $ir_id2;

#Now we need to set the owner to Nobody so that we can take the ticket for the Take tests
$agent->follow_link_ok({text => 'Edit', n => '1'}, "Followed Edit link");
$agent->form_number(3);
$agent->field('Owner', $nobody);
$agent->click('SaveChanges');
$agent->content_like(qr{<li>Owner changed from \w+ to Nobody</li>}, "Owner changed to Nobody");



#Take lock
diag("Testing take lock") if $ENV{'TEST_VERBOSE'};
$agent->follow_link_ok({text => 'Take', n => '1'}, "Followed Take link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket\.}ims, "Got a lock from Taking");
$ir_obj->Load($report);
$lock = $ir_obj->Locked();
ok(($lock->Content->{'Type'} eq 'Take'), "Lock is a Take lock");
sleep 5;
$agent->follow_link_ok({text => '[New]', n => '1'}, "Followed New (incident to link to) link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have had Ticket #$report locked for \d+ \w+\.}, "IR #$report is locked on Create Incident page");
$agent->form_number(3);
$agent->field('Subject', 'Incident linked to Lock Testing IR');
$agent->click('CreateIncident');
$agent->content_like(qr{<div class="locked-by-you">\s*You had Ticket #$report locked for \d+ \w+. It is now unlocked\.}ims, "Removed IR #$report Take lock");
$agent->goto_ticket($report);
$agent->content_unlike(qr{<div class="locked-by-you">}ims, "IR #$report is not locked");

$agent->follow_link_ok({text => 'Lock', n => '1'}, "Hard locked to test multi-user lock");




diag("Testing IR locking from other user's point of view");

go_home($root);
display_ticket($root, $report);
$root->content_like(qr{<div class="locked">}, "IR #$report is locked by another");
$root->follow_link_ok({text => 'Break lock', n => '1'}, "Breaking lock on IR #$report");
$root->content_like(qr{<li>You have broken the lock on this ticket</li>}, "Lock on IR #$report is broken");



diag("Testing Incident locking");
# Create an incident
my $inc = create_incident($agent, {Subject => $SUBJECT, Content => "bla", Owner => 'Nobody in particular &#40;Nobody&#41;' });


my $inc_obj = RT::Ticket->new(RT::SystemUser());

$inc_obj->Load($inc);
is($inc_obj->Id, $inc, "report has right ID");
is($inc_obj->Subject, $SUBJECT, "subject is right");

#Hard lock
diag("Testing hard lock") if $ENV{'TEST_VERBOSE'};

$agent->goto_ticket($inc);
$agent->follow_link_ok({text => 'Lock', n => '1'}, "Followed 'Lock' link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket\.}ims, "Added a hard lock on ticket $inc");
$lock = $inc_obj->Locked();
ok(($lock->Content->{'Type'} eq 'Hard'), "Lock is a Hard lock");
sleep 5;    #Otherwise, we run the risk of getting "You have locked this ticket" (see /Elements/ShowLock)


###Testing Reply.html locking###

$agent->follow_link_ok({text => 'Reply to Reporters', n => '1'}, "Followed Reply to Reporters link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have had this ticket locked for \d+}ims, "Reply to Reporters page is locked");
$agent->form_number(3);
$agent->click('SubmitTicket');
diag("Submitted Reply form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">}, "Incident $inc is still locked");


$agent->follow_link_ok({text => 'Edit', n => '1'}, "Followed Edit link");

$agent->content_like(qr{<div class="locked-by-you">\s*You have had this ticket locked for \d+}ims, "Edit page is locked");

$agent->form_number(3);
$agent->submit();
diag("Submitted Edit form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">}, "Incident $inc is still locked");

$agent->follow_link_ok({text => 'Unlock', n => '1'}, "Unlocking Incident $inc");
$agent->content_like(qr{<div class="locked-by-you">\s*You had this ticket locked for \d+ \w+\. It is now unlocked\.}ims, "Incident $inc is not locked");
$agent->follow_link_ok({text => 'Lock', n => '1'}, "Followed 'Lock' link again");
sleep 5;    #Otherwise, we run the risk of getting "You have locked this ticket" (see /Elements/ShowLock)
$agent->follow_link_ok({text => 'Split', n => '1'}, "Followed Split link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have had this ticket locked for \d+}ims, "Split page is still locked");
$agent->form_number(3);
$agent->field('Owner', $nobody);
$agent->click('CreateIncident');
diag("Submitted Split form") if $ENV{'TEST_VERBOSE'};
my $inc_id2;
if($agent->content =~ qr{<li>Ticket (\d+) created in queue.*</li>}i) {
    $inc_id2 = $1;
}
$agent->content_like(qr{<div class="locked-by-you">\s*You have had Ticket #$inc locked for \d+ \w+\.}ims, "Incident $inc is still locked");
display_ticket($agent, $inc);
$agent->follow_link_ok({text => 'Merge', n => '1'}, "Followed Merge link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have had this ticket locked for \d+}ims, "Merge page is still locked");
$agent->form_number(3);

$agent->field("SelectedTicket", $inc_id2);
$agent->submit();
diag("Submitted Merge form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket\.}ims, "Lock from $inc moved to $inc_id2");
$inc = $inc_id2;
$agent->follow_link_ok({text => 'Unlock', n => '1'}, "Removing hard lock on Incident $inc");


#Auto lock
diag("Testing auto lock") if $ENV{'TEST_VERBOSE'};

 
###Testing Reply.html locking###

$agent->follow_link_ok({text => 'Reply to Reporters', n => '1'}, "Followed Reply to Reporters link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket\.}ims, "Reply to Reporters page is locked");
sleep 5;
$agent->form_number(3);
$agent->click('SubmitTicket');
diag("Submitted Reply form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">\s*You had this ticket locked for \d+ \w+\. It is now unlocked\.}ims, "Incident $inc is still locked");


$agent->follow_link_ok({text => 'Edit', n => '1'}, "Followed Edit link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket}ims, "Edit page is auto locked");
# Without this, the lock type doesn't seem to refresh, even on successive calls to Locked()
$inc_obj->Load($inc);
$lock = $inc_obj->Locked();
ok(($lock->Content->{'Type'} eq 'Auto'), "Lock is an Auto lock");
$agent->form_number(3);
$agent->submit();
diag("Submitted Edit form") if $ENV{'TEST_VERBOSE'};
$agent->content_unlike(qr{<div class="locked-by-you">.+\.It is now unlocked\.}ims, "Incident $inc is not locked");

$agent->follow_link_ok({text => 'Split', n => '1'}, "Followed Split link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket}ims, "Split page is auto locked");
$agent->form_number(3);
$agent->field('Owner', $nobody);
sleep 5;
$agent->click('CreateIncident');
diag("Submitted Split form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you">\s*You had Ticket #$inc locked for \d+ \w+. It is now unlocked\.}ims, "Incident $inc is not locked");
if($agent->content =~ qr{<li>Ticket (\d+) created in queue.*</li>}i) {
    $inc_id2 = $1;
}
display_ticket($agent, $inc);
$agent->follow_link_ok({text => 'Merge', n => '1'}, "Followed Merge link");
$agent->content_like(qr{<div class="locked-by-you">\s*You have locked this ticket\.}ims, "Merge page is locked");
$agent->form_number(3);

$agent->field("SelectedTicket", $inc_id2);
$agent->submit();
diag("Submitted Merge form") if $ENV{'TEST_VERBOSE'};
$agent->content_unlike(qr{<div class="locked-by-you">}ims, "Lock from $inc not moved to $inc_id2");
$report = $inc_id2;

$agent->follow_link_ok({text => 'Lock', n => '1'}, "Hard locked to test multi-user lock");



diag("Testing Incident locking from other user's point of view");

display_ticket($root, $inc);
$root->content_like(qr{<div class="locked">}, "Incident #$inc is locked by another");
$root->follow_link_ok({text => 'Break lock', n => '1'}, "Breaking lock on Incident #$inc");
$root->content_like(qr{<li>You have broken the lock on this ticket</li>}, "Lock on Incident #$inc is broken");



#removes all user's locks
$agent->follow_link_ok({text => 'Logout', n => '1'}, "Logging out rtir_test_user");
$root->follow_link_ok({text => 'Logout', n => '1'}, "Logging out root");

1;

__DATA__

TODO: think about testing locking on other object types

# Create a new Incident from that report
my $first_incident_id = create_incident_for_ir($agent, $report, {Subject => "first incident"},
                                               {Function => "IncidentCoord"});

# TODO: make sure subject and content come from Report

# TODO: create Incident with new subject/content

# TODO: make sure all fields are set properly in DB

# create a new incident
my $second_incident_id = create_incident( $agent, { Subject => "foo Incident", Content => "bar baz quux" } );

