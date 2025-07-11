#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test::GnuPG tests => undef, gnupg_options => { passphrase => 'rt-test' };

my $queue = RT::Test->load_or_create_queue(
    Name              => 'Incident Reports',
    CorrespondAddress => 'rt-recipient@example.com',
    CommentAddress    => 'rt-recipient@example.com',
);
ok $queue && $queue->id, 'loaded or created queue';

my ($baseurl) = RT::Test->started_ok;
my $agent = default_agent();
rtir_user();
$agent->login( rtir_test_user => 'rtir_test_pass' );

{
    RT::Test->import_gnupg_key('rt-recipient@example.com');
    RT::Test->trust_gnupg_key('rt-recipient@example.com');
    my %res = RT::Crypt->GetKeysInfo('rt-recipient@example.com');
    is $res{'info'}[0]{'TrustTerse'}, 'ultimate', 'ultimately trusted key';
}

my $tid;
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    ($tid) = $ticket->Create(
        Subject   => 'test',
        Queue     => $queue->id,
    );
    ok $tid, 'ticket created';
}

diag "check that things don't work if there is no key";
{
    unlink "t/mailbox";

    ok $agent->goto_ticket( $tid ), "UI -> ticket #$tid";
    $agent->follow_link_ok( { text => 'Reply' }, 'ticket -> reply' );
    $agent->form_number(3);
    $agent->tick( Encrypt => 1 );
    $agent->field( UpdateCc => 'rt-test@example.com' );
    $agent->field( UpdateContent => 'Some content' );
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

    $agent->next_warning_like(qr/public key not found|No public key/) for 1 .. 2;
    $agent->no_leftover_warnings_ok;
}

diag "import first key of rt-test\@example.com";
my $fpr1 = '';
{
    RT::Test->import_gnupg_key('rt-test@example.com', 'public');
    my %res = RT::Crypt->GetKeysInfo('rt-test@example.com');
    is $res{'info'}[0]{'TrustLevel'}, 0, 'is not trusted key';
    $fpr1 = $res{'info'}[0]{'Fingerprint'};
}

diag "check that things still doesn't work if key is not trusted";
{
    unlink "t/mailbox";

    ok $agent->goto_ticket( $tid ), "UI -> ticket #$tid";
    $agent->follow_link_ok( { text => 'Reply' }, 'ticket -> reply' );
    $agent->form_number(3);
    $agent->tick( Encrypt => 1 );
    $agent->field( UpdateCc => 'rt-test@example.com' );
    $agent->field( UpdateContent => 'Some content' );
    $agent->click('SubmitTicket');
    $agent->content_like(
        qr/You are going to encrypt outgoing email messages/i,
        'problems with keys'
    );
    $agent->content_like(
        qr/There is one suitable key, but trust level is not set/i,
        'problems with keys'
    );

    my $form = $agent->form_number(3);
    ok my $input = $form->find_input( 'UseKey-rt-test@example.com' ), 'found key selector';
    is scalar $input->possible_values, 1, 'one option';

    $agent->select( 'UseKey-rt-test@example.com' => $fpr1 );
    $agent->click('SubmitTicket');
    $agent->content_like(
        qr/You are going to encrypt outgoing email messages/i,
        'problems with keys'
    );
    $agent->content_like(
        qr/Selected key either is not trusted/i,
        'problems with keys'
    );

    my @mail = RT::Test->fetch_caught_mails;
    ok !@mail, 'there are no outgoing emails';
}

diag "import a second key of rt-test\@example.com";
my $fpr2 = '';
{
    RT::Test->import_gnupg_key('rt-test@example.com.2', 'public');
    my %res = RT::Crypt->GetKeysInfo('rt-test@example.com');
    is $res{'info'}[1]{'TrustLevel'}, 0, 'is not trusted key';
    $fpr2 = $res{'info'}[2]{'Fingerprint'};
}

diag "check that things still doesn't work if two keys are not trusted";
{
    unlink "t/mailbox";

    ok $agent->goto_ticket( $tid ), "UI -> ticket #$tid";
    $agent->follow_link_ok( { text => 'Reply' }, 'ticket -> reply' );
    $agent->form_number(3);
    $agent->tick( Encrypt => 1 );
    $agent->field( UpdateCc => 'rt-test@example.com' );
    $agent->field( UpdateContent => 'Some content' );
    $agent->click('SubmitTicket');
    $agent->content_like(
        qr/You are going to encrypt outgoing email messages/i,
        'problems with keys'
    );
    $agent->content_like(
        qr/There are several keys suitable for encryption/i,
        'problems with keys'
    );

    my $form = $agent->form_number(3);
    ok my $input = $form->find_input( 'UseKey-rt-test@example.com' ), 'found key selector';
    is scalar $input->possible_values, 2, 'two options';

    $agent->select( 'UseKey-rt-test@example.com' => $fpr1 );
    $agent->click('SubmitTicket');
    $agent->content_like(
        qr/You are going to encrypt outgoing email messages/i,
        'problems with keys'
    );
    $agent->content_like(
        qr/Selected key either is not trusted/i,
        'problems with keys'
    );

    my @mail = RT::Test->fetch_caught_mails;
    ok !@mail, 'there are no outgoing emails';
}

