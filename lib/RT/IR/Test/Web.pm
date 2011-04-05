package RT::IR::Test::Web;

use strict;
use warnings;

use base qw(RT::Test::Web);

require RT::IR::Test;
require Test::More;

sub create_incident {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return (shift)->create_rtir_ticket_ok( 'Incidents', @_ );
}
sub create_ir {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return (shift)->create_rtir_ticket_ok( 'Incident Reports', @_ );
}
sub create_investigation {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return (shift)->create_rtir_ticket_ok( 'Investigations', @_ );
}
sub create_block {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return (shift)->create_rtir_ticket_ok( 'Blocks', @_ );
}

sub goto_create_rtir_ticket {
    my $self = shift;
    my $queue = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $equeue = $queue;
    $equeue =~ s/ /%20/;

    $self->get_ok("/RTIR/index.html", "Loaded home page");
    $self->follow_link_ok(
        {text => "Create", url_regex => qr{RTIR/Create\.html.*(?i:$equeue)} },
        "Followed create in '$queue' link"
    );

    # set the form
    $self->form_number(3);
}

sub create_rtir_ticket_ok {
    my $self = shift;
    my $queue = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $id = $self->create_rtir_ticket( $queue, @_ );
    Test::More::ok( $id, "Created ticket #$id in queue '$queue' successfully." );
    return $id;
}

sub create_rtir_ticket
{
    my $self = shift;
    my $queue = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    $self->goto_create_rtir_ticket($queue);
    
    #Enable test scripts to pass in the name of the owner rather than the ID
    if ($$fields{Owner} && $$fields{Owner} !~ /^\d+$/)
    {
        if($self->content =~ qr{<option.+?value="(\d+)"\s*>$$fields{Owner}</option>}ims) {
            $$fields{Owner} = $1;
        }
    }
    

    $fields->{'Requestors'} ||= $RT::IR::Test::RTIR_TEST_USER if $queue eq 'Investigations';
    while (my ($f, $v) = each %$fields) {
        $self->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        $self->set_custom_field($queue, $f, $v);
    }

    my %create = (
        'Incident Reports' => 'Create',
        'Investigations'   => 'Create',
        'Blocks'           => 'Create',
        'Incidents'        => 'CreateIncident'
    );
    # Create it!
    $self->click( $create{ $queue } );
    
    Test::More::is ($self->status, 200, "Attempted to create the ticket");

    return $self->get_ticket_id;
}

sub create_incident_for_ir {
    my $self = shift;
    my $ir_id = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    $self->display_ticket( $ir_id );

    # Select the "New" link from the Display page
    $self->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link")
        or diag $self->content;

    $self->form_number(3);

    while (my ($f, $v) = each %$fields) {
        $self->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        $self->set_custom_field( 'Incidents', $f, $v);
    }

    $self->click("CreateIncident");
    
    Test::More::is ($self->status, 200, "Attempting to create new incident linked to child $ir_id");

    Test::More::ok ($self->content =~ /.*Ticket (\d+) created in queue.*/g, "Incident created from child $ir_id.");
    my $incident_id = $1;

#    diag("incident ID is $incident_id");
    return $incident_id;
}

sub display_ticket {
    my $self = shift;
    my $id = shift;

    $self->get_ok("/RTIR/Display.html?id=$id", "Loaded Display page for Ticket #$id");
}

sub ticket_is_linked_to_inc {
    my $self = shift;
    my $id = shift;
    my $incs = shift;
    $self->display_ticket( $id );
    foreach my $inc( ref $incs? @$incs : ($incs) ) {
        my $desc = shift || "Ticket #$id is linked to the Incident #$inc";
        $self->content_like(
            qr{Incident:\s*</td>\s*<td[^>]*?>.*?<a\s+href="/RTIR/Display.html\?id=\Q$inc\E">\Q$inc\E:\s+}ism,
            $desc
        ) or return 0;
    }
    return 1;
}

