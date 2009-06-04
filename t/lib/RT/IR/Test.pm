use strict;
use warnings;

package RT::IR::Test;
use base qw(Test::More);
use Cwd;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt3/local/lib /opt/rt3/lib);

eval 'use RT::Test; 1'
    or Test::More::plan skip_all => "requires 3.8 to run tests. Error:\n$@\nYou may need to set PERL5LIB=/path/to/rt/lib";

use RT::Test::Web;

our @EXPORT = qw(
    default_agent
    set_custom_field
    display_ticket
    ticket_state
    ticket_state_is
    ticket_is_linked_to_inc
    ticket_is_not_linked_to_inc
    rtir_user
    create_incident
    create_ir
    create_investigation
    create_block
    goto_create_rtir_ticket
    create_rtir_ticket_ok
    create_rtir_ticket
    get_ticket_id
    create_incident_for_ir
    ok_and_content_like
    LinkChildToIncident
    merge_ticket
    create_incident_and_investigation
);

sub import_extra {
    my $class = shift;
    my $args  = shift;

    # Spit out a plan (if we got one) *before* we load modules, in
    # case of compilation errors
    $class->builder->plan(@{$args})
      unless $class->builder->has_plan;

    Test::More->export_to_level(2);

    # Now, clobber Test::Builder::plan (if we got given a plan) so we
    # don't try to spit one out *again* later.  Test::Builder::Module 
    # plans for you in import
    if ($class->builder->has_plan) {
        no warnings 'redefine';
        *Test::Builder::plan = sub {};
    }

    # we need to lie to RT and have it find RTFM's mason templates 
    # in the local directory
    {
        require RT::Plugin;
        no warnings 'redefine';
        my $cwd = getcwd;
        my $old_func = \&RT::Plugin::_BasePath;
        *RT::Plugin::_BasePath = sub {
            return $cwd if $_[0]->{name} eq 'RT::IR';
            if ( $_[0]->{name} eq 'RT::FM' ) {
                my ($path) = map $ENV{$_}, grep /^CHIMPS_RTFM.*_ROOT$/, keys %ENV;
                return $path if $path;
            }
            return $old_func->(@_);
        };
    }
    RT->Config->Set('Plugins',qw(RT::FM RT::IR));
    RT->InitPluginPaths;

    {
        require RT::Plugin;
        my $rtfm = RT::Plugin->new( name => 'RT::FM' );
        # RTFM's data

        Test::More::diag("RTFM path: ". $rtfm->Path('etc') );
        my ($ret, $msg) = $RT::Handle->InsertSchema( undef, $rtfm->Path('etc') );
        Test::More::ok($ret,"Created Schema: ".($msg||''));
        ($ret, $msg) = $RT::Handle->InsertACL( undef, $rtfm->Path('etc') );
        Test::More::ok($ret,"Created ACL: ".($msg||''));

        # RTIR's data
        ($ret, $msg) = $RT::Handle->InsertData('etc/initialdata');
        Test::More::ok($ret,"Created ACL: ".($msg||''));

        $RT::Handle->Connect;
    }

    RT->Config->LoadConfig( File => 'RTIR_Config.pm' );
    RT->Config->Set( 'rtirname' => 'regression_tests' );
    require RT::IR;
}

my $RTIR_TEST_USER = "rtir_test_user";
my $RTIR_TEST_PASS = "rtir_test_pass";

sub default_agent {
    my $agent = new RT::Test::Web;
    require HTTP::Cookies;
    $agent->cookie_jar( HTTP::Cookies->new );
    rtir_user();
    $agent->login($RTIR_TEST_USER, $RTIR_TEST_PASS);
    $agent->get_ok("/RTIR/index.html", "Loaded home page");
    return $agent;
}

sub set_custom_field {
    my $agent   = shift;
    my $queue   = shift;
    my $cf_name = shift;
    my $val     = shift;

    my $cf_obj = RT::CustomField->new( $RT::SystemUser );
    $cf_obj->LoadByName( Queue => $queue, Name => $cf_name );
    unless ( $cf_obj->id ) {
        Test::More::diag("Can not load custom field '$cf_name' in queue '$queue'");
        return 0;
    }
    my $cf_id = $cf_obj->id;
    
    my ($field_name) =
        grep /^Object-RT::Ticket-\d*-CustomField-$cf_id-Values?$/,
        map $_->name,
        $agent->current_form->inputs;
    unless ( $field_name ) {
        Test::More::diag("Can not find input for custom field '$cf_name' #$cf_id");
        return 0;
    }

    $agent->field($field_name, $val);
    return 1;
}

sub display_ticket {
    my $agent = shift;
    my $id = shift;

    $agent->get_ok("/RTIR/Display.html?id=$id", "Loaded Display page for Ticket #$id");
}

sub ticket_state {
    my $agent = shift;
    my $id = shift;
    
    display_ticket($agent, $id);
    my ($got) = ($agent->content =~ qr{State:\s*</td>\s*<td[^>]*?class="value"[^>]*?>\s*([\w ]+?)\s*</td>}ism);
    unless ( $got ) {
        Test::More::diag("Error: couldn't find state value on the page, may be regexp problem");
    }
    return $got;
}

