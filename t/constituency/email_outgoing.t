#!/usr/bin/perl

use strict;
use warnings;

require "t/rtir-test.pl";
use Test::More tests => 36;

RT->Config->Set( '_RTIR_Constituency_default' => 'EDUNET' );

my ($queue_ir, $queue_ir_edunet, $queue_ir_govnet);
diag "create or update queues";
{
    $queue_ir = RT::Test->load_or_create_queue(
        Name              => 'Incident Reports',
        CorrespondAddress => 'reports@example.com',
        CommentAddress    => 'reports-comment@example.com',
    );
    ok $queue_ir && $queue_ir->id, 'loaded or created queue_ir';

    $queue_ir_edunet = RT::Test->load_or_create_queue(
        Name              => 'Incident Reports - EDUNET',
        CorrespondAddress => 'edu-reports@example.com',
        CommentAddress    => 'edu-reports-comment@example.com',
    );
    ok $queue_ir_edunet && $queue_ir_edunet->id, 'loaded or created queue';

    $queue_ir_govnet = RT::Test->load_or_create_queue(
        Name              => 'Incident Reports - GOVNET',
        CorrespondAddress => 'gov-reports@example.com',
        CommentAddress    => 'gov-reports-comment@example.com',
    );
    ok $queue_ir_govnet && $queue_ir_govnet->id, 'loaded or created queue';
}

my $eduhandler = RT::Test->load_or_create_user( Name => 'eduhandler', Password => 'eduhandler' );
ok $eduhandler->id, "Created eduhandler";
my $govhandler = RT::Test->load_or_create_user( Name => 'govhandler', Password => 'govhandler' );
ok $govhandler->id, "Created govhandler";

ok( RT::Test->add_rights(
    { Principal => 'Privileged',
        Right => [qw(ModifyCustomField SeeCustomField OwnTicket)], },
    { Principal => $govhandler, Object => $queue_ir,
        Right => [qw(SeeQueue CreateTicket)] },
    { Principal => $eduhandler, Object => $queue_ir,
        Right => [qw(SeeQueue CreateTicket)] },
    { Principal => $eduhandler, Object => $queue_ir_edunet,
        Right => [qw(ShowTicket CreateTicket)] },
    { Principal => $govhandler, Object => $queue_ir_govnet,
        Right => [qw(ShowTicket CreateTicket)] },
), 'added rights');

RT::Test->set_mail_catcher;

my ($baseurl, $agent) = RT::Test->started_ok;
my $rtir_user = rtir_user();
$agent->login( rtir_test_user => 'rtir_test_pass' );

diag "create an IR via base address";
{
    RT::Test->clean_caught_mails;

        my $text = <<EOF;
From: @{[ $rtir_user->EmailAddress ]}
To: reports\@example.com
Subject: This is a test of constituency functionality

Foob!
EOF
    my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Incident Reports');
    is $status >> 8, 0, "The mail gateway exited ok";
    ok $id, "created ticket $id";

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    ok $ticket->id, 'loaded the ticket';
    is $ticket->FirstCustomFieldValue('Constituency'), 'EDUNET', 'correct value';

    display_ticket($agent, $id);
    $agent->content_like( qr/\QEDUNET/, "value on the page" );

    my @mail = RT::Test->fetch_caught_mails;
    ok @mail, 'there are some outgoing emails';
    
    my $from_ok = 1;
    foreach my $mail ( @mail ) {
        next if $mail =~ /^From:\s*.*?edu-reports\@example\.com/mi;
        diag $mail;
        $from_ok = 0;
        last;
    }
    ok $from_ok, 'all From addresses are correct';
}

diag "create an IR under GOVNET";
{
    RT::Test->clean_caught_mails;

    my $text = <<EOF;
From: @{[ $rtir_user->EmailAddress ]}
To: gov-reports\@example.com
Subject: This is a test of constituency functionality

Foob!
EOF
    my ($status, $id) = RT::Test->send_via_mailgate($text, queue => 'Incident Reports', extension => 'GOVNET');
    is $status >> 8, 0, "The mail gateway exited ok";
    ok $id, "created ticket $id";

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    ok $ticket->id, 'loaded the ticket';
    is $ticket->FirstCustomFieldValue('Constituency'), 'GOVNET', 'correct value';

    display_ticket($agent, $id);
    $agent->content_like( qr/GOVNET/, "value on the page" );

    my @mail = RT::Test->fetch_caught_mails;
    ok @mail, 'there are some outgoing emails';
    
    my $from_ok = 1;
    foreach my $mail ( @mail ) {
        next if $mail =~ /^From:\s*.*?gov-reports\@example\.com/mi;
        diag $mail;
        $from_ok = 0;
        last;
    }
    ok $from_ok, 'all From addresses are correct';
}

diag "GOV user creates an IR under EDUNET, check addresses";
{
    RT::Test->clean_caught_mails;

    $agent->login('govhandler', 'govhandler');
    my $id = create_ir(
        $agent,
        { Subject => "test", Requestors => $rtir_user->EmailAddress },
        { Constituency => 'EDUNET' },
    );
    ok $id, "created ticket $id";

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    ok $ticket->id, 'loaded the ticket';
    is $ticket->FirstCustomFieldValue('Constituency'), 'EDUNET', 'correct value';

    my @mail = RT::Test->fetch_caught_mails;
    ok @mail, 'there are some outgoing emails';
    
    my $from_ok = 1;
    foreach my $mail ( @mail ) {
        next if $mail =~ /^From:\s*.*?edu-reports\@example\.com/mi;
        diag $mail;
        $from_ok = 0;
        last;
    }
    ok $from_ok, 'all From addresses are correct';
}

