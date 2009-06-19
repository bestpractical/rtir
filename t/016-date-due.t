#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 17;

my $duty_a = RT::Test->load_or_create_user(
    Name       => 'duty a',
    Password   => 'password',
    MemberOf   => 'DutyTeam',
);

my $duty_b = RT::Test->load_or_create_user(
    Name       => 'duty b',
    Password   => 'password',
    MemberOf   => 'DutyTeam',
);

my $customer = RT::Test->load_or_create_user(
    Name       => 'customer',
    Password   => 'password',
);

{
    my $ticket = RT::Ticket->new( $duty_a );
    my ($id) = $ticket->Create(
        Queue => 'Incident Reports',
        Owner => $duty_a->id,
        Requestor => $customer->id,
    );
    ok $id, 'created a ticket';

    $ticket->Load( $id );
    is $ticket->id, $id, 'loaded ticket';
    is $ticket->Owner, $duty_a->id, 'correct owner';
    ok $ticket->Due, 'due value';
    # XXX: need something better
    ok $ticket->DueObj->Unix > time, 'in the future';

    { # duty_b replies
        my $ticket = RT::Ticket->new( $duty_b );
        $ticket->Load($id);
        ok $ticket->id, 'laoded ticket';
        my ($status, $msg) = $ticket->Correspond( Content => 'hey ho!' );
        ok $status, 'replied' or diag "error: $msg";
        ok $ticket->DueObj->Unix > time, 'in the future';
    }

    { # customer replies
        my $ticket = RT::Ticket->new( $customer );
        $ticket->Load($id);
        ok $ticket->id, 'laoded ticket';
        my ($status, $msg) = $ticket->Correspond( Content => 'hey ho!' );
        ok $status, 'replied' or diag "error: $msg";
        ok $ticket->DueObj->Unix < time, 'in the future';
    }
}