sub ticket_is_not_linked_to_inc {
    my $self = shift;
    my $id = shift;
    my $incs = shift;
    $self->display_ticket( $id );
    foreach my $inc( @$incs ) {
        my $desc = shift || "Ticket #$id is not linked to the Incident #$inc";
        $self->content_unlike(
            qr{Incident:\s*</td>\s*<td[^>]*?>.*?<a\s+href="/RTIR/Display.html\?id=\Q$inc\E">\Q$inc\E:\s+}ism,
            $desc
        ) or return 0;
    }
    return 1;
}

sub ok_and_content_like {
    my $self = shift;
    my $re = shift;
    my $desc = shift || "looks good";
    
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is($self->status, 200, "request successful");
    #like($self->content, $re, $desc);
    $self->content_like($re, $desc);
}


sub LinkChildToIncident {

    my $self = shift;
    my $id = shift;
    my $incident = shift;

    $self->display_ticket( $id);

    # Select the "Link" link from the Display page
    $self->follow_link_ok({text => "[Link]", n => "1"}, "Followed 'Link(to Incident)' link");

    
    # Check that the desired incident occurs in the list of available incidents; if not, keep
    # going to the next page until you find it (or get to the last page and don't find it,
    # whichever comes first)
    while($self->content() !~ m|<a href="/Ticket/Display.html\?id=$incident">$incident</a>|) {
        last unless $self->follow_link(text => 'Next');
    }
    
    $self->form_number(3);
    
    $self->field("SelectedTicket", $incident);

    $self->click("LinkChild");

    Test::More::is ($self->status, 200, "Attempting to link child $id to Incident $incident");

    Test::More::ok ($self->content =~ /Ticket\s+$id:\s*Ticket\s+$id\s+member\s+of\s+Ticket\s+$incident/gs, "Incident $incident linked successfully.");

    return;
}


sub merge_ticket {
    my $self = shift;
    my $id = shift;
    my $id_to_merge_to = shift;
    
    $self->display_ticket( $id);
    
    $self->timeout(600);
    
    $self->follow_link_ok({text => 'Merge', n => '1'}, "Followed 'Merge' link");
    
    $self->content() =~ /Merge ([\w ]+) #$id:/i;
    my $type = $1 || 'Ticket';
    

    # Check that the desired incident occurs in the list of available incidents; if not, keep
    # going to the next page until you find it (or get to the last page and don't find it,
    # whichever comes first)
    while($self->content() !~ m|<a href="/Ticket/Display.html\?id=$id_to_merge_to">$id_to_merge_to</a>|) {
        my @ids = sort map s|<b>\s*<a href="/Ticket/Display.html?id=(\d+)">\1</a>\s*</b>|$1|, split /<td/, $self->content();
        my $max = pop @ids;
        my $url = "Merge.html?id=$id&Order=ASC&Query=( 'Status' = 'new' OR 'Status' = 'open' AND 'id' > $max)";
        my $weburl = RT->Config->Get('WebURL');
        Test::More::diag("IDs found: " . join ', ', @ids);
        Test::More::diag("Max ID: " . $max);
        Test::More::diag ("URL: " . $url);
        $self->get("$weburl/RTIR/$url");
        last unless $self->content() =~ qr|<b>\s*<a href="/Ticket/Display.html?id=(\d+)">\1</a>\s*</b>|sm;
    }
    
    
    $self->form_number(3);
    
    
    $self->field("SelectedTicket", $id_to_merge_to);
    $self->click_button(value => 'Merge');
    
    Test::More::is ($self->status, 200, "Attempting to merge $type #$id to ticket #$id_to_merge_to");
    
    $self->content_like(qr{.*<ul class="action-results">\s*<li>Merge Successful</li>.*}i, 
        "Successfully merged $type #$id to ticket #$id_to_merge_to");
}


