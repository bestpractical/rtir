use inc::Module::Install;

RTx('RT-IR');
license('GPL Version 2');
author('Best Practical Solutions <sales@bestpractical.com>');
version_from('lib/RT/IR.pm');

# update README and docs/UPGRADING
requires_rt('4.0.14rc1');

# XXX: This should be reported by M::I::RTx
my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

# Straight from perldoc perlvar
use Config;
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS') {
    $secure_perl_path .= $Config{_exe}
    unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

# RTIR needs this version of SB because of cud-from-select
requires('DBIx::SearchBuilder', 1.61);

# whois tool
requires('Net::Whois::RIPE');
# IP searching
requires('Hook::LexWrap');
requires('Regexp::Common');
# queries parsing
requires('Parse::BooleanLogic');

# for tests
build_requires('Test::More');
build_requires('File::Find');
# for etc/upgrade/upgrade.pl
build_requires('File::Temp');

auto_install();

substitute( {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
        PERL        => $ENV{PERL} || $secure_perl_path,
    },
    { sufix => '.in' },
    'etc/upgrade/upgrade.pl',
    'etc/add_constituency',
    'lib/RT/IR/Test.pm',
    'etc/upgrade/2.5.1/update_saved_searches.pl',
);

tests("t/*.t t/*/*.t");

WriteAll();
