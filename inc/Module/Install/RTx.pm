#line 1
package Module::Install::RTx;

use 5.008;
use strict;
use warnings;
no warnings 'once';

use Module::Install::Base;
use base 'Module::Install::Base';
our $VERSION = '0.41';

use FindBin;
use File::Glob     ();
use File::Basename ();

my @DIRS = qw(etc lib html static bin sbin po var);
my @INDEX_DIRS = qw(lib bin sbin);

sub RTx {
    my ( $self, $name, $extra_args ) = @_;
    $extra_args ||= {};

    # Set up names
    my $fname = $name;
    $fname =~ s!-!/!g;

    $self->name( $name )
        unless $self->name;
    $self->all_from( "lib/$fname.pm" )
        unless $self->version;
    $self->abstract("$name Extension")
        unless $self->abstract;
    unless ( $extra_args->{no_readme_generation} ) {
        $self->readme_from( "lib/$fname.pm",
                            { options => [ quotes => "none" ] } );
    }
    $self->add_metadata("x_module_install_rtx_version", $VERSION );

    my $installdirs = $ENV{INSTALLDIRS};
    for ( @ARGV ) {
        if ( /INSTALLDIRS=(.*)/ ) {
            $installdirs = $1;
        }
    }

    # Try to find RT.pm
    my @prefixes = qw( /opt /usr/local /home /usr /sw /usr/share/request-tracker4);
    $ENV{RTHOME} =~ s{/RT\.pm$}{} if defined $ENV{RTHOME};
    $ENV{RTHOME} =~ s{/lib/?$}{}  if defined $ENV{RTHOME};
    my @try = $ENV{RTHOME} ? ($ENV{RTHOME}, "$ENV{RTHOME}/lib") : ();
    while (1) {
        my @look = @INC;
        unshift @look, grep {defined and -d $_} @try;
        push @look, grep {defined and -d $_}
            map { ( "$_/rt5/lib", "$_/lib/rt5", "$_/rt4/lib", "$_/lib/rt4", "$_/lib" ) } @prefixes;
        last if eval {local @INC = @look; require RT; $RT::LocalLibPath};

        warn
            "Cannot find the location of RT.pm that defines \$RT::LocalPath in: @look\n";
        my $given = $self->prompt("Path to directory containing your RT.pm:") or exit;
        $given =~ s{/RT\.pm$}{};
        $given =~ s{/lib/?$}{};
        @try = ($given, "$given/lib");
    }

    print "Using RT configuration from $INC{'RT.pm'}:\n";

    my $local_lib_path = $RT::LocalLibPath;
    unshift @INC, $local_lib_path;
    my $lib_path = File::Basename::dirname( $INC{'RT.pm'} );
    unshift @INC, $lib_path;

    # Set a baseline minimum version
    unless ( $extra_args->{deprecated_rt} ) {
        $self->requires_rt('4.0.0');
    }

    # Installation locations
    my %path;
    my $plugin_path;
    if ( $installdirs && $installdirs eq 'vendor' ) {
        $plugin_path = $RT::PluginPath;
    } else {
        $plugin_path = $RT::LocalPluginPath;
    }
    $path{$_} = $plugin_path . "/$name/$_"
        foreach @DIRS;

    # Copy RT 4.2.0 static files into NoAuth; insufficient for
    # images, but good enough for css and js.
    $path{static} = "$path{html}/NoAuth/"
        unless $RT::StaticPath;

    # Delete the ones we don't need
    delete $path{$_} for grep {not -d "$FindBin::Bin/$_"} keys %path;

    my %index = map { $_ => 1 } @INDEX_DIRS;
    $self->no_index( directory => $_ ) foreach grep !$index{$_}, @DIRS;

    my $args = join ', ', map "q($_)", map { ($_, "\$(DESTDIR)$path{$_}") }
        sort keys %path;

    printf "%-10s => %s\n", $_, $path{$_} for sort keys %path;

    if ( my @dirs = map { ( -D => $_ ) } grep $path{$_}, qw(bin html sbin etc) ) {
        my @po = map { ( -o => $_ ) }
            grep -f,
            File::Glob::bsd_glob("po/*.po");
        $self->postamble(<< ".") if @po;
lexicons ::
\t\$(NOECHO) \$(PERL) -MLocale::Maketext::Extract::Run=xgettext -e \"xgettext(qw(@dirs @po))\"
.
    }

    my $remove_files;
    if( $extra_args->{'remove_files'} ){
        $self->include('Module::Install::RTx::Remove');
        our @remove_files;
        eval { require "etc/upgrade/remove_files" }
          or print "No remove file located, no files to remove\n";
        $remove_files = join ",", map {"q(\$(DESTDIR)$plugin_path/$name/$_)"} @remove_files;
    }

    $self->include('Module::Install::RTx::Runtime') if $self->admin;
    $self->include_deps( 'YAML::Tiny', 0 ) if $self->admin;
    my $postamble = << ".";
install ::
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Iinc -MModule::Install::RTx::Runtime -e"RTxPlugin()"
.

    if( $remove_files ){
        $postamble .= << ".";
\t\$(NOECHO) \$(PERL) -MModule::Install::RTx::Remove -e \"RTxRemove([$remove_files])\"
.
    }

    $postamble .= << ".";
\t\$(NOECHO) \$(PERL) -MExtUtils::Install -e \"install({$args})\"
.

    if ( $path{var} and -d $RT::MasonDataDir ) {
        my ( $uid, $gid ) = ( stat($RT::MasonDataDir) )[ 4, 5 ];
        $postamble .= << ".";
\t\$(NOECHO) chown -R $uid:$gid $path{var}
.
    }

    my %has_etc;
    if ( File::Glob::bsd_glob("$FindBin::Bin/etc/schema.*") ) {
        $has_etc{schema}++;
    }
    if ( File::Glob::bsd_glob("$FindBin::Bin/etc/acl.*") ) {
        $has_etc{acl}++;
    }
    if ( -e 'etc/initialdata' ) { $has_etc{initialdata}++; }
    if ( grep { /\d+\.\d+\.\d+.*$/ } glob('etc/upgrade/*.*.*') ) {
        $has_etc{upgrade}++;
    }

    $self->postamble("$postamble\n");
    if ( $path{lib} ) {
        $self->makemaker_args( INSTALLSITELIB => $path{'lib'} );
        $self->makemaker_args( INSTALLARCHLIB => $path{'lib'} );
        $self->makemaker_args( INSTALLVENDORLIB => $path{'lib'} )
    } else {
        $self->makemaker_args( PM => { "" => "" }, );
    }

    $self->makemaker_args( INSTALLSITEMAN1DIR => "$RT::LocalPath/man/man1" );
    $self->makemaker_args( INSTALLSITEMAN3DIR => "$RT::LocalPath/man/man3" );
    $self->makemaker_args( INSTALLSITEARCH => "$RT::LocalPath/man" );

    # INSTALLDIRS=vendor should install manpages into /usr/share/man.
    # That is the default path in most distributions. Need input from
    # Redhat, Centos etc.
    $self->makemaker_args( INSTALLVENDORMAN1DIR => "/usr/share/man/man1" );
    $self->makemaker_args( INSTALLVENDORMAN3DIR => "/usr/share/man/man3" );
    $self->makemaker_args( INSTALLVENDORARCH => "/usr/share/man" );

    if (%has_etc) {
        print "For first-time installation, type 'make initdb'.\n";
        my $initdb = '';
        $initdb .= <<"." if $has_etc{schema};
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Iinc -MModule::Install::RTx::Runtime -e"RTxDatabase(qw(schema \$(NAME) \$(VERSION)))"
.
        $initdb .= <<"." if $has_etc{acl};
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Iinc -MModule::Install::RTx::Runtime -e"RTxDatabase(qw(acl \$(NAME) \$(VERSION)))"
.
        $initdb .= <<"." if $has_etc{initialdata};
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Iinc -MModule::Install::RTx::Runtime -e"RTxDatabase(qw(insert \$(NAME) \$(VERSION)))"
.
        $self->postamble("initdb ::\n$initdb\n");
        $self->postamble("initialize-database ::\n$initdb\n");
        if ($has_etc{upgrade}) {
            print "To upgrade from a previous version of this extension, use 'make upgrade-database'\n";
            my $upgradedb = qq|\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Iinc -MModule::Install::RTx::Runtime -e"RTxDatabase(qw(upgrade \$(NAME) \$(VERSION)))"\n|;
            $self->postamble("upgrade-database ::\n$upgradedb\n");
            $self->postamble("upgradedb ::\n$upgradedb\n");
        }
    }

}

