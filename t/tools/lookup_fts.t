use strict;
use warnings;

use RT::IR::Test tests => undef;

my $dbtype = RT->Config->Get('DatabaseType');
if ( $dbtype eq 'SQLite' ) {
    diag "Indexed FTS is not supported on SQLite, skipping FTS-dependent assertions";
    done_testing;
    exit 0;
}

# Configure FTS for the active database type, mirroring RT's per-DB FTS
# test setup (t/fts/indexed_mysql.t, indexed_pg.t, indexed_oracle.t).
my %fts_config = ( Enable => 1, Indexed => 1 );
if ( $dbtype eq 'Pg' ) {
    $fts_config{Column} = 'ContentIndex';
    $fts_config{Table}  = 'AttachmentsIndex';
}
elsif ( $dbtype eq 'Oracle' ) {
    $fts_config{IndexName} = 'rt_fts_index';
}
else {
    # mysql/mariadb
    $fts_config{Table} = 'AttachmentsIndex';
}
RT->Config->Set( FullTextSearch => %fts_config );

use RT::Test::FTS;
RT::Test::FTS->setup_indexing();

RT::Test->started_ok;
my $agent = default_agent();

my $email = 'lookup-test@example.com';

my $ir = $agent->create_ir(
    { Subject => 'Email lookup FTS test', Content => "Investigation involving $email" },
);

RT::Test::FTS->sync_index();

diag "Test Lookup page with an email address (containing '\@') and FTS enabled";
{
    $agent->get_ok(
        "/RTIR/Tools/Lookup.html?ticket=$ir&type=email&q=$email",
        "Loaded Lookup page for $email",
    );
    $agent->content_contains( $email, 'Lookup page rendered for the email' );
    $agent->content_like(
        qr{Incident Reports: \Q$email\E.*?Email lookup FTS test}s,
        'Found the test ticket in search results on lookup',
    );

    $agent->content_lacks(
        '&#40;no Incident Reports&#41;',
        'IR appears in the Incident Reports lookup results',
    );
}

my $host = 'bad-host.example.com';

my $host_ir = $agent->create_ir(
    { Subject => 'Host lookup FTS test', Content => "Investigation involving $host" },
);

RT::Test::FTS->sync_index();

diag "Test Lookup page with a hostname (containing '-') and FTS enabled";
{
    $agent->get_ok(
        "/RTIR/Tools/Lookup.html?ticket=$host_ir&type=host&q=$host",
        "Loaded Lookup page for $host",
    );
    $agent->content_contains( $host, 'Lookup page rendered for the host' );
    $agent->content_like(
        qr{Incident Reports: \Q$host\E.*?Host lookup FTS test}s,
        'Found the test ticket in search results on lookup',
    );

    $agent->content_lacks(
        '&#40;no Incident Reports&#41;',
        'IR appears in the Incident Reports lookup results',
    );
}

diag "Test Lookup page with values that do not appear in any ticket";
{
    my $missing_email = 'nomatch-test@example.org';
    $agent->get_ok(
        "/RTIR/Tools/Lookup.html?ticket=$ir&type=email&q=$missing_email",
        "Loaded Lookup page for $missing_email",
    );
    $agent->content_contains(
        '&#40;no Incident Reports&#41;',
        'No IR is reported for an email that is not indexed',
    );

    my $missing_host = 'nonexistent-host.example.org';
    $agent->get_ok(
        "/RTIR/Tools/Lookup.html?ticket=$host_ir&type=host&q=$missing_host",
        "Loaded Lookup page for $missing_host",
    );
    $agent->content_contains(
        '&#40;no Incident Reports&#41;',
        'No IR is reported for a host that is not indexed',
    );
}

done_testing;
