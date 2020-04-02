#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

# Create some reports

my $rtir_user = rtir_user();

# We are testing that the reject and quick reject buttons both work
# both for IRs that you own and IRs that are unowned.  So we make four IRs to work with.

my $nobody_slow  = $agent->create_ir( {Subject => "nobody slow", Owner => RT::Nobody()->Id });
my $nobody_quick = $agent->create_ir( {Subject => "nobody quick", Owner => RT::Nobody()->Id });
my $me_slow      = $agent->create_ir( {Subject => "me slow", Owner => $rtir_user->Id });
my $me_quick     = $agent->create_ir( {Subject => "me quick", Owner => $rtir_user->Id });


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
    $agent->display_ticket( $id);
    $agent->follow_link_ok({text => "Quick Reject"}, "Followed 'Quick Reject' link");

    like($agent->content, qr/Status changed from \S*(?:new|open)\S* to \S*rejected\S*/, "site says ticket got rejected");
}
for my $id ($nobody_slow, $me_slow) {
    $agent->display_ticket( $id);

    $agent->follow_link_ok({text => "Reject"}, "Followed 'Reject' link");

    $agent->form_name("TicketUpdate");
    $agent->field(UpdateContent => "why you are rejected");
    $agent->click("SubmitTicket");

    is ($agent->status, 200, "attempt to reject succeeded");

    like($agent->content, qr/Status changed from \S*(?:new|open)\S* to \S*rejected\S*/, "site says ticket got rejected");
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

diag "test that after reject links to incidents are still there" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( {Subject => "test"});
    my $id = $agent->create_ir( {Subject => "test", Incident => $inc_id});
    {
        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->FromSQL( "id = $id AND MemberOf = $inc_id");
        is $tickets->Count, 1, 'have the link';
    }

    $agent->display_ticket( $id);
    $agent->follow_link_ok({text => "Reject"}, "Followed 'Reject' link");
    $agent->form_name("TicketUpdate");
    $agent->field(UpdateContent => "why you are rejected");
    $agent->click("SubmitTicket");
    is $agent->status, 200, "attempt to reject succeeded";
    $agent->ticket_status_is( $id, 'rejected' );

    {
        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->FromSQL( "id = $id AND MemberOf = $inc_id");
        is $tickets->Count, 1, 'the link is still there';
    }

    # go to incident and check that we still can see the child
    $agent->display_ticket( $inc_id);
    $agent->follow_link_ok({text => "Incident Reports", n => 2}, "Followed 'Incident Reports' link");
    $agent->form_number(3);
    $agent->tick( Statuses => 'rejected' );
    $agent->click('RefineStatus');

    $agent->has_tag('a', "$id", 'we have link to ticket');
}

diag "test that after quick reject links to incidents are still there" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( {Subject => "test"});
    my $id = $agent->create_ir( {Subject => "test", Incident => $inc_id});
    {
        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->FromSQL( "id = $id AND MemberOf = $inc_id");
        is $tickets->Count, 1, 'have the link';
    }

    $agent->display_ticket( $id);
    $agent->follow_link_ok({text => "Quick Reject"}, "Followed 'Reject' link");
    $agent->ticket_status_is( $id, 'rejected' );

    {
        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->FromSQL( "id = $id AND MemberOf = $inc_id");
        is $tickets->Count, 1, 'the link is still there';
    }

    # go to incident and check that we still can see the child
    $agent->display_ticket( $inc_id);
    $agent->follow_link_ok({text => "Incident Reports", n => 2}, "Followed 'Incident Reports' link");
    $agent->form_number(3);
    $agent->tick( Statuses => 'rejected' );
    $agent->click('RefineStatus');

    $agent->has_tag('a', "$id", 'we have link to ticket');
}

diag "test that after bulk reject links to incidents are still there" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( {Subject => "test"});
    my $id = $agent->create_ir( {Subject => "test", Incident => $inc_id});
    {
        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->FromSQL( "id = $id AND MemberOf = $inc_id");
        is $tickets->Count, 1, 'have the link';
    }

    $agent->display_ticket( $id);
    $agent->follow_link_ok({text => "Incident Reports", url => '/Search/Results.html?ExtraQueryParams=RTIR&RTIR=1&Lifecycle=incident_reports'}, "Followed 'Incident Reports' link");
    while($agent->content() !~ m{Display.html\?id=$id">$id</a>}) {
        last unless $agent->follow_link(text => 'Next');
    }
    $agent->has_tag('a', "$id", 'we have link to ticket');
    $agent->follow_link_ok({text => "Bulk Reject"}, "Followed 'Bulk Reject' link");
    $agent->form_number(3);
    $agent->tick( SelectedTickets => $id );
    $agent->click('BulkReject');

    $agent->ticket_status_is( $id, 'rejected' );

    {
        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->FromSQL( "id = $id AND MemberOf = $inc_id");
        is $tickets->Count, 1, 'the link is still there';
    }

    # go to incident and check that we still can see the child
    $agent->display_ticket( $inc_id);
    $agent->follow_link_ok({text => "Incident Reports", n => 2}, "Followed 'Incident Reports' link");
    $agent->form_number(3);
    $agent->tick( Statuses => 'rejected' );
    $agent->click('RefineStatus');

    $agent->has_tag('a', "$id", 'we have link to ticket');
}

undef $agent;
done_testing;
