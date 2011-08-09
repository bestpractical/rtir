use strict;
use warnings;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt4/local/lib /opt/rt4/lib);

package RT::IR::Test;

our @ISA;
BEGIN {
    local $@ = undef;
    eval { require RT::Test; 1 } or do {
        require Test::More;
        Test::More::BAIL_OUT(
            "requires 3.8 to run tests. Error:\n$@\n"
            ."You may need to set PERL5LIB=/path/to/rt/lib"
        );
    };
    push @ISA, 'RT::Test';
}

use RT::IR::Test::Web;

our @EXPORT = qw(
    default_agent
    rtir_user
);

sub import {
    my $class = shift;
    my %args  = @_;

    $args{'requires'} ||= [];
    if ( $args{'testing'} ) {
        unshift @{ $args{'requires'} }, 'RT::IR';
    } else {
        $args{'testing'} = 'RT::IR';
    }

    $class->SUPER::import( %args );
    $class->export_to_level(1);

    RT->Config->Set( 'rtirname' => 'regression_tests' );
}

our $RTIR_TEST_USER = "rtir_test_user";
our $RTIR_TEST_PASS = "rtir_test_pass";

sub default_agent {
    my $agent = new RT::IR::Test::Web;
    require HTTP::Cookies;
    $agent->cookie_jar( HTTP::Cookies->new );
    rtir_user();
    $agent->login($RTIR_TEST_USER, $RTIR_TEST_PASS);
    $agent->get_ok("/RTIR/index.html", "Loaded home page");
    return $agent;
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

sub import_snapshot {
    my $self = shift;
    my $file = shift;

    my $db_type = RT->Config->Get('DatabaseType');

    if ( $db_type eq 'mysql' ) {
        my @args = ('-u', $ENV{'RT_DBA_USER'});
        if ( length $ENV{'RT_DBA_PASSWORD'} ) {
            push @args, '--password='. $ENV{'RT_DBA_PASSWORD'}
        }
        push @args, RT->Config->Get('DatabaseName');
        my $cmd = $ENV{'RT_TEST_MYSQL_CLIENT'} || 'mysql';

        Test::More::diag("About to run `". join(' ', $cmd, @args) ."`");

        open my $fh, "|-", $cmd, @args
            or die "couldn't run mysql: $!";
        print $fh $self->file_content( ['t','data', 'snapshot', $db_type, $file] );
        close $fh;

        RT::Test::__reconnect_rt();
    } else {
        die "Importing snapshot is not implemented for $db_type";
    }
}

sub apply_upgrade {
    my $self = shift;
    my $base_dir = shift;
    my @versions = @_;

    my $db_type = RT->Config->Get('DatabaseType');
    foreach my $n ( 0..$#versions ) {
        my $v = $versions[$n];

        my $datadir = "$base_dir/$v";
        if ( -e "$datadir/schema.$db_type" ) {
            my ( $ret, $msg ) = RT::Handle->InsertSchema( get_admin_dbh(), $datadir );
            return ( $ret, $msg ) unless $ret;
        }
        if ( -e "$datadir/acl.$db_type" ) {
            my ( $ret, $msg ) = RT::Handle->InsertACL( get_admin_dbh(), $datadir );
            return ( $ret, $msg ) unless $ret;
        }
        if ( -e "$datadir/content" ) {
            RT::Test::__reconnect_rt();
            my ( $ret, $msg ) = $RT::Handle->InsertData( "$datadir/content" );
            return ( $ret, $msg ) unless $ret;
        }
    }
    RT::Test::__reconnect_rt();
}

sub get_admin_dbh {
    return _get_dbh( RT::Handle->DSN, $ENV{'RT_DBA_USER'}, $ENV{'RT_DBA_PASSWORD'} );
}

sub _get_dbh {
    my ($dsn, $user, $pass) = @_;
    my $dbh = DBI->connect(
        $dsn, $user, $pass,
        { RaiseError => 0, PrintError => 0 },
    );
    unless ( $dbh ) {
        my $msg = "Failed to connect to $dsn as user '$user': ". $DBI::errstr;
        print STDERR $msg; exit -1;
    }
    return $dbh;
}

1;
