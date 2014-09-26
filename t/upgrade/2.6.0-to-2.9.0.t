#!/usr/bin/perl

use strict;
use warnings;

BEGIN { unless ( $ENV{RTIR_TEST_UPGRADE} ) {
    require Test::More;
    Test::More->import( skip_all => "Skipping upgrade tests, it's only for developers" );
} }

use RT::IR::Test tests => 18;
{
    RT::IR::Test->import_snapshot( 'rtir-2.6.after-rt-upgrade.sql' );
    my ($status, $msg) = RT::IR::Test->apply_upgrade( 'etc/upgrade/', '2.9.0' );
    ok $status, "applied upgrade" or diag "error: $msg";
}

my @state_cf_ids;
{
    my $cfs = RT::CustomFields->new( RT->SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => 'State', CASESENSITIVE => 0 );
    $cfs->Limit( FIELD => 'Disabled', VALUE => 1 );
    push @state_cf_ids, map $_->id, @{ $cfs->ItemsArrayRef };
    is( scalar @state_cf_ids, 4, 'four disabled state fields' );
}

{
    my @sla_cf_ids;
    my $cfs = RT::CustomFields->new( RT->SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => 'SLA', CASESENSITIVE => 0  );
    $cfs->Limit( FIELD => 'Disabled', VALUE => 1 );
    push @sla_cf_ids, map $_->id, @{ $cfs->ItemsArrayRef };
    is( scalar @sla_cf_ids, 1, 'one disabled SLA field' );
}


{
    my $ticket = RT::Ticket->new( RT->SystemUser );
    $ticket->Load(4);

    my $queue = $ticket->QueueObj;
    is( $queue->Name, 'Incident Reports', 'an IR' );
    is( $queue->LifecycleObj->Name, 'incident_reports', 'incidents cycle' );

    is( $ticket->Subject, 'IR for reject' );
    is( $ticket->Status, 'rejected' );

    ok( !$ticket->LoadCustomFieldByIdentifier('State')->id, 'State is not applied' );
    check_txns($ticket);
}

{
    my $ticket = RT::Ticket->new( RT->SystemUser );
    $ticket->Load(5);

    my $queue = $ticket->QueueObj;
    is( $queue->Name, 'Incidents', 'an incident' );
    is( $queue->LifecycleObj->Name, 'incidents', 'incidents cycle' );

    is( $ticket->Subject, 'Inc for abandon' );
    is( $ticket->Status, 'abandoned' );

    ok( !$ticket->LoadCustomFieldByIdentifier('State')->id, 'State is not applied' );
    check_txns($ticket);
}

sub check_txns {
    my $ticket = shift;

    my $txns = RT::Transactions->new( RT->SystemUser );
    $txns->Limit( FIELD => 'ObjectType', VALUE => 'RT::Ticket' );
    $txns->Limit( FIELD => 'ObjectId', VALUE => $ticket->id );
    $txns->Limit( FIELD => 'Type', VALUE => 'CustomField' );
    $txns->Limit( FIELD => 'Field', VALUE => $_ ) foreach @state_cf_ids;
    is( $txns->Count, 0, 'no state changes in history' );
}

