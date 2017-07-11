#!/usr/bin/perl

use strict;
use warnings;
use Test::Warn;

BEGIN { unless ( $ENV{RTIR_TEST_UPGRADE} ) {
    require Test::More;
    Test::More->import( skip_all => "Skipping upgrade tests, it's only for developers" );
} }

BEGIN { unless ( -d "../rt/etc/upgrade/" ) {
    require Test::More;
    Test::More->import( skip_all => "Skipping upgrade tests, must have a sibling ../rt/ directory for running upgrades" );
} }

use RT::IR::Test tests => undef;

{
    RT::IR::Test->import_snapshot( 'rtir-2.6.after-rt-upgrade.sql' );

    # upgrade database for RT 4.2.0 on
    {
        my @all_versions = sort { RT::Handle::cmp_version($a, $b) } map { m{upgrade/([\w.]+)/} && $1 } glob('../rt/etc/upgrade/4.*/');
        my @upgrades;
        for my $version (@all_versions) {
            next if RT::Handle::cmp_version($version, '4.2.0') == -1;
            next if RT::Handle::cmp_version($version, $RT::VERSION) == 1;
            push @upgrades, $version;
        }

        # if we're between versions *and* the last version we collected above
        # is the same as the penultimate version, then collect the next
        # version too
        # as a concrete example, if the RT version is 4.4.1-147-g602fd00
        # then the above code selects all the upgrades up to and
        # including 4.4.1, but doesn't include 4.4.2 because it's a
        # future version. that will cause the test to explode because
        # 4.4.1-147-g602fd00 needs to include the 4.4.2 schema changes
        # as well, even though 4.4.2 hasn't even been tagged
        # yet. so the following check adds that "future" version, 4.4.2
        push @upgrades, $all_versions[-1]
            if $RT::VERSION =~ /-/
            && RT::Handle::cmp_version($all_versions[-2], $upgrades[-1]) == 0;

        my ($status, $msg);
        warnings_like {
            ($status, $msg) = RT::IR::Test->apply_upgrade( '../rt/etc/upgrade/', @upgrades);
        } [ qr{Unable to load scrip} ];

        ok $status, "applied " . scalar(@upgrades) . " RT version upgrades" or diag "error: $msg";
    }

    # upgrade database for RTIR 2.6.0 on
    {
        my @versions;
        for my $version (sort { RT::Handle::cmp_version($a, $b) } map { m{upgrade/([\w.]+)/} && $1 } glob('etc/upgrade/*/')) {
            next if RT::Handle::cmp_version($version, '2.6.0') == -1;

            push @versions, $version;
        }

        my ($status, $msg) = RT::IR::Test->apply_upgrade( 'etc/upgrade/', @versions);
        ok $status, "applied " . scalar(@versions) . " RTIR upgrades" or diag "error: $msg";
    }
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
    my $ticket = RT::Ticket->new( RT->SystemUser );
    $ticket->Load(4);

    my $queue = $ticket->QueueObj;
    is( $queue->Name, 'Incident Reports - EDUNET', 'an IR' );
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
    is( $queue->Name, 'Incidents - EDUNET', 'an incident' );
    is( $queue->LifecycleObj->Name, 'incidents', 'incidents cycle' );

    is( $ticket->Subject, 'Inc for abandon' );
    is( $ticket->Status, 'abandoned' );

    ok( !$ticket->LoadCustomFieldByIdentifier('State')->id, 'State is not applied' );
    check_txns($ticket);
}

done_testing;

sub check_txns {
    my $ticket = shift;

    my $txns = RT::Transactions->new( RT->SystemUser );
    $txns->Limit( FIELD => 'ObjectType', VALUE => 'RT::Ticket' );
    $txns->Limit( FIELD => 'ObjectId', VALUE => $ticket->id );
    $txns->Limit( FIELD => 'Type', VALUE => 'CustomField' );
    $txns->Limit( FIELD => 'Field', VALUE => $_ ) foreach @state_cf_ids;
    is( $txns->Count, 0, 'no state changes in history' );
}

