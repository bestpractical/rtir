#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $agent = default_agent();

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
    $agent->get_ok( '/RTIR/index.html?q=test%40example.com' );
    like($agent->dom->at('table.ticket-list')->all_text, qr{test inc});
    unlike($agent->dom->at('table.ticket-list')->all_text, qr{test ir});

    $agent->get_ok( '/RTIR/index.html?q=192.168.1.1' );
    like($agent->dom->at('table.ticket-list')->all_text, qr{test ir});

    $agent->get_ok( "/RTIR/index.html?q=$inc_id" );
    is($agent->uri,$agent->rt_base_url."RTIR/Incident/Display.html?id=$inc_id","Directed to the Incident Page");

    $agent->get_ok( "/RTIR/index.html?q=$ir_id" );
    is($agent->uri,$agent->rt_base_url."RTIR/Display.html?id=$ir_id","Directed to the Report Page");
}

done_testing;
