use inc::Module::Install;

RTx('RT-IR');
license('GPL Version 2');
author('Best Practical Solutions <sales@bestpractical.com>');
version_from('lib/RT/IR.pm');

{ # check RT version
    my @v = split /\./, "$RT::VERSION";
    unless ($v[0]>=3 && $v[1]>=8 && ($v[2]>=1 || $v[2]eq'HEAD')) {
        die "RTIR 2.4 and newer needs RT 3.8.1 at least, you have $RT::VERSION";
    }
}

# XXX: This should be reported by M::I::RTx
my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

# XXX: we can not depend on RT::FM as new plugin system
# is not ready for that
#requires('RT::FM');

# RTIR needs this version of SB cuz of bug-fix
requires('DBIx::SearchBuilder', 1.51);

# work hours
requires('Business::Hours');
# service level agreement
requires('Business::SLA');
# whois tool
requires('Net::Whois::RIPE');
# IP searching
requires('Hook::LexWrap');
requires('Regexp::Common');
# CIDR parsing and converting
requires('Net::CIDR');
requires('Regexp::Common::net::CIDR');

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
    't/lib/RT/IR/Test.pm',
);

tests("t/*.t t/*/*.t");

WriteAll();
