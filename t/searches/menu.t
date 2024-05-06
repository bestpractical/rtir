use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $m = default_agent();

my %ticket;

for my $subject (qw/foo bar baz/) {
    for my $type ( 'incident', 'ir', 'investigation', 'countermeasure' ) {
        my $create_sub = "create_$type";
        push @{ $ticket{$type} },
            $m->$create_sub(
            {
                Subject => "$type $subject",
                $type eq 'incident' ? () : ( Incident => $ticket{incident}[-1] ),
            }
            );
    }
}

# Merge
for my $type ( 'incident', 'ir', 'investigation', 'countermeasure' ) {
    $m->display_ticket( $ticket{$type}[0] );
    $m->follow_link_ok( { text => 'Merge' } );
    $m->title_like(qr/Merge .+ #$ticket{$type}[0]:/);

    if ($type eq 'incident') { 
        for my $id ( @{ $ticket{$type} }[ 1 .. 2 ] ) {
         ok( $m->find_link( url_regex => qr{/RTIR/Incident/Display.html\?id=$id$} ), "found link to $type $id" );
        } 
    } else {
        for my $id ( @{ $ticket{$type} }[ 1 .. 2 ] ) {
         ok( $m->find_link( url_regex => qr{/RTIR/Display.html\?id=$id$} ), "found link to $type $id" );
        } 

    }

    $m->follow_link_ok( { text => "Edit Search" } );
    $m->form_name('BuildQuery');
    $m->submit_form_ok(
        {
            with_fields => { idOp => '!=', ValueOfid => $ticket{$type}[1] },
            button      => 'DoSearch'
        },
        "add new term 'id != $ticket{$type}[1]'"
    );

    if ($type eq 'incident') {
    ok( !$m->find_link( url_regex => qr{/RTIR/Incident/Display.html\?id=$ticket{$type}[1]$} ),
        "didn't find link to $type $ticket{$type}[1]" );
    ok( $m->find_link( url_regex => qr{/RTIR/Incident/Display.html\?id=$ticket{$type}[2]$} ),
        "found link to $type $ticket{$type}[2]" );
    } else {

    ok( !$m->find_link( url_regex => qr{/RTIR/Display.html\?id=$ticket{$type}[1]$} ),
        "didn't find link to $type $ticket{$type}[1]" );
    ok( $m->find_link( url_regex => qr{/RTIR/Display.html\?id=$ticket{$type}[2]$} ),
        "found link to $type $ticket{$type}[2]" );
    }

}

# Link ToIncident
{

    $m->display_ticket( $ticket{ir}[0] );
    $m->follow_link_ok( { id => 'link-incident' } );
    $m->title_is("Link Report #$ticket{ir}[0] to selected Incident");

    ok( !$m->find_link( url_regex => qr{/RTIR/Incident/Display.html\?id=$ticket{incident}[0]$} ),
        "didn't find link to incident $ticket{incident}[0]" );
    for my $incident_id ( @{ $ticket{incident} }[ 1 .. 2 ] ) {
        ok( $m->find_link( url_regex => qr{/RTIR/Incident/Display.html\?id=$incident_id$} ),
            "found link to incident $incident_id" );
    }
    $m->follow_link_ok( { text => "Edit Search" } );
    $m->form_name('BuildQuery');
    my ($input_query) = $m->find_all_inputs( name => 'Query' );
    is( $input_query->value, q{( Lifecycle = 'incidents' ) AND Status = 'open' AND HasMember != 2}, 'Query input is correct' );

    $m->submit_form_ok(
        {
            with_fields => { idOp => '!=', ValueOfid => $ticket{incident}[1] },
            button      => 'DoSearch'
        },
        "add new term 'id != $ticket{incident}[1]'"
    );
    ok( !$m->find_link( url_regex => qr{/RTIR/Incident/Display.html\?id=$ticket{incident}[1]$} ),
        "didn't find link to incident $ticket{incident}[1]" );
    ok( $m->find_link( url_regex => qr{/RTIR/Incident/Display.html\?id=$ticket{incident}[2]$} ),
        "found link to incident $ticket{incident}[2]" );
}

# Link FromIncident
{
    $m->display_ticket( $ticket{incident}[0] );
    $m->follow_link_ok( { url_regex => qr{Link/FromIncident} } );
    $m->title_is("Link selected Report to Incident #$ticket{incident}[0]");

    ok(
        !$m->find_link(
            url_regex => qr{/RTIR/Display.html\?id=$ticket{ir}[0]$}
        ),
        "didn't find link to incident report $ticket{ir}[0]"
    );

    for my $ir ( @{ $ticket{ir} }[ 1 .. 2 ] ) {
        ok( $m->find_link( url_regex => qr{/RTIR/Display.html\?id=$ir$} ), "found link to incident report $ir" );
    }

    $m->follow_link_ok( { text => "Edit Search" } );
    $m->form_name('BuildQuery');
    my ($input_query) = $m->find_all_inputs( name => 'Query' );
    is(
        $input_query->value,
        q{( Lifecycle = 'incident_reports' ) AND ( Status = 'new' OR Status = 'open' ) AND MemberOf != 1},
        'Query input is correct'
    );

    $m->submit_form_ok(
        {
            with_fields => { idOp => '!=', ValueOfid => $ticket{ir}[1] },
            button      => 'DoSearch'
        },
        "add new term 'id != $ticket{ir}[1]'"
    );

    ok(
        !$m->find_link(
            url_regex => qr{/RTIR/Display.html\?id=$ticket{ir}[1]$}
        ),
        "didn't find link to incident report $ticket{ir}[1]"
    );

    ok( $m->find_link( url_regex => qr{/RTIR/Display.html\?id=$ticket{ir}[2]$} ),
        "found link to incident report $ticket{ir}[2]" );
}

# Incident Reply to Reporters
{
    $m->display_ticket( $ticket{incident}[0] );
    $m->follow_link_ok( { text => 'Reply to Reporters' } );
    $m->title_like(qr/#$ticket{incident}[0]: Reply to Reporters/);

    ok( $m->find_link( url_regex => qr{/RTIR/Display.html\?id=$ticket{ir}[0]$} ),
        "found link to incident report $ticket{ir}[0]" );

    for my $type (qw/investigation countermeasure/) {
        ok( !$m->find_link( url_regex => qr{/RTIR/Display.html\?id=$ticket{$type}[0]$} ),
            "didn't find link to $type $ticket{$type}[0]" );
    }

    $m->form_name('TicketUpdate');
    my ($checkbox) = $m->find_all_inputs( name => 'SelectedReports' );
    is( $checkbox->value, $ticket{ir}[0], '$ticket{ir}[0] is checked' );

    $m->follow_link_ok( { text => "Edit Search" } );
    $m->form_name('BuildQuery');
    $m->submit_form_ok(
        {
            with_fields => { idOp => '!=', ValueOfid => $ticket{ir}[0] },
            button      => 'DoSearch'
        },
        "add new term 'id != $ticket{ir}[0]'"
    );

    ok(
        !$m->find_link(
            url_regex => qr{/RTIR/Display.html\?id=$ticket{ir}[0]$},
            text      => $ticket{ir}[0],
            n         => 2,                     # there is one in "Attach Reports" widget
        ),
        "didn't find link to incident report $ticket{ir}[0]"
    );

    for my $type (qw/investigation countermeasure/) {
        ok( !$m->find_link( url_regex => qr{/RTIR/Display.html\?id=$ticket{$type}[0]$} ),
            "didn't find link to $type $ticket{$type}[0]" );
    }
}

# Incident Reply to All
{
    $m->display_ticket( $ticket{incident}[0] );
    $m->follow_link_ok( { text => 'Reply to All' } );
    $m->title_like(qr/#$ticket{incident}[0]: Reply to All/);

    for my $type (qw/ir investigation countermeasure/) {
        ok( $m->find_link( url_regex => qr{/RTIR/Display.html\?id=$ticket{$type}[0]$} ),
            "found link to $type $ticket{$type}[0]" );
    }
    $m->form_name('TicketUpdate');
    my ($checkbox) = $m->find_all_inputs( name => 'SelectedReports' );
    is( $checkbox->value, $ticket{ir}[0], '$ticket{ir}[0] is checked' );

    ($checkbox) = $m->find_all_inputs( name => 'SelectedInvestigations' );
    is( $checkbox->value, $ticket{investigation}[0], '$ticket{investigation}[0] is checked' );

    ($checkbox) = $m->find_all_inputs( name => 'SelectedCountermeasures' );
    is( $checkbox->value, $ticket{countermeasure}[0], '$ticket{countermeasure}[0] is checked' );

    $m->follow_link_ok( { text => "Edit Search" } );
    $m->form_name('BuildQuery');
    $m->submit_form_ok(
        {
            with_fields => { idOp => '!=', ValueOfid => $ticket{ir}[0] },
            button      => 'DoSearch'
        },
        "add new term 'id != $ticket{ir}[0]'"
    );

    ok(
        !$m->find_link(
            url_regex => qr{/RTIR/Display.html\?id=$ticket{ir}[0]$},
            text      => $ticket{ir}[0],
            n         => 2,                     # there is one in "Attach Reports" widget
        ),
        "didn't find link to incident report $ticket{ir}[0]"
    );

    for my $type (qw/investigation countermeasure/) {
        ok( $m->find_link( url_regex => qr{/RTIR/Display.html\?id=$ticket{$type}[0]$} ),
            "found link to $type $ticket{$type}[0]" );
    }
}

undef $m;
done_testing;