{
    RT::Test->lsign_gnupg_key( $fpr1 );
    my %res = RT::Crypt->GetKeysInfo('rt-test@example.com');
    ok $res{'info'}[0]{'TrustLevel'} > 0, 'trusted key';
    is $res{'info'}[1]{'TrustLevel'}, 0, 'is not trusted key';
}

diag "check that we see key selector even if only one key is trusted but there are more keys";
{
    unlink "t/mailbox";

    ok $agent->goto_ticket( $tid ), "UI -> ticket #$tid";
    $agent->follow_link_ok( { text => 'Reply' }, 'ticket -> reply' );
    $agent->form_number(3);
    $agent->tick( Encrypt => 1 );
    $agent->field( UpdateCc => 'rt-test@example.com' );
    $agent->field( UpdateContent => 'Some content' );
    $agent->click('SubmitTicket');
    $agent->content_like(
        qr/You are going to encrypt outgoing email messages/i,
        'problems with keys'
    );
    $agent->content_like(
        qr/There are several keys suitable for encryption/i,
        'problems with keys'
    );

    my $form = $agent->form_number(3);
    ok my $input = $form->find_input( 'UseKey-rt-test@example.com' ), 'found key selector';
    is scalar $input->possible_values, 2, 'two options';

    my @mail = RT::Test->fetch_caught_mails;
    ok !@mail, 'there are no outgoing emails';
}

diag "check that key selector works and we can select trusted key";
{
    unlink "t/mailbox";

    ok $agent->goto_ticket( $tid ), "UI -> ticket #$tid";
    $agent->follow_link_ok( { text => 'Reply' }, 'ticket -> reply' );
    $agent->form_number(3);
    $agent->tick( Encrypt => 1 );
    $agent->field( UpdateCc => 'rt-test@example.com' );
    $agent->field( UpdateContent => 'Some content' );
    $agent->click('SubmitTicket');
    $agent->content_like(
        qr/You are going to encrypt outgoing email messages/i,
        'problems with keys'
    );
    $agent->content_like(
        qr/There are several keys suitable for encryption/i,
        'problems with keys'
    );

    my $form = $agent->form_number(3);
    ok my $input = $form->find_input( 'UseKey-rt-test@example.com' ), 'found key selector';
    is scalar $input->possible_values, 2, 'two options';

    $agent->select( 'UseKey-rt-test@example.com' => $fpr1 );
    $agent->click('SubmitTicket');
    $agent->content_like( qr/Correspondence added/i, 'ticket updated' );

    my @mail = RT::Test->fetch_caught_mails;
    ok @mail, 'there are some emails';
    check_text_emails( { Encrypt => 1 }, @mail );
}

diag "check encrypting of attachments";
{
    unlink "t/mailbox";

    ok $agent->goto_ticket( $tid ), "UI -> ticket #$tid";
    $agent->follow_link_ok( { text => 'Reply' }, 'ticket -> reply' );
    $agent->form_number(3);
    $agent->tick( Encrypt => 1 );
    $agent->field( UpdateCc => 'rt-test@example.com' );
    $agent->field( UpdateContent => 'Some content' );
    $agent->field( Attachment => $0 );
    $agent->click('SubmitTicket');
    $agent->content_like(
        qr/You are going to encrypt outgoing email messages/i,
        'problems with keys'
    );
    $agent->content_like(
        qr/There are several keys suitable for encryption/i,
        'problems with keys'
    );

    my $form = $agent->form_number(3);
    ok my $input = $form->find_input( 'UseKey-rt-test@example.com' ), 'found key selector';
    is scalar $input->possible_values, 2, 'two options';

    $agent->select( 'UseKey-rt-test@example.com' => $fpr1 );
    $agent->click('SubmitTicket');
    $agent->content_like( qr/Correspondence added/i, 'ticket updated' );

    my @mail = RT::Test->fetch_caught_mails;
    ok @mail, 'there are some emails';
    check_text_emails( { Encrypt => 1, Attachment => 1 }, @mail );
}


done_testing;

sub check_text_emails {
    my %args = %{ shift @_ };
    my @mail = @_;

    ok scalar @mail, "got some mail";
    for my $mail (@mail) {
        for my $type ('email', 'attachment') {
            next if $type eq 'attachment' && !$args{'Attachment'};

            my $content = $type eq 'email'
                        ? "Some content"
                        : "Attachment content";

            if ( $args{'Encrypt'} ) {
                unlike $mail, qr/$content/, "outgoing $type was encrypted";
            } else {
                like $mail, qr/$content/, "outgoing $type was not encrypted";
            } 

            next unless $type eq 'email';

            if ( $args{'Sign'} && $args{'Encrypt'} ) {
                like $mail, qr/BEGIN PGP MESSAGE/, 'outgoing email was signed';
            } elsif ( $args{'Sign'} ) {
                like $mail, qr/SIGNATURE/, 'outgoing email was signed';
            } else {
                unlike $mail, qr/SIGNATURE/, 'outgoing email was not signed';
            }
        }
    }
}


