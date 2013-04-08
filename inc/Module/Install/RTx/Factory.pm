#line 1
package Module::Install::RTx::Factory;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

use strict;
use File::Basename ();

sub RTxInitDB {
    my ($self, $action, $name, $version) = @_;

    unshift @INC, substr(delete($INC{'RT.pm'}), 0, -5) if $INC{'RT.pm'};

    require RT;
    unshift @INC, "$RT::LocalPath/lib" if $RT::LocalPath;

    $RT::SbinPath ||= $RT::LocalPath;
    $RT::SbinPath =~ s/local$/sbin/;

    foreach my $file ($RT::CORE_CONFIG_FILE, $RT::SITE_CONFIG_FILE) {
        next if !-e $file or -r $file;
        die "No permission to read $file\n-- please re-run $0 with suitable privileges.\n";
    }

    RT::LoadConfig();

    require RT::System;

    my $lib_path = File::Basename::dirname($INC{'RT.pm'});
    my @args = ("-Ilib");
    push @args, "-I$RT::LocalPath/lib" if $RT::LocalPath;
    push @args, (
        "-I$lib_path",
        "$RT::SbinPath/rt-setup-database",
        "--action"      => $action,
        "--datadir"     => "etc",
        (($action eq 'insert') ? ("--datafile"    => "etc/initialdata") : ()),
        "--dba"         => $RT::DatabaseAdmin || $RT::DatabaseUser,
        "--prompt-for-dba-password" => '',
        (RT::System->can('AddUpgradeHistory') ? ("--package" => $name, "--ext-version" => $version) : ()),
    );

    print "$^X @args\n";
    (system($^X, @args) == 0) or die "...returned with error: $?\n";
}

1;
