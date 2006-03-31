#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 53;

require "t/rtir-test.pl";

my $agent = default_agent();

# Create some reports

my $rtir_user = rtir_user();

# We are testing that the reject and quick reject buttons both work
# both for IRs that you own and IRs that are unowned.  So we make four IRs to work with.

my $nobody_slow  = create_ir($agent, {Subject => "nobody slow", Owner => RT::Nobody()->Id });
my $nobody_quick = create_ir($agent, {Subject => "nobody quick", Owner => RT::Nobody()->Id });
my $me_slow      = create_ir($agent, {Subject => "me slow", Owner => $rtir_user->Id });
my $me_quick     = create_ir($agent, {Subject => "me quick", Owner => $rtir_user->Id });


for my $id ($nobody_slow, $nobody_quick) {
    my $ir_obj = RT::Ticket->new(RT::SystemUser());
    $ir_obj->Load($id);
    is($ir_obj->Id, $id, "report has right ID");
    is($ir_obj->Owner, RT::Nobody()->Id, "report owned by nobody");
}

for my $id ($me_slow, $me_quick) {
    my $ir_obj = RT::Ticket->new(RT::SystemUser());
    $ir_obj->Load($id);
    is($ir_obj->Id, $id, "report has right ID");
    is($ir_obj->Owner, $rtir_user->Id, "report owned by me");
}

for my $id ($nobody_quick, $me_quick) {
    display_ticket($agent, $id);
    $agent->follow_link_ok({text => "Quick Reject"}, "Followed 'Quick Reject' link");

    like($agent->content, qr/State changed from new to rejected/, "site says ticket got rejected");
}

for my $id ($nobody_slow, $me_slow) {
    display_ticket($agent, $id);

    $agent->follow_link_ok({text => "Reject"}, "Followed 'Reject' link");

    $agent->form_name("TicketUpdate");
    $agent->field(UpdateContent => "why you are rejected");
    $agent->click("SubmitTicket");

    is ($agent->status, 200, "attempt to reject succeeded");

    like($agent->content, qr/State changed from new to rejected/, "site says ticket got rejected");
}

# we need to flush the cache, or else later the status change will not be detected
use DBIx::SearchBuilder::Record::Cachable;
DBIx::SearchBuilder::Record::Cachable::FlushCache();


for my $id ($nobody_slow, $nobody_quick, $me_quick, $me_slow) {
    my $ir_obj = RT::Ticket->new(RT::SystemUser());
    $ir_obj->Load($id);
    is($ir_obj->Id, $id, "loaded ticket $id OK");
    is($ir_obj->Status, 'rejected', "ticket $id is now rejected in DB");
}
