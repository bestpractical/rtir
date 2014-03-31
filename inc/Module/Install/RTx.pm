#line 1
package Module::Install::RTx;

use 5.008;
use strict;
use warnings;
no warnings 'once';

use Module::Install::Base;
use base 'Module::Install::Base';
our $VERSION = '0.33';

use FindBin;
use File::Glob     ();
use File::Basename ();

my @DIRS = qw(etc lib html static bin sbin po var);
my @INDEX_DIRS = qw(lib bin sbin);

sub RTx {
    my ( $self, $name ) = @_;

    my $original_name = $name;
    my $RTx = 'RTx';
    $RTx = $1 if $name =~ s/^(\w+)-//;
    my $fname = $name;
    $fname =~ s!-!/!g;

    $self->name("$RTx-$name")
        unless $self->name;
    $self->all_from( -e "$name.pm" ? "$name.pm" : "lib/$RTx/$fname.pm" )
        unless $self->version;
    $self->abstract("RT $name Extension")
        unless $self->abstract;

    my @prefixes = (qw(/opt /usr/local /home /usr /sw ));
    my $prefix   = $ENV{PREFIX};
    @ARGV = grep { /PREFIX=(.*)/ ? ( ( $prefix = $1 ), 0 ) : 1 } @ARGV;

    if ($prefix) {
        $RT::LocalPath = $prefix;
        $INC{'RT.pm'} = "$RT::LocalPath/lib/RT.pm";
    } else {
        local @INC = (
            $ENV{RTHOME} ? ( $ENV{RTHOME}, "$ENV{RTHOME}/lib" ) : (),
            @INC,
            map { ( "$_/rt4/lib", "$_/lib/rt4", "$_/rt3/lib", "$_/lib/rt3", "$_/lib" )
                } grep $_, @prefixes
        );
        until ( eval { require RT; $RT::LocalPath } ) {
            warn
                "Cannot find the location of RT.pm that defines \$RT::LocalPath in: @INC\n";
            $_ = $self->prompt("Path to directory containing your RT.pm:") or exit;
            $_ =~ s/\/RT\.pm$//;
            push @INC, $_, "$_/rt3/lib", "$_/lib/rt3", "$_/lib";
        }
    }

    my $lib_path = File::Basename::dirname( $INC{'RT.pm'} );
    my $local_lib_path = "$RT::LocalPath/lib";
    print "Using RT configuration from $INC{'RT.pm'}:\n";
    unshift @INC, "$RT::LocalPath/lib" if $RT::LocalPath;
    unshift @INC, $lib_path;

    $RT::LocalVarPath    ||= $RT::VarPath;
    $RT::LocalPoPath     ||= $RT::LocalLexiconPath;
    $RT::LocalHtmlPath   ||= $RT::MasonComponentRoot;
    $RT::LocalStaticPath ||= $RT::StaticPath;
    $RT::LocalLibPath    ||= "$RT::LocalPath/lib";

    my $with_subdirs = $ENV{WITH_SUBDIRS};
    @ARGV = grep { /WITH_SUBDIRS=(.*)/ ? ( ( $with_subdirs = $1 ), 0 ) : 1 }
        @ARGV;

    my %subdirs;
    %subdirs = map { $_ => 1 } split( /\s*,\s*/, $with_subdirs )
        if defined $with_subdirs;
    unless ( keys %subdirs ) {
        $subdirs{$_} = 1 foreach grep -d "$FindBin::Bin/$_", @DIRS;
    }

    # If we're running on RT 3.8 with plugin support, we really wany
    # to install libs, mason templates and po files into plugin specific
    # directories
    my %path;
    if ( $RT::LocalPluginPath ) {
        die "Because of bugs in RT 3.8.0 this extension can not be installed.\n"
            ."Upgrade to RT 3.8.1 or newer.\n" if $RT::VERSION =~ /^3\.8\.0/;
        $path{$_} = $RT::LocalPluginPath . "/$original_name/$_"
            foreach @DIRS;
    } else {
        foreach ( @DIRS ) {
            no strict 'refs';
            my $varname = "RT::Local" . ucfirst($_) . "Path";
            $path{$_} = ${$varname} || "$RT::LocalPath/$_";
        }

        $path{$_} .= "/$name" for grep $path{$_}, qw(etc po var);
    }

    my %index = map { $_ => 1 } @INDEX_DIRS;
    $self->no_index( directory => $_ ) foreach grep !$index{$_}, @DIRS;

    my $args = join ', ', map "q($_)", map { ($_, $path{$_}) }
        grep $subdirs{$_}, keys %path;

    print "./$_\t=> $path{$_}\n" for sort keys %subdirs;

    if ( my @dirs = map { ( -D => $_ ) } grep $subdirs{$_}, qw(bin html sbin) ) {
        my @po = map { ( -o => $_ ) }
            grep -f,
            File::Glob::bsd_glob("po/*.po");
        $self->postamble(<< ".") if @po;
lexicons ::
\t\$(NOECHO) \$(PERL) -MLocale::Maketext::Extract::Run=xgettext -e \"xgettext(qw(@dirs @po))\"
.
    }

    my $postamble = << ".";
install ::
\t\$(NOECHO) \$(PERL) -MExtUtils::Install -e \"install({$args})\"
.

    if ( $subdirs{var} and -d $RT::MasonDataDir ) {
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
    unless ( $subdirs{'lib'} ) {
        $self->makemaker_args( PM => { "" => "" }, );
    } else {
        $self->makemaker_args( INSTALLSITELIB => $path{'lib'} );
        $self->makemaker_args( INSTALLARCHLIB => $path{'lib'} );
    }

    $self->makemaker_args( INSTALLSITEMAN1DIR => "$RT::LocalPath/man/man1" );
    $self->makemaker_args( INSTALLSITEMAN3DIR => "$RT::LocalPath/man/man3" );
    $self->makemaker_args( INSTALLSITEARCH => "$RT::LocalPath/man" );

    if (%has_etc) {
        $self->load('RTxInitDB');
        print "For first-time installation, type 'make initdb'.\n";
        my $initdb = '';
        $initdb .= <<"." if $has_etc{schema};
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Minc::Module::Install -e"RTxInitDB(qw(schema \$(NAME) \$(VERSION)))"
.
        $initdb .= <<"." if $has_etc{acl};
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Minc::Module::Install -e"RTxInitDB(qw(acl \$(NAME) \$(VERSION)))"
.
        $initdb .= <<"." if $has_etc{initialdata};
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Minc::Module::Install -e"RTxInitDB(qw(insert \$(NAME) \$(VERSION)))"
.
        $self->postamble("initdb ::\n$initdb\n");
        $self->postamble("initialize-database ::\n$initdb\n");
        if ($has_etc{upgrade}) {
            print "To upgrade from a previous version of this extension, use 'make upgrade-database'\n";
            my $upgradedb = qq|\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Minc::Module::Install -e"RTxInitDB(qw(upgrade \$(NAME) \$(VERSION)))"\n|;
            $self->postamble("upgrade-database ::\n$upgradedb\n");
            $self->postamble("upgradedb ::\n$upgradedb\n");
        }
    }
}

sub requires_rt {
    my ($self,$version) = @_;

    # if we're exactly the same version as what we want, silently return
    return if ($version eq $RT::VERSION);

    _load_rt_handle();
    my @sorted = sort RT::Handle::cmp_version $version,$RT::VERSION;

    if ($sorted[-1] eq $version) {
        # should we die?
        die "\nWarning: prerequisite RT $version not found. Your installed version of RT ($RT::VERSION) is too old.\n\n";
    }
}

sub rt_too_new {
    my ($self,$version,$msg) = @_;
    $msg ||= "Your version %s is too new, this extension requires a release of RT older than %s\n";

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

#line 362
