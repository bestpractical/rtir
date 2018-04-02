#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 68;

RT::Test->started_ok;
my $agent = default_agent();

use_ok('RT');
use_ok('RT::IR');

my $rtir_user = RT::CurrentUser->new( rtir_user() );

diag "started date of an investigation" if $ENV{'TEST_VERBOSE'};
{
    my $id = $agent->create_investigation( {Subject => "started date"});
    $agent->display_ticket( $id);
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    is($ticket->id, $id, 'loaded ticket');
    is($ticket->Started, $ticket->Created, 'for an investigation started date == created');
}

diag "started date of an IR" if $ENV{'TEST_VERBOSE'};
{
    my $ir_id = $agent->create_ir( {Subject => "started date"});
    $agent->display_ticket( $ir_id);
    sleep 1;

    my $inc_id = $agent->create_incident_for_ir( $ir_id, {Subject => "started date"} );
    my $inc = RT::Ticket->new( $RT::SystemUser );
    $inc->Load( $inc_id );
    is($inc->id, $inc_id, 'loaded inc');

    my $ir = RT::Ticket->new( $RT::SystemUser );
    $ir->Load( $ir_id );
    is($ir->id, $ir_id, 'loaded ir');
    ok( abs($ir->StartedObj->Unix - $inc->CreatedObj->Unix) <= 1, 'for an IR started date == linking to inc time');
}

diag "started date of an IR" if $ENV{'TEST_VERBOSE'};
{
    my $ir_id = $agent->create_ir( {Subject => "started date"});
    my $ir = RT::Ticket->new( $RT::SystemUser );
    $ir->Load( $ir_id );
    is($ir->id, $ir_id, 'loaded ir');
    ok($ir->StartedObj->Unix <= 0, 'started is not set on a new IR');

    $agent->display_ticket( $ir_id);
    $agent->follow_link_ok({text => 'Reply'}, "go to 'Reply'");
    is($agent->status, 200, "request successful");

    $agent->form_number(3);
    $agent->field('UpdateContent', "reply shouldn't open or set started date");
    $agent->click('SubmitTicket');
    is($agent->status, 200, "request successful");
    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    $ir = RT::Ticket->new( $RT::SystemUser );
    $ir->Load( $ir_id );
    is($ir->id, $ir_id, 'loaded ir');
    ok($ir->StartedObj->Unix <= 0, 'started is not set on a new IR');
}

diag "started date of an IR" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( {Subject => "started date"});
    sleep 5;

    my $ir_id = $agent->create_ir( {Subject => "started date", Incident => $inc_id});
    $agent->display_ticket( $ir_id);

    my $inc = RT::Ticket->new( $RT::SystemUser );
    $inc->Load( $inc_id );
    is($inc->id, $inc_id, 'loaded inc');

    my $ir = RT::Ticket->new( $RT::SystemUser );
    $ir->Load( $ir_id );
    is($ir->id, $ir_id, 'loaded ir');
    ok( abs( $ir->StartedObj->Unix - $ir->CreatedObj->Unix ) <= 2,
        'for an IR started date == linking to inc time: ' . $ir->StartedObj->Unix . ' VS ' . $ir->CreatedObj->Unix );
}

diag "started date of a block" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( {Subject => "started date"});
    my $block_id = $agent->create_block( {Subject => "started date", Incident => $inc_id});

    my $block = RT::Ticket->new( $RT::SystemUser );
    $block->Load( $block_id );
    is($block->id, $block_id, 'loaded block');
    ok( $block->StartedObj->Unix <= 0, 'a new block is not active');

    $agent->display_ticket( $block_id);
    $agent->follow_link_ok({text => 'Activate'}, "activate it");
    is($agent->status, 200, "request successful");

    $agent->form_number(3);
    $agent->field( UpdateContent => 'activating block' );
    $agent->click('SubmitTicket');
    is($agent->status, 200, "request successful");

    DBIx::SearchBuilder::Record::Cachable::FlushCache();

    $block = RT::Ticket->new( $RT::SystemUser );
    $block->Load( $block_id );
    is($block->id, $block_id, 'loaded block');
    ok( $block->StartedObj->Unix > 0, 'activation of a block sets started date');
}

