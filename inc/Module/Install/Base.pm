#line 1 "inc/Module/Install/Base.pm - /usr/local/share/perl/5.8.7/Module/Install/Base.pm"
package Module::Install::Base;

# Suspend handler for "redefined" warnings
BEGIN { my $w = $SIG{__WARN__}; $SIG{__WARN__} = sub { $w } };

#line 30

sub new {
    my ($class, %args) = @_;

    foreach my $method (qw(call load)) {
        *{"$class\::$method"} = sub {
            +shift->_top->$method(@_);
        } unless defined &{"$class\::$method"};
    }

    bless(\%args, $class);
}

#line 48

sub AUTOLOAD {
    my $self = shift;

    local $@;
    my $autoload = eval { $self->_top->autoload } or return;
    goto &$autoload;
}

#line 62

sub _top { $_[0]->{_top} }

#line 73

sub admin {
    my $self = shift;
    $self->_top->{admin} or Module::Install::Base::FakeAdmin->new;
}

sub is_admin {
    my $self = shift;
    $self->admin->VERSION;
}

sub DESTROY {}

package Module::Install::Base::FakeAdmin;

my $Fake;
sub new { $Fake ||= bless(\@_, $_[0]) }
sub AUTOLOAD {}
sub DESTROY {}

1;

# Restore warning handler
BEGIN { $SIG{__WARN__} = $SIG{__WARN__}->() };

__END__

#line 120
