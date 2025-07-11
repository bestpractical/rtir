use strict;
use warnings;

use RT::IR::Test tests => undef;

my ($baseurl, $agent) = RT::Test->started_ok;
diag "Test server running at: $baseurl";

my $m = default_agent();

my %viewed = ( '/NoAuth/Logout.html' => 1 );    # in case logout

my $first_incident  = $m->create_incident({ Subject => "test Incident" });
my $second_incident = $m->create_incident({ Subject => "other test Incident" }); 

# the built-in create_incident_report doesn't support linking to multiple incidents
# despite this being added as an explicit feature in 2.4.0. I'm assuming
# it's never actually been tested before. This code wants to be cleaned
# up and shove into RT::IR::Test::Web but it's kind of ugly.
my $ir = create_incident_report({Subject => "test Report", Incidents => [$first_incident,$second_incident]});

my $extra_incident = $m->create_incident({ Subject => "further test Incident" }); 

{ diag("Keep both Incident parents - the default");
    $m->display_ticket($ir);
    $m->follow_link_ok({text => "Split"}, "Followed link");
    $m->form_number(3);

    # TODO: check the split form to see if the second incident is being displayed twice
    my @ir_params = $m->current_form->param('Incident');
    is($ir_params[0], $first_incident, "First incident is checked");
    is($ir_params[1], $second_incident, "Second incident is checked");

    $m->click_ok('SubmitTicket',"Split the Report");

    my $new_ir = $m->get_ticket_id;
    my $report = load_ticket($new_ir);

    my $new_incidents = RT::IR->Incidents($report);
    is($new_incidents->Count,2);
    is_deeply([sort map { $_->Id } @{$new_incidents->ItemsArrayRef}],[$first_incident,$second_incident],"Properly linked to the second incident");
}

{ diag("Splitting the report and keeping the second Incident");
    $m->display_ticket($ir);
    $m->follow_link_ok({text => "Split"}, "Followed link");
    $m->form_number(3);

    my @ir_params = $m->current_form->param('Incident');
    is($ir_params[0], $first_incident, "First incident is checked");
    is($ir_params[1], $second_incident, "Second incident is checked");

    $m->untick('Incident',1);
    $m->click_ok('SubmitTicket',"Split the Report");

    my $new_ir = $m->get_ticket_id;
    my $report = load_ticket($new_ir);

    my $new_incidents = RT::IR->Incidents($report);
    is($new_incidents->Count,1);
    is($new_incidents->First->Id,$second_incident,"Properly linked to the second incident");
}

{ diag("Splitting the report and applying it to a third unrelated incident");
    $m->display_ticket($ir);
    $m->follow_link_ok({text => "Split"}, "Followed link");
    $m->form_number(3);

    my @ir_params = $m->current_form->param('Incident');
    is($ir_params[0], $first_incident, "First incident is checked");
    is($ir_params[1], $second_incident, "Second incident is checked");

    $m->untick('Incident',1);
    $m->untick('Incident',2);
    $m->field('Incident',$extra_incident,3);
    $m->click_ok('SubmitTicket',"Split the Report");

    my $new_ir = $m->get_ticket_id;
    my $report = load_ticket($new_ir);

    my $new_incidents = RT::IR->Incidents($report);
    is($new_incidents->Count,1);
    is($new_incidents->First->Id,$extra_incident,"Properly linked to the third incident");
}


sub load_ticket {
    my $id = shift;
    my $ticket = RT::Ticket->new(RT->SystemUser);
    $ticket->Load($id);
    is($ticket->Id,$id,"Loaded IR $id");
    return $ticket;
}

sub create_incident_report {
    my $args = shift;
    my $incidents = delete $args->{Incidents};
    $m->goto_create_rtir_ticket('Incident Reports');

    # because the Other Incident and the checkboxes are all named
    # Incident, we have to indicate which field named Incident we want.
    my $count = 1;
    for my $incident (@$incidents) {
        $m->field('Incident',$incident,$count++);
        $m->click_ok('MoreIncident',"Add incident $incident to the IR");
        $m->form_number(3);
    }

    while (my ($f, $v) = each %$args) {
        $m->field($f, $v);
    }
    $m->click('SubmitTicket');

    my $ir = $m->get_ticket_id;
    my $report = load_ticket($ir);
    is(RT::IR->IsLinkedToActiveIncidents($report),scalar @$incidents,"Created an IR linked to ".scalar @$incidents." Incidents");
    return $ir;
}

done_testing;