sub create_incident_and_investigation {
    my $self = shift;
    my $fields = shift || {};
    my $cfs = shift || {};
    my $ir_id = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if($ir_id) {
        $self->display_ticket( $ir_id );
        # Select the "New" link from the Display page
        $self->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");
    }
    else 
    {
        $self->goto_create_rtir_ticket('Incidents');
    }

    # Fill out forms
    $self->form_number(3);

    while (my ($f, $v) = each %$fields) {
        $self->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        $self->set_custom_field( 'Incidents', $f, $v);
    }
    $self->click("CreateWithInvestigation");
    my $msg = $ir_id
        ? "Attempting to create new incident and investigation linked to child $ir_id"
        : "Attempting to create new incident and investigation";
    Test::More::is ($self->status, 200, $msg);
    $msg = $ir_id ? "Incident created from child $ir_id." : "Incident created.";

    my $re = qr/.*Ticket (\d+) created in queue &#39;Incidents&#39;/;
    $self->content_like( $re, $msg );
      my ($incident_id) = ($self->content =~ $re);
      
    $re = qr/.*Ticket (\d+) created in queue &#39;Investigations&#39;/;
    $self->content_like( $re, "Investigation created for Incident $incident_id." );
    my ($investigation_id) = ($self->content =~ $re);

    return ($incident_id, $investigation_id);
}

sub has_watchers {
    my $self = shift;
    my $id   = shift;
    my $type = shift || 'Correspondents';
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->display_ticket($id);

    $self->content_like(
qr{<td class="labeltop">Correspondents:</td>\s*<td class="value">\s*([@\w\.]+)\s*<br />}ms,
        "Found $type",
    );
}

sub goto_edit_block {
    my $self = shift;
    my $id   = shift;

    $self->display_ticket($id);

    $self->follow_link_ok( { text => 'Edit', n => '1' },
        "Followed 'Edit' (block) link" );
}

sub resolve_rtir_ticket {
    my $self = shift;
    my $id   = shift;
    my $type = shift || 'Ticket';

    $self->display_ticket($id);
    $self->follow_link_ok(
        { text => "Quick Resolve", n => "1" },
        "Followed 'Quick Resolve' link"
    );

    Test::More::is( $self->status, 200, "Attempting to resolve $type #$id" );

    $self->content_like(
        qr/.*Status changed from \S*\w+\S* to \S*resolved.*/,
        "Successfully resolved $type #$id"
    );
}

sub bulk_abandon {
    my $self       = shift;
    my @to_abandon = @_;

    Test::More::diag "going to bulk abandon incidents " . join ',', map "#$_",
      @to_abandon
      if $ENV{'TEST_VERBOSE'};

    $self->get_ok( '/RTIR/index.html', 'get rtir at glance page' );
    $self->follow_link_ok( { text => "Incidents", n => '1' },
        "Followed 'Incidents' link" );
    $self->follow_link_ok(
        { text => "Bulk Abandon", n => '1' },
        "Followed 'Bulk Abandon' link"
    );

    $self->content_unlike( qr/no incidents/i, 'have an incident' );

# Check that the desired incident occurs in the list of available incidents; if not, keep
# going to the next page until you find it (or get to the last page and don't find it,
# whichever comes first)
    while ( $self->content() !~
        qr{<a href="/Ticket/Display.html\?id=$to_abandon[0]">$to_abandon[0]</a>}
      )
    {
        last unless $self->follow_link( text => 'Next' );
    }

    $self->form_number(3);
    foreach my $id (@to_abandon) {
        $self->tick( 'SelectedTickets', $id );
    }

    $self->click('BulkAbandon');

    foreach my $id (@to_abandon) {
        $self->ok_and_content_like(
            qr{<li>Ticket $id: Status changed from \S*\w+\S* to \S*abandoned\S*</li>}i,
            "Incident $id abandoned" );
    }

    if ( $self->content =~ /no incidents/i ) {
        Test::More::ok( 1, 'no more incidents' );
    }
    else {
        $self->form_number(3);
        Test::More::ok( $self->value('BulkAbandon'), "Still on Bulk Abandon page" );
    }
}

1;
