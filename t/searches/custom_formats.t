
use strict;
use warnings;

use RT::IR::Test tests => undef, config => q{Set(%RTIRSearchResultFormats,
    'ReportDefault' => q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',
'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',
QueueName,
Status,
LastUpdatedRelative,
CreatedRelative,
__NEWLINE__,
'',
Requestors,
OwnerName,
ToldRelative,
DueRelative,
TimeLeft,
'__CustomField.{How Reported}__'});};

RT::Test->started_ok;
my $agent = default_agent();

diag 'Confirm custom IR format is used';
{
    my $ir_id = $agent->create_ir( {
        Subject => 'test ir',
        Requestors => 'test@example.com',
    }, {
        IP => '192.168.1.1',
    });
    my $inc_id = $agent->create_incident_for_ir(
        $ir_id, { Subject => 'test inc' },
    );
    $agent->get_ok( '/RTIR/index.html', 'get rtir at glance page' );
    $agent->follow_link_ok(
        { text => "Incident Reports", n => '1' },
        "Followed 'Incidents Reports' link"
    );
    $agent->content_like( qr/test/, "the ticket is on the page");
    $agent->content_like( qr/How Reported/, "How Reported is on the page");
}

undef $agent;
done_testing;