sub requires_rt {
    my ($self,$version) = @_;

    _load_rt_handle();

    if ($self->is_admin) {
        $self->add_metadata("x_requires_rt", $version);
        my @sorted = sort RT::Handle::cmp_version $version,'4.0.0';
        $self->perl_version('5.008003') if $sorted[0] eq '4.0.0'
            and (not $self->perl_version or '5.008003' > $self->perl_version);
        @sorted = sort RT::Handle::cmp_version $version,'4.2.0';
        $self->perl_version('5.010001') if $sorted[0] eq '4.2.0'
            and (not $self->perl_version or '5.010001' > $self->perl_version);
    }

    # if we're exactly the same version as what we want, silently return
    return if ($version eq $RT::VERSION);

    my @sorted = sort RT::Handle::cmp_version $version,$RT::VERSION;

    if ($sorted[-1] eq $version) {
        die <<"EOT";

**** Error: This extension requires RT $version. Your installed version
            of RT ($RT::VERSION) is too old.

EOT
    }
}

sub requires_rt_plugin {
    my $self = shift;
    my ( $plugin ) = @_;

    if ($self->is_admin) {
        my $plugins = $self->Meta->{values}{"x_requires_rt_plugins"} || [];
        push @{$plugins}, $plugin;
        $self->add_metadata("x_requires_rt_plugins", $plugins);
    }

    my $path = $plugin;
    $path =~ s{\:\:}{-}g;
    $path = "$RT::LocalPluginPath/$path/lib";
    if ( -e $path ) {
        unshift @INC, $path;
    } else {
        my $name = $self->name;
        warn <<"EOT";

**** Warning: $name requires that the $plugin plugin be installed and
              enabled; it does not appear to be installed.

EOT
    }
    $self->requires(@_);
}

sub rt_too_new {
    my ($self,$version,$msg) = @_;
    my $name = $self->name;
    $msg ||= <<EOT;

**** Error: Your installed version of RT (%s) is too new; this extension
            only works with versions older than %s.

EOT
    $self->add_metadata("x_rt_too_new", $version) if $self->is_admin;

    _load_rt_handle();
    my @sorted = sort RT::Handle::cmp_version $version,$RT::VERSION;

    if ($sorted[0] eq $version) {
        die sprintf($msg,$RT::VERSION,$version);
    }
}

# RT::Handle runs FinalizeDatabaseType which calls RT->Config->Get
# On 3.8, this dies.  On 4.0/4.2 ->Config transparently runs LoadConfig.
# LoadConfig requires being able to read RT_SiteConfig.pm (root) so we'd
# like to avoid pushing that on users.
# Fake up just enough Config to let FinalizeDatabaseType finish, and
# anyone later calling LoadConfig will overwrite our shenanigans.
sub _load_rt_handle {
    unless ($RT::Config) {
        require RT::Config;
        $RT::Config = RT::Config->new;
        RT->Config->Set('DatabaseType','mysql');
    }
    require RT::Handle;
}

1;

__END__

#line 468
