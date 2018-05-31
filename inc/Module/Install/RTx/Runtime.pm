#line 1
package Module::Install::RTx::Runtime;

use base 'Exporter';
our @EXPORT = qw/RTxDatabase RTxPlugin/;

use strict;
use File::Basename ();

sub _rt_runtime_load {
    require RT;

    eval { RT::LoadConfig(); };
    if (my $err = $@) {
        die $err unless $err =~ /^RT couldn't load RT config file/m;
        my $warn = <<EOT;
This usually means that your current user cannot read the file.  You
will likely need to run this installation step as root, or some user
with more permissions.
EOT
        $err =~ s/This usually means.*/$warn/s;
        die $err;
    }
}

sub RTxDatabase {
    my ($action, $name, $version) = @_;

    _rt_runtime_load();

    require RT::System;
    my $has_upgrade = RT::System->can('AddUpgradeHistory');

    my $lib_path = File::Basename::dirname($INC{'RT.pm'});
    my @args = (
        "-I.",
        "-Ilib",
        "-I$RT::LocalLibPath",
        "-I$lib_path",
        "$RT::SbinPath/rt-setup-database",
        "--action"      => $action,
        ($action eq 'upgrade' ? () : ("--datadir"     => "etc")),
        (($action eq 'insert') ? ("--datafile"    => "etc/initialdata") : ()),
        "--dba"         => $RT::DatabaseAdmin || $RT::DatabaseUser,
        "--prompt-for-dba-password" => '',
        ($has_upgrade ? ("--package" => $name, "--ext-version" => $version) : ()),
    );
    # If we're upgrading against an RT which isn't at least 4.2 (has
    # AddUpgradeHistory) then pass --package.  Upgrades against later RT
    # releases will pick up --package from AddUpgradeHistory.
    if ($action eq 'upgrade' and not $has_upgrade) {
        push @args, "--package" => $name;
    }

    print "$^X @args\n";
    (system($^X, @args) == 0) or die "...returned with error: $?\n";
}

sub RTxPlugin {
    my ($name) = @_;

    _rt_runtime_load();
    require YAML::Tiny;
    my $data = YAML::Tiny::LoadFile('META.yml');
    my $name = $data->{name};

    my @enabled = RT->Config->Get('Plugins');
    for my $required (@{$data->{x_requires_rt_plugins} || []}) {
        next if grep {$required eq $_} @enabled;

        warn <<"EOT";

**** Warning: $name requires that the $required plugin be installed and
              enabled; it is not currently in \@Plugins.

EOT
    }
}

1;
