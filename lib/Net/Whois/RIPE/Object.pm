###############################################################################
# Net::Whois::RIPE - implementation of RIPE Whois.
# Copyright (C) 2009 Luis Motta Campos
# Copyright (C) 2005 Paul Gampe, Kevin Baker
# vim:tw=78:ts=4
###############################################################################
package Net::Whois::RIPE::Object;
use strict;
use Carp;

our $VERSION = '1.31';

my $errstr = '';
sub errstr { $errstr }

# XXX: remove declaration of AUTOLOAD from here
use vars qw($AUTOLOAD);

# values not permitted to be added
my @NO_ADD = qw(
  content methods attributes warning error success debug parse
  size _ok _err _wrn
);
my %NO_ADD = map { $_ => 1 } @NO_ADD;

my @Free_Form = qw(descr remarks person address role trouble);
my %Free_Form = map { $_ => 1 } @Free_Form;

sub new {
    my $proto       = shift;
    my $class       = ref($proto) || $proto;
    my $handle      = shift;
    my $persistance = shift || 0;

    unless ( $handle and ref($handle) ) {
        $errstr = 'expected handle not found';
        carp "expecting a handle";
        return undef;
    }
    $errstr = '';

    my $self = bless {
        _methods => {}
        ,    # storage for parsed attributes values, lookup by attribute
        _order   => [],    # order attributes are saved in
        _content => [],    # untampered text from whois server
        _debug   => 0,     # off by default
        _warn    => [],
        _error   => [],
    }, $class;

    return $self->parse( $handle, $persistance ) ? $self : undef;
}

sub parse {
    my $self        = shift;
    my $handle      = shift;
    my $persistance = shift;

    my $found_record = 0;
    my $precedent_attribute;
    local $/ = "\n";
    local $_;

    my $line_cnt = 0;
    while ( $_ = <$handle> ) {    # walk through the response
        $line_cnt++;
        push @{ $self->{_content} }, $_;    # save the entire response

        if ( $self->debug ) {
            my $received = $_;
            chomp $received;
            carp "received ->", $received;
        }

        /^The object shown below is NOT in the/ and $self->_err($_);
        /^\%\s+No entries found/ and $self->_err('No entries found');
        /^\%ERROR:(.*)/ and $self->_err($1), next;
        /^%/   and next;                     # skip server comments
        /^\n$/ and $found_record and last;
        /^\n$/ and $persistance and last;
        /^\n$/ and next;

        chomp;

        # search for errors, failures and warnings
        /^(?:New|Delete|Update) FAILED/ and next;    # followed by ERROR
        /^(?:New|Update|Delete) OK:(.*)/ and $self->_ok($1), next;
        /^\*ERROR\*:\s+(.*)/ and $self->_err($1), next;
        /^WARNING:\s+(.*)/   and $self->_wrn($1), next;

        # ok, now try to match attribute value pairs
        if ( my ($value) = /^(\+\s*.*|\s+.+)$/ and $precedent_attribute ) {
            $value =~ s/^\+/ /;
            $self->clean_and_add( $precedent_attribute, $value );
        }
        elsif ( my ( $attribute, $v ) = /^([\w\-]+|\*\w\w):\s*(.*)$/ ) {
            $self->clean_and_add( $attribute, $v );
            $precedent_attribute = $attribute;
            $found_record        = 1;
        }
        else {
            $self->_err("unparseable line: '$_'");
        }
    }

    if ( $line_cnt == 0 ) {
        carp "parse: no lines read from handle" if $self->debug;
        $errstr = "no lines read from handle";
        return 0;
    }

    if ( @{ $self->{_content} } == 0 ) {    # this should be caught by $line_cnt
        carp "parse: no content read from handle" if $self->debug;
        $errstr = "no content read from handle";
        return 0;
    }

    if ( scalar $self->content =~ /^\s*$/ ) {
        carp "parse: content is all whitespace" if $self->debug;
        $errstr = "content is all whitespace";
        return 0;
    }

    return 1;
}

sub size {    # will only work in the ascii world
    my $self = shift;
    return length scalar $self->content;
}

sub clean_and_add {
    my ( $self, $attr, $value ) = @_;

    # strip end of line comments and leading and trailing white space
    $value =~ s/#.*$// unless exists $Free_Form{$attr};
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;

    return $self->add( $attr, $value );
}

sub add {
    my ( $self, $attr, $value ) = @_;

    unless ( ref($self) and $attr and defined $value ) {
        carp "add: expecting an ATTRIBUTE and a VALUE" if $self->debug;
        return undef;
    }

    # don't clobber our method names
    if ( defined $NO_ADD{$attr} ) {
        carp "attribute [$attr] is a reserved attribute" if $self->debug;
        return undef;
    }

    carp "adding attribute [$attr] with value [$value]" if $self->debug;

    # preserve order in which the attributes are registered.
    # if this ATTRIBUTE has been saved before then do not
    # place it on the order list again.
    push @{ $self->{_order} }, $attr
      unless exists $self->{_methods}->{$attr};

    # save the VALUE on the list for that ATTRIBUTE
    push @{ $self->{_methods}->{$attr} }, $value;
}

sub content {
    my $self = shift;
    return wantarray
      ? @{ $self->{_content} }
      : join( '', @{ $self->{_content} } );
}

sub methods { return $_[0]->attributes }

sub attributes {
    my $self = shift;
    return @{ $self->{_order} };
}

sub warning {
    my $self = shift;

    #    local $^W=0;
    return wantarray ? @{ $self->{_warn} } : join( "\n", @{ $self->{_warn} } );
}

sub error {
    my $self = shift;

    #    local $^W=0;
    return
      wantarray ? @{ $self->{_error} } : join( "\n", @{ $self->{_error} } );
}

sub success {
    my $self = shift;
    return @{ $self->{_error} } ? 0 : 1;
}

sub debug {
    my $self = shift;
    return @_ ? $self->{_debug} = shift : $self->{_debug};
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/^.*://;    # strip fully-qualified portion
    $name =~ s/_/-/g;     # change _ to - in method name: same as 'add'

    unless ( exists $self->{_methods}->{$name} ) {
        carp "I don't know about method `$name' in class $type"
          if $self->debug;
        return undef;
    }

    # all the attribute values are stored in arrays
    return wantarray
      ? @{ $self->{_methods}->{$name} }
      : $self->{_methods}->{$name}->[0];
}

sub DESTROY { }

###############################################################################
##            P R I V A T E   M E T H O D S
###############################################################################

sub _err { my $self = shift; (@_) and push @{ $self->{_error} }, shift }
sub push_warn { shift->_wrn(@_) }
sub _wrn { my $self = shift; (@_) and push @{ $self->{_warn} }, shift }

sub _ok {
    my ( $self, $text ) = @_;
    unless ($text) {
        carp "_ok: can't find TEXT" if $self->debug;
        return undef;
    }

    # New and Update return the nic hdl of the created/updated object
    # tear out the nic-hdl from the text. example text below.
    #New OK: [person] KB1-TEST (Kevin Baker)
    #Update OK: [person] KB1-TEST (Kevin Baker)
    # I made this a separate routine in case there turn out to be other
    # cases to match. For instance, a route object.
    if ( $text =~ /\[person\]\s+([^\s]+)\s+\((.+)\)/ ) {
        $self->add( 'nic-hdl', $1 );
        $self->add( 'person',  $2 );
    }
}

1;
__END__
