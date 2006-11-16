use inc::Module::Install;

RTx('RT-IR');
license('GPL Version 2');
author('Best Practical Solutions <sales@bestpractical.com>');
version_from('lib/RT/IR.pm');

{ # check RT version
    my @v = split /\./, "$RT::VERSION";
    unless ($v[0]>=3 && $v[1]>=7) {
        die "RTIR 2.0 needs RT 3.7.0 at least, you have $RT::VERSION";
    }
}

# XXX: This should be reported by M::I::RTx
my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";

unshift @INC, $local_lib_path, $lib_path;
requires('RT::FM');

# RTIR needs this version of SB due lack
# of features in priviouse
requires('DBIx::SearchBuilder', 1.40);

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

build_requires('Test::More');
build_requires('File::Find');

auto_install();

substitute( {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
    },
    't/rtir-test.pl',
    'etc/upgrade/upgrade.pl'
);

WriteAll();
