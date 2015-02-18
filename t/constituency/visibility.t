use strict;
use warnings;

use Test::More skip_all => 'constituencies being rebuilt';
use RT::IR::Test tests => undef;

my @constituencies = qw(EDUNET GOVNET third);

my $constituency_cf = RT::CustomField->new(RT->SystemUser);
{
    my ($ok, $msg) = $constituency_cf->LoadByName(Queue => 'Incident Reports', Name => 'Constituency');
    ok($ok, "Loaded Constituency CF: $msg");
}

# users who will have limited access to the system
# the default_agent user is a member of the DutyTeam and as such
# can see any/all constituencies.
my $eduhandler = RT::Test->load_or_create_user( Name => 'eduhandler', Password => 'eduhandler' );
ok $eduhandler->id, "Created eduhandler";
my $govhandler = RT::Test->load_or_create_user( Name => 'govhandler', Password => 'govhandler' );
ok $govhandler->id, "Created govhandler";
# this user has read only access to the GOVNET constituency
my $rogovhandler = RT::Test->load_or_create_user( Name => 'rogovhandler', Password => 'rogovhandler' );
ok $rogovhandler->id, "Created rogovhandler";

{
    my $path = RT::Plugin->new( name => 'RT::IR' )->Path( 'bin' ) . "/add_constituency";
    diag("running $path to set up EDUNET and GOVNET constituencies");

    for my $constituency (@constituencies) {
        my ($exit_code, $output) = RT::Test->run_and_capture(
                command     => $path,
                name        => $constituency,
                force       => 1,
                quiet       => 1,
            );
         ok(!$exit_code, "created constituency $constituency");
         diag "output: $output";
    }

# Actually use the newly created Queues/Groups that come from add_constituency
# This means that eduhandler should be able to see/change EDUNET tickets
# but not GOVNET tickets and vice versa.
# Neither should be able to see the third constituency

    my $edugroup = RT::Group->new(RT->SystemUser);
    my ($ok, $msg) = $edugroup->LoadUserDefinedGroup('DutyTeam EDUNET');
    ok($ok, "Loaded DutyTeam EDUNET: $msg");

    ($ok,$msg) = $edugroup->AddMember($eduhandler->PrincipalObj->Id);
    ok($ok, "Added eduhandler to DutyTeam EDUNET: $msg");

    my $govgroup = RT::Group->new(RT->SystemUser);
    ($ok, $msg) = $govgroup->LoadUserDefinedGroup('DutyTeam GOVNET');
    ok($ok, "Loaded DutyTeam GOVNET: $msg");

    ($ok,$msg) = $govgroup->AddMember($govhandler->PrincipalObj->Id);
    ok($ok, "Added govhandler to DutyTeam GOVNET: $msg");

    my $rogovgroup = RT::Group->new(RT->SystemUser);
    ($ok, $msg) = $rogovgroup->LoadUserDefinedGroup('ReadOnly GOVNET');
    ok($ok, "Loaded ReadOnly GOVNET: $msg");

    ($ok,$msg) = $rogovgroup->AddMember($rogovhandler->PrincipalObj->Id);
    ok($ok, "Added rogovhandler to ReadOnly GOVNET: $msg");

}

my ($baseurl) = RT::Test->started_ok;
my $agent = default_agent();


diag("Ensure that DutyTeam members can see all the constituencies");
{
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "'$queue' queue";

        $agent->goto_create_rtir_ticket( $queue );

        my @values = $agent->current_form->find_input("Object-RT::Ticket--CustomField-". $constituency_cf->id ."-Values")->possible_values;
        is_deeply([sort @values],[sort @constituencies],"All the expected constituencies are available to DutyTeam on $queue");
    }
}

my %constituency_tickets;
diag("Create tickets in the different constituencies so we can test visibility");
{
    # Blocks require an Incident unless we futz %RTIR_IncidentChildren and we're being lazy and just making standalone tickets
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', ) {
        foreach my $const ( @constituencies ) {
            my $id = $agent->create_rtir_ticket_ok(
                    $queue,
                    { Subject => "test ip", Owner => 'Nobody' },
                    { Constituency => $const },
            );

            push @{$constituency_tickets{$const}}, $id;
        }
    }
}

