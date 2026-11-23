#!/usr/bin/perl

use strict;
use warnings;

use RT::IR::Test tests => undef;

# Keep the stock statuses, but capitalize them
{
    my %lifecycles = RT->Config->Get('Lifecycles');
    my $uc         = sub { my $status = shift; $status =~ /^[a-z]/ ? ucfirst $status : $status };

    for my $name (qw(incidents incident_reports)) {
        my $lifecycle = $lifecycles{$name};

        $lifecycle->{$_} = [ map { $uc->($_) } @{ $lifecycle->{$_} || [] } ] for qw(initial active inactive);
        $lifecycle->{defaults}{$_} = $uc->( $lifecycle->{defaults}{$_} ) for keys %{ $lifecycle->{defaults} };
        $lifecycle->{transitions} = {
            map { $uc->($_) => [ map { $uc->($_) } @{ $lifecycle->{transitions}{$_} } ] }
                keys %{ $lifecycle->{transitions} }
        };

        my @actions = @{ $lifecycle->{actions} };
        for ( my $i = 0; $i < @actions; $i += 2 ) {
            $actions[$i] = join ' -> ', map { $uc->($_) } split /\s*->\s*/, $actions[$i];
        }
        $lifecycle->{actions} = \@actions;
    }

    RT->Config->Set( Lifecycles => %lifecycles );
    RT::Lifecycle->FillCache;
}

is_deeply(
    [ RT::Lifecycle->Load( Name => 'incidents' )->Valid ],
    [qw(Open Resolved Abandoned)],
    'incidents statuses are capitalized'
);
is_deeply(
    [ RT::Lifecycle->Load( Name => 'incident_reports' )->Valid ],
    [qw(New Open Resolved Rejected)],
    'incident reports statuses are capitalized'
);

is( RT::IR->MapStatus( 'Resolved',  'incidents'        => 'incident_reports' ), 'resolved',  'mapped Resolved' );
is( RT::IR->MapStatus( 'Abandoned', 'incidents'        => 'incident_reports' ), 'rejected',  'mapped Abandoned' );
is( RT::IR->MapStatus( 'Rejected',  'incident_reports' => 'incidents' ),        'abandoned', 'mapped Rejected' );

for my $status (qw(Resolved Abandoned)) {
    my $incident = RT::Test->create_ticket( Queue => 'Incidents', Subject => "incident to be $status" );
    is( $incident->Status, 'Open', 'incident is Open' );

    my $report = RT::Test->create_ticket(
        Queue    => 'Incident Reports',
        Subject  => "report of incident to be $status",
        MemberOf => $incident->id,
    );
    is( $report->Status, 'Open', 'report linked to an incident is Open' );

    my ( $ok, $msg ) = $incident->SetStatus($status);
    ok( $ok, "set incident to $status" ) or diag $msg;

    DBIx::SearchBuilder::Record::Cachable->FlushCache;
    $report->Load( $report->id );
    is(
        $report->Status,
        $status eq 'Resolved' ? 'Resolved' : 'Rejected',
        "report followed its incident to $status"
    );
}

done_testing;
