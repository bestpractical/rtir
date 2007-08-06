#!/usr/bin/perl

# Load this in test scripts with: require "t/rtir-test.pl";
# *AFTER* loading in Test::More.

# Note that this runs on an
# *INSTALLED* copy of RTIR, with a running server.

use strict;
use warnings;

use HTTP::Cookies;
use Test::More;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt3/local/lib /opt/rt3/lib);

use RT;
ok(RT::LoadConfig, "Loaded configuration");
ok(RT::Init, "Basic initialization and DB connectivity");

require $RT::BasePath. '/lib/t/utils.pl';

my $RTIR_TEST_USER = "rtir_test_user";
my $RTIR_TEST_PASS = "rtir_test_pass";

use RT::Test::Web;

sub default_agent { 
    my $agent = new RT::Test::Web;
    $agent->cookie_jar( HTTP::Cookies->new );
    $agent->login($RTIR_TEST_USER, $RTIR_TEST_PASS);
    go_home($agent);
    return $agent;
}

sub set_custom_field {
    my $agent = shift;
    my $cf_name = shift;
    my $val = shift;
    my $field_name = $agent->value($cf_name) or return 0;
    $agent->field($field_name, $val);
    return 1;
}

sub go_home {
    my $agent = shift;
    my $weburl = RT->Config->Get('WebURL');
    $agent->get_ok("$weburl/RTIR/index.html", "Loaded home page");
}

sub display_ticket {
    my $agent = shift;
    my $id = shift;

    $agent->get_ok(RT->Config->Get('WebURL') . "/RTIR/Display.html?id=$id", "Loaded Display page for Ticket #$id");
}

sub ticket_state {
	my $agent = shift;
	my $id = shift;
	
	display_ticket($agent, $id);
	$agent->content =~ qr{State:\s*</td>\s*<td[^>]*?>\s*<span class="cf-value">([\w ]+)</span>}ism;
	return $1;
}

sub ticket_state_is {
    my $agent = shift;
    my $id = shift;
    my $state = shift;
    my $desc = shift || "State of the ticket #$id is '$state'";
    display_ticket( $agent, $id );
    $agent->content =~ qr{State:\s*</td>\s*<td[^>]*?>\s*<span class="cf-value">([\w ]+)</span>}ism;
    return is($1, $state, $desc);
}

sub ticket_is_linked_to_inc {
    my $agent = shift;
    my $id = shift;
    my $incs = shift;
    my $desc = shift;
    display_ticket( $agent, $id );
    foreach my $inc( ref $incs? @$incs : ($incs) ) {
        my $desc = shift || "Ticket #$id is linked to the Incident #$inc";
        $agent->content_like(
            qr{Incident:\s*</td>\s*<td[^>]*?>.*?\Q$inc:}ism,
            $desc || "Ticket #$id is linked to the Incident #$inc"
        ) or return 0;
    }
    return 1;
}

sub ticket_is_not_linked_to_inc {
    my $agent = shift;
    my $id = shift;
    my $incs = shift;
    my $desc = shift;
    display_ticket( $agent, $id );
    foreach my $inc( @$incs ) {
        my $desc = shift || "Ticket #$id is linked to the Incident #$inc";
        $agent->content_unlike(
            qr{Incident:\s*</td>\s*<td[^>]*?>.*?\Q$inc:}ism,
            $desc || "Ticket #$id is not linked to the Incident #$inc"
        ) or return 0;
    }
    return 1;
}

sub create_user {
    my $user_obj = rtir_user();

    if ($user_obj->Id) {
        $user_obj->SetDisabled(0);
        $user_obj->SetPrivileged(1);
        $user_obj->SetPassword($RTIR_TEST_PASS);
    } else {
        $user_obj->Create(Name => $RTIR_TEST_USER,
                          Password => $RTIR_TEST_PASS,
                          EmailAddress => "$RTIR_TEST_USER\@example.com",
                          RealName => "$RTIR_TEST_USER Smith",
                          Privileged => 1);
    }

    ok($user_obj->Id > 0, "Successfully found the user");
    
    my $group_obj = RT::Group->new(RT::SystemUser());
    $group_obj->LoadUserDefinedGroup("DutyTeam");
    ok($group_obj->Id > 0, "Successfully found the DutyTeam group");

    $group_obj->AddMember($user_obj->Id);
    ok($group_obj->HasMember($user_obj->PrincipalObj), "user is in the group");
}

