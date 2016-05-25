#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

my $cf_name = 'test';
my $cf;
{
    $cf = RT::CustomField->new( $RT::SystemUser );
    my ($id, $msg) = $cf->Create(
        Name       => $cf_name,
        LookupType => 'RT::Queue-RT::Ticket-RT::Transaction',
        Type       => 'FreeformSingle',
        Pattern    => '(?#not a magic)^(?!magic).*$',
    );
    ok( $id, "created custom field" ) or diag "error: $msg";

    for my $q ('Incident Reports', 'Investigations', 'Incidents', 'Countermeasures') {
        my $q_obj = RT::Queue->new($RT::SystemUser);
        $q_obj->Load($q);
        ok( $q_obj->id, "Loaded queue '$q'" );

        my $OCF = RT::ObjectCustomField->new($RT::SystemUser);
        my ($status, $msg) = $OCF->Create(
            CustomField => $cf->id,
            ObjectId    => $q_obj->id,
        );
        ok( $status && $OCF->id, 'Applied CF to the queue') or diag "error: $msg";
    }

    RT::IR::Test->add_rights( Principal => 'everyone', Right => ['SeeCustomField', 'ModifyCustomField']);
    RT::IR->FlushCustomFieldsCache;
}

RT::Test->started_ok;
my $agent = default_agent();

my $inc_id = $agent->create_incident( { Subject => "incident" } );
ok $inc_id, "created an incident";

my @tickets;
foreach my $qname ('Incident Reports', 'Investigations', 'Countermeasures') {
    $agent->goto_create_rtir_ticket( $qname );
    my $form = $agent->form_name('TicketCreate');

    my $input_name = 'Object-RT::Transaction--CustomField-'. $cf->id .'-Value';
    my $input = $form->find_input( $input_name );
    ok $input, 'input for the field is on the page';

    $agent->field( Incident => $inc_id ); # for countermeasures
    $agent->field( Requestors => 'rt-test@example.com' ); # for invs
    $agent->field( $input_name => 'magic' );
    $agent->click('Create');

    $form = $agent->form_name('TicketCreate');
    ok($form, 'still on create page');
    $input = $form->find_input( $input_name );
    ok $input, 'input for the field is on the page';

    is $agent->value( $input_name ), 'magic', 'old value is there';
    $agent->content_like( qr/not a magic/, 'error is there' );
    $agent->field( $input_name => 'not magic' );
    $agent->click('Create');

    my $id = $agent->get_ticket_id;
    ok $id, 'created a ticket';
    push @tickets, $id;
}

foreach my $id ( @tickets ) {
    my $ticket = RT::Ticket->new( RT->SystemUser );
    $ticket->Load( $id );
    is $ticket->id, $id, 'loaded ticket';

    my $txn = $ticket->Transactions->First;
    is $txn->Type, 'Create';
    is $txn->FirstCustomFieldValue( $cf_name ), 'not magic', 'correct value';
}


foreach my $id ( @tickets ) {
    $agent->goto_ticket( $id );
    $agent->follow_link_ok({ text => 'Reply' });

    my $form = $agent->form_name('TicketUpdate');

    my $input_name = 'Object-RT::Transaction--CustomField-'. $cf->id .'-Value';
    my $input = $form->find_input( $input_name );
    ok $input, 'input for the field is on the page';

    $agent->field( $input_name => 'magic' );
    $agent->click('SubmitTicket');

    $form = $agent->form_name('TicketUpdate');
    ok($form, 'still on update page');
    $input = $form->find_input( $input_name );
    ok $input, 'input for the field is on the page';

    is $agent->value( $input_name ), 'magic', 'old value is there';
    $agent->content_like( qr/not a magic/, 'error is there' );
    $agent->field( $input_name => 'not magic' );
    $agent->field( UpdateContent => 'content' );
    $agent->click('SubmitTicket');
}

foreach my $id ( @tickets ) {
    my $ticket = RT::Ticket->new( RT->SystemUser );
    $ticket->Load( $id );
    is $ticket->id, $id, 'loaded ticket';

    my $txns = $ticket->Transactions;
    $txns->Limit( FIELD => 'Type', VALUE => 'Correspond' );
    my $txn = $txns->First;
    ok $txn, 'found correspond';
    is $txn->FirstCustomFieldValue( $cf_name ), 'not magic', 'correct value';
}


undef $agent;
done_testing;
