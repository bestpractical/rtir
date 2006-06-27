use inc::Module::Install;

RTx('RT-IR');
license('GPL Version 2');
author('Best Practical Solutions <sales@bestpractical.com>');
version('2.0.0');

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

requires('DBIx::SearchBuilder', 1.40);
requires('Business::Hours');
requires('Business::SLA');
requires('Net::Whois::RIPE');
auto_install();

substitute( {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
    },
    't/rtir-test.pl'
);

WriteAll();
