use inc::Module::Install;

RTx('RT-IR');
license('GPL Version 2');
author('Best Practical Solutions <sales@bestpractical.com>');
#description('RT extension for Incident Response');
version('1.9.HEAD');

requires('DBIx::SearchBuilder', 1.40);
requires('Business::Hours');
requires('Business::SLA');
requires('Net::Whois::RIPE');
auto_install();

my ($lp) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );

substitute( {
        RT_LIB_PATH => $lib_path,
    },
    't/rtir-test.pl'
);

WriteAll();
