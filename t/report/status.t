#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

diag "link IR to Inc on create" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( { Subject => "test" } );
    my $ir_id = $agent->create_ir( { Subject => "test", Incident => $inc_id } );
    is $agent->ticket_status($ir_id), 'open', 'auto open kicked in';
}

diag "link IR to Inc after create" if $ENV{'TEST_VERBOSE'};
{
    my $inc_id = $agent->create_incident( { Subject => "test" } );
    my $ir_id = $agent->create_ir( { Subject => "test" } );
    is $agent->ticket_status($ir_id), 'new', 'auto open kicked in';

    {
        my $inc = RT::Ticket->new( RT->SystemUser );
        $inc->Load( $inc_id );
        my $ir = RT::Ticket->new( RT->SystemUser );
        $ir->Load( $ir_id );
        my ($status, $msg) = $ir->AddLink( Type => 'MemberOf', Target => $inc_id );
        ok($status, 'linked IR with Inc') or diag "error: $msg";
    }

    is $agent->ticket_status($ir_id), 'open', 'auto open kicked in';
}

done_testing;
