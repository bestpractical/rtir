use inc::Module::Install;

RTx('RT-IR');
license('GPL Version 2');
author('Best Practical Solutions <sales@bestpractical.com>');
version_from('lib/RT/IR.pm');

requires_rt('4.0.11');

# XXX: This should be reported by M::I::RTx
my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

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
    },
    'etc/upgrade/upgrade.pl',
    'etc/add_constituency',
    'lib/RT/IR/Test.pm',
);

tests("t/*.t t/*/*.t");

WriteAll();
