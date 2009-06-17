use strict;
use warnings;

package RT::IR::Test;
use base qw(Test::More);
use Cwd;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt3/local/lib /opt/rt3/lib);

eval 'use RT::Test; 1'
    or Test::More::plan skip_all => "requires 3.8 to run tests. Error:\n$@\nYou may need to set PERL5LIB=/path/to/rt/lib";

use RT::IR::Test::Web;

our @EXPORT = qw(
    default_agent
    rtir_user
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

1;
