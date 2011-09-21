#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => 20;

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
    $agent->content_like(qr{test inc});
    $agent->content_unlike(qr{test ir});

    $agent->get_ok( '/RTIR/index.html?q=192.168.1.1' );
    $agent->content_like(qr{test ir});
}