sub rtir_user {
    my $u = RT::User->new(RT::SystemUser());
    $u->Load($RTIR_TEST_USER);
    return $u;
}

sub create_incident {
    return create_rtir_ticket( shift, 'Incidents', @_ );
}
sub create_ir {
    return create_rtir_ticket( shift, 'Incident Reports', @_ );
}
sub create_investigation {
    return create_rtir_ticket( shift, 'Investigations', @_ );
}
sub create_block {
    return create_rtir_ticket( shift, 'Blocks', @_ );
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

    go_home($agent);

    $agent->follow_link_ok({text => $queue, n => "1"}, "Followed '$queue' link");
    $agent->follow_link_ok({text => "New ". $type{ $queue }, n => "1"}, "Followed 'New $type{$queue}' link");

    # set the form
    $agent->form_number(3);
}

sub create_rtir_ticket
{
    my $agent = shift;
    my $queue = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    goto_create_rtir_ticket($agent, $queue);

    $fields->{'Requestors'} ||= $RTIR_TEST_USER if $queue eq 'Investigations';
    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }

    my %create = (
        'Incident Reports' => 'Create',
        'Investigations'   => 'Create',
        'Blocks'           => 'Create',
        'Incidents'        => 'CreateIncident'
    );
    # Create it!
    $agent->click( $create{ $queue } );
    
    is ($agent->status, 200, "Attempted to create the ticket");

    # Now see if we succeeded
    my $id = get_ticket_id($agent);
    ok ($id, "Created ticket #$id in queue '$queue' successfully.");

    return $id;
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
    $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");

    $agent->form_number(3);

    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }

    $agent->click("CreateIncident");
    
    is ($agent->status, 200, "Attempting to create new incident linked to child $ir_id");

    ok ($agent->content =~ /.*Ticket (\d+) created in queue.*/g, "Incident created from child $ir_id.");
    my $incident_id = $1;

#    diag("incident ID is $incident_id");
    return $incident_id;
}

sub ok_and_content_like {
    my $agent = shift;
    my $re = shift;
    my $desc = shift || "looks good";
    
    is($agent->status, 200, "request successful");
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
    	last unless $agent->follow_link(text => 'Next Page');
    }
    
    $agent->form_number(3);
    
    $agent->field("SelectedTicket", $incident);

    $agent->click("LinkChild");

    is ($agent->status, 200, "Attempting to link child $id to Incident $incident");

    ok ($agent->content =~ /Ticket $id: Link created/g, "Incident $incident linked successfully.");

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
		my $url = "Merge.html?id=$id&Order=ASC&Query=( 'CF.{_RTIR_State}' = 'new' OR 'CF.{_RTIR_State}' = 'open' AND 'id' > $max)";
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
    
    is ($agent->status, 200, "Attempting to merge $type #$id to ticket #$id_to_merge_to");
	
	$agent->content_like(qr{.*<ul class="action-results">\s*<li>Merge Successful</li>.*}i, 
    	"Successfully merged $type #$id to ticket #$id_to_merge_to");
}


sub create_incident_and_investigation {
	my $agent = shift;
    my $fields = shift || {};
    my $cfs = shift || {};
	my $ir_id = shift;

    $ir_id ? display_ticket($agent, $ir_id) : go_home($agent);

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
        set_custom_field($agent, $f, $v);
    }
    $agent->click("CreateWithInvestigation");
    my $msg = $ir_id
        ? "Attempting to create new incident and investigation linked to child $ir_id"
        : "Attempting to create new incident and investigation";
    is ($agent->status, 200, $msg);
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