sub ticket_state_is {
    my $agent = shift;
    my $id = shift;
    my $state = shift;
    my $desc = shift || "State of the ticket #$id is '$state'";
    return Test::More::is(ticket_state($agent, $id), $state, $desc);
}

sub ticket_is_linked_to_inc {
    my $agent = shift;
    my $id = shift;
    my $incs = shift;
    display_ticket( $agent, $id );
    foreach my $inc( ref $incs? @$incs : ($incs) ) {
        my $desc = shift || "Ticket #$id is linked to the Incident #$inc";
        $agent->content_like(
            qr{Incident:\s*</td>\s*<td[^>]*?>.*?<a\s+href="/RTIR/Display.html\?id=\Q$inc\E">\Q$inc\E:\s+}ism,
            $desc
        ) or return 0;
    }
    return 1;
}

sub ticket_is_not_linked_to_inc {
    my $agent = shift;
    my $id = shift;
    my $incs = shift;
    display_ticket( $agent, $id );
    foreach my $inc( @$incs ) {
        my $desc = shift || "Ticket #$id is not linked to the Incident #$inc";
        diag $agent->content;
        $agent->content_unlike(
            qr{Incident:\s*</td>\s*<td[^>]*?>.*?<a\s+href="/RTIR/Display.html\?id=\Q$inc\E">\Q$inc\E:\s+}ism,
            $desc
        ) or return 0;
    }
    return 1;
}

sub rtir_user {
    return RT::Test->load_or_create_user(
        Name         => $RTIR_TEST_USER,
        Password     => $RTIR_TEST_PASS,
        EmailAddress => "$RTIR_TEST_USER\@example.com",
        RealName     => "$RTIR_TEST_USER Smith",
        MemberOf     => 'DutyTeam',
    );
}

sub create_incident {
    return create_rtir_ticket_ok( shift, 'Incidents', @_ );
}
sub create_ir {
    return create_rtir_ticket_ok( shift, 'Incident Reports', @_ );
}
sub create_investigation {
    return create_rtir_ticket_ok( shift, 'Investigations', @_ );
}
sub create_block {
    return create_rtir_ticket_ok( shift, 'Blocks', @_ );
}

sub goto_create_rtir_ticket {
    my $agent = shift;
    my $queue = shift;

    my %type = (
        'Incident Reports' => 'Report',
        'Investigations'   => 'Investigation',
        'Blocks'           => 'Block',
        'Incidents'        => 'Incident'
    );

    $agent->get_ok("/RTIR/index.html", "Loaded home page");
    $agent->follow_link_ok({text => $queue, n => "1"}, "Followed '$queue' link");
    $agent->follow_link_ok({text => "New ". $type{ $queue }, n => "1"}, "Followed 'New $type{$queue}' link");
    

    # set the form
    $agent->form_number(3);
}

sub create_rtir_ticket_ok {
    my $agent = shift;
    my $queue = shift;

    my $id = create_rtir_ticket( $agent, $queue, @_ );
    Test::More::ok( $id, "Created ticket #$id in queue '$queue' successfully." );
    return $id;
}

sub create_rtir_ticket
{
    my $agent = shift;
    my $queue = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    goto_create_rtir_ticket($agent, $queue);
    
    #Enable test scripts to pass in the name of the owner rather than the ID
    if ($$fields{Owner} && $$fields{Owner} !~ /^\d+$/)
    {
        if($agent->content =~ qr{<option.+?value="(\d+)"\s*>$$fields{Owner}</option>}ims) {
            $$fields{Owner} = $1;
        }
    }
    

    $fields->{'Requestors'} ||= $RTIR_TEST_USER if $queue eq 'Investigations';
    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $queue, $f, $v);
    }

    my %create = (
        'Incident Reports' => 'Create',
        'Investigations'   => 'Create',
        'Blocks'           => 'Create',
        'Incidents'        => 'CreateIncident'
    );
    # Create it!
    $agent->click( $create{ $queue } );
    
    Test::More::is ($agent->status, 200, "Attempted to create the ticket");

    return get_ticket_id($agent);
}

sub get_ticket_id {
    my $agent = shift;
    my $content = $agent->content();
    my $id = 0;
    if ($content =~ /.*Ticket (\d+) created.*/g) {
        $id = $1;
    }
    elsif ($content =~ /.*No permission to view newly created ticket #(\d+).*/g) {
        diag("\nNo permissions to view the ticket.\n") if($ENV{'TEST_VERBOSE'});
        $id = $1;
    }
    return $id;
}


sub create_incident_for_ir {
    my $agent = shift;
    my $ir_id = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    display_ticket($agent, $ir_id);

    # Select the "New" link from the Display page
    $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link")
        or diag $agent->content;

    $agent->form_number(3);

    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, 'Incidents', $f, $v);
    }

    $agent->click("CreateIncident");
    
    Test::More::is ($agent->status, 200, "Attempting to create new incident linked to child $ir_id");

    Test::More::ok ($agent->content =~ /.*Ticket (\d+) created in queue.*/g, "Incident created from child $ir_id.");
    my $incident_id = $1;

