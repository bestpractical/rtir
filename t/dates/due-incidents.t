#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

# link on create without due
{
    my $ir1 = RT::Ticket->new( RT->SystemUser );
    my ($id, undef, $msg) = $ir1->Create(
        Queue => 'Incident Reports',
        Subject => 'IR1',
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $ir1->DueObj->Unix, 0;

    my $inc = RT::Ticket->new( RT->SystemUser );
    ($id, undef, $msg) = $inc->Create(
        Queue => 'Incidents',
        Subject => 'inc',
        HasMember => $ir1->URI,
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $inc->DueObj->Unix, 0;
}

# link after create without due
{
    my $ir1 = RT::Ticket->new( RT->SystemUser );
    my ($id, undef, $msg) = $ir1->Create(
        Queue => 'Incident Reports',
        Subject => 'IR1',
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $ir1->DueObj->Unix, 0;

    my $inc = RT::Ticket->new( RT->SystemUser );
    ($id, undef, $msg) = $inc->Create(
        Queue => 'Incidents',
        Subject => 'inc',
    );
    ok $id, 'created a ticket' or diag "error: $msg";

    (my $status, $msg) = $ir1->AddLink( Type => 'MemberOf', Target => $inc->id );
    ok $status, 'linked tickets' or diag "error: $msg";

    is $inc->DueObj->Unix, 0;
}

# link on create with due
{
    my $ir1 = RT::Ticket->new( RT->SystemUser );
    my ($id, undef, $msg) = $ir1->Create(
        Queue => 'Incident Reports',
        Subject => 'IR1',
        Due => '2011-10-23 16:47:45',
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $ir1->DueObj->ISO, '2011-10-23 16:47:45';

    my $inc = RT::Ticket->new( RT->SystemUser );
    ($id, undef, $msg) = $inc->Create(
        Queue => 'Incidents',
        Subject => 'inc',
        HasMember => $ir1->URI,
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $inc->DueObj->ISO, $ir1->DueObj->ISO;
}

# link after create with due
{
    my $ir1 = RT::Ticket->new( RT->SystemUser );
    my ($id, undef, $msg) = $ir1->Create(
        Queue => 'Incident Reports',
        Subject => 'IR1',
        Due => '2011-10-23 16:47:45',
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $ir1->DueObj->ISO, '2011-10-23 16:47:45';

    my $inc = RT::Ticket->new( RT->SystemUser );
    ($id, undef, $msg) = $inc->Create(
        Queue => 'Incidents',
        Subject => 'inc',
    );
    ok $id, 'created a ticket' or diag "error: $msg";

    (my $status, $msg) = $ir1->AddLink( Type => 'MemberOf', Target => $inc->id );
    ok $status, 'linked tickets' or diag "error: $msg";

    $inc->Load( $inc->id ); # reload
    is $inc->DueObj->ISO, $ir1->DueObj->ISO;
}

# change Due after linking
{
    my $ir1 = RT::Ticket->new( RT->SystemUser );
    my ($id, undef, $msg) = $ir1->Create(
        Queue => 'Incident Reports',
        Subject => 'IR1',
    );
    ok $id, 'created a ticket' or diag "error: $msg";

    my $inc = RT::Ticket->new( RT->SystemUser );
    ($id, undef, $msg) = $inc->Create(
        Queue => 'Incidents',
        Subject => 'inc',
        HasMember => $ir1->URI,
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $inc->DueObj->Unix, 0;

    (my $status, $msg) = $ir1->SetDue('2011-10-23 16:47:45');
    ok $status, "updated due on IR";
    is $ir1->DueObj->ISO, '2011-10-23 16:47:45';

    $inc->Load( $inc->id ); # reload
    is $inc->DueObj->ISO, $ir1->DueObj->ISO;

    ($status, $msg) = $ir1->SetDue('2011-11-23 16:47:45');
    ok $status, "updated due on IR";
    is $ir1->DueObj->ISO, '2011-11-23 16:47:45';

    $inc->Load( $inc->id ); # reload
    is $inc->DueObj->ISO, $ir1->DueObj->ISO;

    ($status, $msg) = $ir1->SetDue('2011-09-23 16:47:45');
    ok $status, "updated due on IR";
    is $ir1->DueObj->ISO, '2011-09-23 16:47:45';

    $inc->Load( $inc->id ); # reload
    is $inc->DueObj->ISO, $ir1->DueObj->ISO;

    ($status, $msg) = $ir1->SetDue('1970-01-01 00:00:00');
    ok $status, "updated due on IR";
    is $ir1->DueObj->ISO, '1970-01-01 00:00:00';

    $inc->Load( $inc->id ); # reload
    is $inc->DueObj->ISO, $ir1->DueObj->ISO;
}

# two IRs linked to Inc, play with Due
{
    my $ir1 = RT::Ticket->new( RT->SystemUser );
    my ($id, undef, $msg) = $ir1->Create(
        Queue => 'Incident Reports',
        Subject => 'IR1',
        Due => '2011-10-23 16:47:45',
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $ir1->DueObj->ISO, '2011-10-23 16:47:45';

    my $ir2 = RT::Ticket->new( RT->SystemUser );
    ($id, undef, $msg) = $ir2->Create(
        Queue => 'Incident Reports',
        Subject => 'IR2',
        Due => '2011-10-24 16:47:45',
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $ir2->DueObj->ISO, '2011-10-24 16:47:45';

    my $inc = RT::Ticket->new( RT->SystemUser );
    ($id, undef, $msg) = $inc->Create(
        Queue => 'Incidents',
        Subject => 'inc',
        HasMember => [$ir1->URI, $ir2->URI],
    );
    ok $id, 'created a ticket' or diag "error: $msg";
    is $inc->DueObj->ISO, $ir1->DueObj->ISO;

    (my $status, $msg) = $ir2->SetDue('2011-10-25 16:47:45');
    ok $status, "updated due on IR";
    is $ir2->DueObj->ISO, '2011-10-25 16:47:45';

    $inc->Load( $inc->id ); # reload
    is $inc->DueObj->ISO, $ir1->DueObj->ISO;

    ($status, $msg) = $ir2->SetDue('2011-10-22 16:47:45');
    ok $status, "updated due on IR";
    is $ir2->DueObj->ISO, '2011-10-22 16:47:45';

    $inc->Load( $inc->id ); # reload
    is $inc->DueObj->ISO, $ir2->DueObj->ISO;

    ($status, $msg) = $ir2->SetStatus('resolved');
    ok $status, "updated status on IR";

    $inc->Load( $inc->id ); # reload
    is $inc->DueObj->ISO, $ir1->DueObj->ISO;
}

done_testing;
