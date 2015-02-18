#!/usr/bin/perl

use strict;
use warnings;

use Test::More skip_all => 'constituencies being rebuilt';
use RT::IR::Test tests => 13;
use_ok('RT::IR');

my $cf;
diag "load and check basic properties of the CF" if $ENV{'TEST_VERBOSE'};
{
    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => 'Constituency', CASESENSITIVE => 0 );
    $cf = $cfs->First;
    ok $cf && $cf->id, 'loaded field';
    is $cf->Name, 'Constituency', 'good name';
}

my $user = RT::Test->load_or_create_user(
    Name => 'test',
    Password => 'password',
);
ok $user && $user->id, 'loaded or created user';

my $queue_ir = RT::Test->load_or_create_queue( Name => 'Incident Reports' );
ok $queue_ir && $queue_ir->id, 'loaded or created queue';

# cleanup ACLs
RT::Test->set_rights;

my $queue_ir_edunet = RT::Test->load_or_create_queue( Name => 'Incident Reports - EDUNET' );
ok $queue_ir_edunet && $queue_ir_edunet->id, 'loaded or created queue';

{
    my $queue = RT::Queue->new( $user );
    $queue->Load('Incident Reports');
    ok $queue->id, 'loaded IR queue object';
    ok !$queue->CurrentUserHasRight('CreateTicket'), 'user has no right';

    RT::Test->set_rights(
        Principal => $user->PrincipalObj,
        Right => ['CreateTicket', 'SeeQueue'],
        Object => $queue_ir_edunet,
    );
    ok $queue->CurrentUserHasRight('CreateTicket'), 'user has right';
    ok $queue->CurrentUserHasRight('SeeQueue'), 'user has right';
}
