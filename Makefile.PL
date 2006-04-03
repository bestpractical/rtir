use inc::Module::Install;

RTx('RT-IR');
license('GPL Version 2');
author('Best Practical Solutions <sales@bestpractical.com>');
version('1.9.HEAD');

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
