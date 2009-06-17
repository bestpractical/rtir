#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 39;
use File::Temp qw(tempdir);

my @rights_backup = RT::Test->store_rights;

RT::Test->set_mail_catcher;

RT->Config->Set( 'GnuPG',
                 Enable => 1,
                 OutgoingMessagesFormat => 'RFC' );

RT->Config->Set( GnuPGOptions =>
    homedir => scalar tempdir( CLEANUP => 0 ),
    passphrase => 'rt-test',
    'no-permission-warning' => undef,
);
diag "GnuPG --homedir ". RT->Config->Get('GnuPGOptions')->{'homedir'};

RT->Config->Set( 'MailPlugins' => 'Auth::MailFrom', 'Auth::GnuPG' );

my $queue = RT::Test->load_or_create_queue(
    Name              => 'Incident Reports',
    CorrespondAddress => 'rt-recipient@example.com',
    CommentAddress    => 'rt-recipient@example.com',
);
ok $queue && $queue->id, 'loaded or created queue';

my ($baseurl, $agent) = RT::Test->started_ok;
rtir_user();
$agent->login( rtir_test_user => 'rtir_test_pass' );

RT::Test->set_rights(
    Principal => 'Everyone',
    Right => ['CreateTicket', 'ShowTicket', 'SeeQueue', 'OwnTicket', 'ReplyToTicket', 'ModifyTicket'],
);

diag "check that things don't work if there is no key";
{

    my $ir_id = $agent->create_ir( { Subject => 'test', Requestors => 'rt-test@example.com' } );
    ok $ir_id, 'created an IR';
    
    my $inc_id = $agent->create_incident_for_ir( $ir_id, { Subject => 'test' } );
    ok $inc_id, 'created an Inc';

    RT::Test->clean_caught_mails;

    ok $agent->goto_ticket( $inc_id ), "UI -> ticket #$inc_id";
    $agent->follow_link_ok( { text => 'Reply to Reporters' }, 'inc -> Reply to Reporters' );
    $agent->form_number(3);
    $agent->tick( SelectedReports => $ir_id );
    $agent->tick( Sign => 1 );
    $agent->click('SubmitTicket');
    $agent->content_like(
        qr/unable to sign outgoing email messages/i,
        'problems with passphrase'
    );
    $agent->content_like(qr/rt-recipient\@example\.com/) or diag $agent->content;

    my @mail = RT::Test->fetch_caught_mails;
    ok !@mail, 'there are no outgoing emails'
        or diag "Emails' have been sent: \n". join "\n\n", @mail;
}

diag 'import rt-recipient@example.com key and sign it';
{
    RT::Test->import_gnupg_key('rt-recipient@example.com');
    RT::Test->trust_gnupg_key('rt-recipient@example.com');
    my %res = RT::Crypt::GnuPG::GetKeysInfo('rt-recipient@example.com');
    is $res{'info'}[0]{'TrustTerse'}, 'ultimate', 'ultimately trusted key';
}

diag "check that things don't work if there is no key";
{
    my $ir_id = $agent->create_ir( { Subject => 'test', Requestors => 'rt-test@example.com' } );
    ok $ir_id, 'created an IR';
    
    my $inc_id = $agent->create_incident_for_ir( $ir_id, { Subject => 'test' } );
    ok $inc_id, 'created an Inc';

    RT::Test->clean_caught_mails;

    ok $agent->goto_ticket( $inc_id ), "UI -> ticket #$inc_id";
    $agent->follow_link_ok( { text => 'Reply to Reporters' }, 'inc -> Reply to Reporters' );
    $agent->form_number(3);
    $agent->tick( SelectedReports => $ir_id );
    $agent->tick( Encrypt => 1 );
    $agent->click('SubmitTicket');
    $agent->content_like(
        qr/You are going to encrypt outgoing email messages/i,
        'problems with keys'
    );
    $agent->content_like(
        qr/There is no key suitable for encryption/i,
        'problems with keys'
    );

    my $form = $agent->form_number(3);
    ok !$form->find_input( 'UseKey-rt-test@example.com' ), 'no key selector';

    my @mail = RT::Test->fetch_caught_mails;
    ok !@mail, 'there are no outgoing emails';
}

RT::Test->restore_rights( @rights_backup );

