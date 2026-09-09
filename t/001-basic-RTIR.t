#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

my $SUBJECT = "foo " . rand;

# Create a report
my $report = $agent->create_ir( {Subject => $SUBJECT, Content => "bla" });

{
    my $ir_obj = RT::Ticket->new(RT::SystemUser());

    $ir_obj->Load($report);
    is($ir_obj->Id, $report, "report has right ID");
    is($ir_obj->Subject, $SUBJECT, "subject is right");
}


# Create a new Incident from that report
my $first_incident_id = $agent->create_incident_for_ir( $report, {Subject => "first incident"},
                                               {Function => "IncidentCoord"});

# TODO: make sure subject and content come from Report

# TODO: create Incident with new subject/content

# TODO: make sure all fields are set properly in DB

# create a new incident
my $second_incident_id = $agent->create_incident( { Subject => "foo Incident", Content => "bar baz quux" } );

# link our report to that incident
$agent->LinkChildToIncident( $report, $second_incident_id);

# TODO: verify in DB that report has 1 parent, and the right parent

# Confirm we show the rich text editor for Incident comment since that is now
# default for RT
diag("Incident comment loaded rich text editor");
{
    ok($agent->display_ticket( $first_incident_id ), "Displayed incident ticket");
    $agent->follow_link_ok({text => "Comment"}, "Followed link to comment");
    $agent->content_contains("id=\"UpdateContentType\" value=\"text/html\"", "Update content type is html");
}

# Create incident with investigation and check if it's created correctly
diag 'Test the creation of an incident with investigation';
$agent->goto_create_rtir_ticket('Incidents');
$agent->form_name('TicketCreate');
$agent->field('Subject', 'Incident with an Investigation');
$agent->field('Content', 'Content of Incident with an Investigation');
$agent->field('Requestors', 'root@localhost');
$agent->field('InvestigationRequestors', 'root@localhost');
$agent->field('InvestigationSubject', 'Investigation created for test incident');
$agent->field('InvestigationContent', 'Content of the Investigation');
$agent->click('CreateWithInvestigation');
$agent->content_like(qr/Incident #\d+: Incident with an Investigation/, 'Incident number generated');
$agent->content_like(qr/Ticket \d+ created in queue &#39;Incidents&#39;/, 'Incident created message');
$agent->content_like(qr/Ticket \d+ created in queue &#39;Investigations&#39;/, 'Investigation created message');
$agent->content_like(qr/Ticket \d+ member of Ticket \d+/, 'Investigation linked to Incident');
$agent->follow_link_ok({text => 'Investigation created for test incident'}, 'Followed link to investigation');
$agent->content_contains('Content of the Investigation', 'Investigation content is correct');

diag 'Reverse history order on RTIR display pages';
{
    my $user = rtir_user();

    my %pages = (
        '/RTIR/Display.html'          => $report,
        '/RTIR/Incident/Display.html' => $first_incident_id,
    );

    # Order is only observable with more than one transaction to order.
    for my $id ( sort { $a <=> $b } values %pages ) {
        my $ticket = RT::Ticket->new( RT->SystemUser );
        $ticket->Load($id);
        my ($ok, $msg) = $ticket->Comment( Content => 'a second transaction' );
        ok( $ok, "commented on ticket $id" ) or diag $msg;
    }

    my $set_show_history = sub {
        my $mode = shift;
        my ($ok, $msg) = $user->SetPreferences( $RT::System => { ShowHistory => $mode } );
        ok( $ok, "set the ShowHistory preference to '$mode'" ) or diag $msg;
    };

    my $rendered_txn_ids = sub {
        my ($path, $id, $reverse) = @_;
        $agent->get_ok( "$path?ForceShowHistory=1;ReverseTxns=$reverse;id=$id",
            "loaded $path for ticket $id with ReverseTxns=$reverse" );
        return [
            map { $_->attr('data-transaction-id') }
                grep { !$_->matches('.end-of-history-list') }
                $agent->dom->find('div.transaction')->each
        ];
    };

    $set_show_history->('always');
    for my $path ( sort keys %pages ) {
        my $id   = $pages{$path};
        my $asc  = $rendered_txn_ids->( $path, $id, 'ASC' );
        my $desc = $rendered_txn_ids->( $path, $id, 'DESC' );
        cmp_ok( scalar @$asc, '>=', 2,
            "$path renders at least 2 transactions for ticket $id" );
        is_deeply( $desc, [ reverse @$asc ],
            "$path renders history in the reverse order for ticket $id" );
    }

    # These modes fetch the history over a second request, so the order has to
    # survive into the URL that request is made with. That URL is embedded in
    # JavaScript, where "/" arrives as either "\/" or "\x2F".
    my $unescaped_content = sub {
        my $content = $agent->content;
        $content =~ s{\\x([0-9a-fA-F]{2})}{chr hex $1}ge;
        $content =~ s{\\/}{/}g;
        return $content;
    };

    for my $mode (qw/delay click/) {
        $set_show_history->($mode);
        for my $path ( sort keys %pages ) {
            my $id = $pages{$path};
            $agent->get_ok( "$path?ReverseTxns=DESC;id=$id",
                "loaded $path for ticket $id in '$mode' mode" );
            like( $unescaped_content->(),
                qr{/Helpers/TicketHistory\?[^"']*\bReverseTxns=DESC\b},
                "$path passes ReverseTxns to the history helper in '$mode' mode" );
        }
    }

    $set_show_history->('scroll');
    for my $path ( sort keys %pages ) {
        my $id = $pages{$path};
        for my $case ( [ DESC => 0 ], [ ASC => 1 ] ) {
            my ($reverse, $oldest_first) = @$case;
            $agent->get_ok( "$path?ReverseTxns=$reverse;id=$id",
                "loaded $path for ticket $id in 'scroll' mode with ReverseTxns=$reverse" );
            like( $agent->content,
                qr{\bvar\s+oldestTransactionsFirst\s*=\s*\Q$oldest_first\E\s*;},
                "$path scrolls with oldestTransactionsFirst=$oldest_first for ReverseTxns=$reverse" );
        }
    }

    my ($ok, $msg) = $user->DeletePreferences($RT::System);
    ok( $ok, 'deleted the ShowHistory preference' ) or diag $msg;
}

undef $agent;
done_testing;