#    diag("incident ID is $incident_id");
    return $incident_id;
}

sub ok_and_content_like {
    my $agent = shift;
    my $re = shift;
    my $desc = shift || "looks good";
    
    Test::More::is($agent->status, 200, "request successful");
    #like($agent->content, $re, $desc);
    $agent->content_like($re, $desc);
}


sub LinkChildToIncident {

    my $agent = shift;
    my $id = shift;
    my $incident = shift;

    display_ticket($agent, $id);

    # Select the "Link" link from the Display page
    $agent->follow_link_ok({text => "[Link]", n => "1"}, "Followed 'Link(to Incident)' link");

    
    # Check that the desired incident occurs in the list of available incidents; if not, keep
    # going to the next page until you find it (or get to the last page and don't find it,
    # whichever comes first)
    while($agent->content() !~ m|<a href="/Ticket/Display.html\?id=$incident">$incident</a>|) {
        last unless $agent->follow_link(text => 'Next');
    }
    
    $agent->form_number(3);
    
    $agent->field("SelectedTicket", $incident);

    $agent->click("LinkChild");

    Test::More::is ($agent->status, 200, "Attempting to link child $id to Incident $incident");

    Test::More::ok ($agent->content =~ /Ticket\s+$id:\s*Ticket\s+$id\s+member\s+of\s+Ticket\s+$incident/gs, "Incident $incident linked successfully.");

    return;
}


sub merge_ticket {
    my $agent = shift;
    my $id = shift;
    my $id_to_merge_to = shift;
    
    display_ticket($agent, $id);
    
    $agent->timeout(600);
    
    $agent->follow_link_ok({text => 'Merge', n => '1'}, "Followed 'Merge' link");
    
    $agent->content() =~ /Merge ([\w ]+) #$id:/i;
    my $type = $1 || 'Ticket';
    

    # Check that the desired incident occurs in the list of available incidents; if not, keep
    # going to the next page until you find it (or get to the last page and don't find it,
    # whichever comes first)
    while($agent->content() !~ m|<a href="/Ticket/Display.html\?id=$id_to_merge_to">$id_to_merge_to</a>|) {
        my @ids = sort map s|<b>\s*<a href="/Ticket/Display.html?id=(\d+)">\1</a>\s*</b>|$1|, split /<td/, $agent->content();
        my $max = pop @ids;
        my $url = "Merge.html?id=$id&Order=ASC&Query=( 'CF.{State}' = 'new' OR 'CF.{State}' = 'open' AND 'id' > $max)";
        my $weburl = RT->Config->Get('WebURL');
        diag("IDs found: " . join ', ', @ids);
        diag("Max ID: " . $max);
        diag ("URL: " . $url);
        $agent->get("$weburl/RTIR/$url");
        last unless $agent->content() =~ qr|<b>\s*<a href="/Ticket/Display.html?id=(\d+)">\1</a>\s*</b>|sm;
    }
    
    
    $agent->form_number(3);
    
    
    $agent->field("SelectedTicket", $id_to_merge_to);
    $agent->click_button(value => 'Merge');
    
    Test::More::is ($agent->status, 200, "Attempting to merge $type #$id to ticket #$id_to_merge_to");
    
    $agent->content_like(qr{.*<ul class="action-results">\s*<li>Merge Successful</li>.*}i, 
        "Successfully merged $type #$id to ticket #$id_to_merge_to");
}


sub create_incident_and_investigation {
    my $agent = shift;
    my $fields = shift || {};
    my $cfs = shift || {};
    my $ir_id = shift;

    $ir_id ? display_ticket($agent, $ir_id)
        : $agent->get_ok("/RTIR/index.html", "Loaded home page");

    if($ir_id) {
        # Select the "New" link from the Display page
        $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");
    }
    else 
    {
        $agent->follow_link_ok({text => "Incidents"}, "Followed 'Incidents' link");
        $agent->follow_link_ok({text => "New Incident", n => '1'}, "Followed 'New Incident' link");
    }

    # Fill out forms
    $agent->form_number(3);

    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, 'Incidents', $f, $v);
    }
    $agent->click("CreateWithInvestigation");
    my $msg = $ir_id
        ? "Attempting to create new incident and investigation linked to child $ir_id"
        : "Attempting to create new incident and investigation";
    Test::More::is ($agent->status, 200, $msg);
    $msg = $ir_id ? "Incident created from child $ir_id." : "Incident created.";

    my $re = qr/.*Ticket (\d+) created in queue &#39;Incidents&#39;/;
    $agent->content_like( $re, $msg );
      my ($incident_id) = ($agent->content =~ $re);
      
    $re = qr/.*Ticket (\d+) created in queue &#39;Investigations&#39;/;
    $agent->content_like( $re, "Investigation created for Incident $incident_id." );
    my ($investigation_id) = ($agent->content =~ $re);

    return ($incident_id, $investigation_id);
}

1;