diag("Ensure that DutyTeam EDUNET members can see only one constituency ");
{
    $agent->login( eduhandler => 'eduhandler', logout => 1 );
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "'$queue' queue";

        $agent->goto_create_rtir_ticket( $queue );

        my @values = $agent->current_form->find_input("Object-RT::Ticket--CustomField-". $constituency_cf->id ."-Values")->possible_values;
        is_deeply([sort @values],['EDUNET'],"Only EDUNET is available to eduhandler on $queue");
    }
}

diag("Ensure that DutyTeam EDUNET members can only see tickets in their constituency");
{
    $agent->login( eduhandler => 'eduhandler', logout => 1 );

    for my $const (@constituencies) {
        for my $ticket (@{$constituency_tickets{$const}}) {
            $agent->display_ticket($ticket);
            if ($const eq 'EDUNET') {
                $agent->text_contains('test ip',"Can see the ticket's subject");
            } else {
                $agent->text_contains('No permission to view ticket');
            }
        }
    }

    my $current_user = RT::CurrentUser->new; $current_user->Load('eduhandler');
    my $tickets = RT::Tickets->new($current_user);
    $tickets->FromSQL("Status = 'new' or Status = 'open'");
    my @ids;
    while (my $tick = $tickets->Next) {
        push @ids, $tick->Id;
    }
    is_deeply([sort @ids],[sort @{$constituency_tickets{'EDUNET'}}],"Only sees new tickets in the EDUNET constituency");
}

diag("Ensure that DutyTeam GOVNET members can see only one constituency ");
{
    $agent->login( govhandler => 'govhandler', logout => 1 );
    foreach my $queue( 'Incidents', 'Incident Reports', 'Investigations', 'Blocks' ) {
        diag "'$queue' queue";

        $agent->goto_create_rtir_ticket( $queue );

        my @values = $agent->current_form->find_input("Object-RT::Ticket--CustomField-". $constituency_cf->id ."-Values")->possible_values;
        is_deeply([sort @values],['GOVNET'],"Only GOVNET is available to govhandler on $queue");
    }
}

diag("Ensure that DutyTeam GOVNET members can only see tickets in their constituency");
{
    $agent->login( govhandler => 'govhandler', logout => 1 );

    for my $const (@constituencies) {
        for my $ticket (@{$constituency_tickets{$const}}) {
            $agent->display_ticket($ticket);
            if ($const eq 'GOVNET') {
                $agent->text_contains('test ip',"Can see the ticket's subject");
                ok($agent->find_link(text => 'Take'), "User can Take tickets");
            } else {
                $agent->text_contains('No permission to view ticket');
            }
        }
    }

    my $current_user = RT::CurrentUser->new; $current_user->Load('govhandler');
    my $tickets = RT::Tickets->new($current_user);
    $tickets->FromSQL("Status = 'new' or Status = 'open'");
    my @ids;
    while (my $tick = $tickets->Next) {
        push @ids, $tick->Id;
    }
    is_deeply([sort @ids],[sort @{$constituency_tickets{'GOVNET'}}],"Only sees new tickets in the GOVNET constituency");
}

diag("Ensure that ReadOnly GOVNET members can only see tickets in their constituency");
{
    $agent->login( rogovhandler => 'rogovhandler', logout => 1 );

    for my $const (@constituencies) {
        for my $ticket (@{$constituency_tickets{$const}}) {
            $agent->display_ticket($ticket);
            if ($const eq 'GOVNET') {
                $agent->text_contains('test ip',"Can see the ticket's subject");
                is($agent->find_link(text => 'Take'), undef, "No Take Link for the ReadOnly user");
            } else {
                $agent->text_contains('No permission to view ticket');
            }
        }
    }

    my $current_user = RT::CurrentUser->new; $current_user->Load('rogovhandler');
    my $tickets = RT::Tickets->new($current_user);
    $tickets->FromSQL("Status = 'new' or Status = 'open'");
    my @ids;
    while (my $tick = $tickets->Next) {
        push @ids, $tick->Id;
    }
    is_deeply([sort @ids],[sort @{$constituency_tickets{'GOVNET'}}],"Only sees new tickets in the GOVNET constituency");
}

done_testing;
