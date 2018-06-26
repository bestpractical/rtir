BEGIN { push @INC, '.' }
use inc::Module::Install;

RTx('RT-IR', { no_readme_generation => 1, remove_files => 1 });
license('GPL Version 2');
author('Best Practical Solutions <sales@bestpractical.com>');
all_from('lib/RT/IR.pm');

# update README and docs/UPGRADING
requires_rt('4.6.0');  # NOTE: we’ll update this to 5.0.0 once an official 5.0.0 is available. fails for alpha tags otherwise.
rt_too_new('5.2.0',"\nThis version of RTIR is only compatible with RT 5.0.x and you are using RT %s\n");

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

# IP searching
requires('Regexp::Common');
# queries parsing
requires('Parse::BooleanLogic');

# Domain searching
requires('Net::Domain::TLD');

# for tests
build_requires('Test::More');
build_requires('File::Find');
# for etc/upgrade/rtir-2.4-upgrade.pl
build_requires('File::Temp');

auto_install();

substitute( {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
        PERL        => $ENV{PERL} || $secure_perl_path,
    },
    { sufix => '.in' },
    'etc/upgrade/rtir-2.4-upgrade.pl',
    'etc/add_constituency',
    'bin/add_constituency',
    'lib/RT/IR/Test.pm',
    'etc/upgrade/2.5.1/update_saved_searches.pl',
);

tests("t/*.t t/*/*.t");

postamble(<<POSTAMBLE
snapshot: dist sign-dist dist-shasums

sign-dist:
	gpg -a --detach-sign \$(DISTVNAME).tar.gz

dist-shasums:
	sha1sum \$(DISTVNAME).tar.gz*

parallel-test: test-parallel

test-parallel:
	RT_TEST_PARALLEL=1 \$(FULLPERLRUN) "-MApp::Prove" -e 'my \$\$p = App::Prove->new(); \$\$p->process_args("-wlrj5","--state=slow,save", "t"); exit( \$\$p->run() ? 0 : 1 )'
POSTAMBLE
);

WriteAll();
