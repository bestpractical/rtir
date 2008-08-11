use strict;
use warnings;

package RT::IR::Test;
use base qw(Test::More);
use Cwd;

eval 'use RT::Test; 1'
    or Test::More::plan skip_all => 'requires 3.8 to run tests.  You may need to set PERL5LIB=/path/to/rt/lib';

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
            return $old_func->(@_);
        };
    }
    RT->Config->Set('Plugins',qw(RT::FM RT::IR));
    RT->InitPluginPaths;

    {
        require RT::Plugin;
        my $rtfm = RT::Plugin->new( name => 'RT::FM' );
        # RTFM's data
        my ($ret, $msg) = $RT::Handle->InsertSchema( undef, $rtfm->Path('etc') );
        Test::More::ok($ret,"Created Schema: ".($msg||''));
        ($ret, $msg) = $RT::Handle->InsertACL( undef, $rtfm->Path('etc') );
        Test::More::ok($ret,"Created ACL: ".($msg||''));

        # RTIR's data
        ($ret, $msg) = $RT::Handle->InsertData('etc/initialdata');
        Test::More::ok($ret,"Created ACL: ".($msg||''));

        #$RT::Handle->Connect;
    }

    RT->Config->LoadConfig( File => 'RTIR_Config.pm' );
    RT->Config->Set( 'rtirname' => 'regression_tests' );
}

1;
