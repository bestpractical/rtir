###############################################################################
# Net::Whois::RIPE - implementation of RIPE Whois.
# Copyright (C) 2009 Luis Motta Campos
# Copyright (C) 2005 Paul Gampe, Kevin Baker
# vim:tw=78:ts=4
###############################################################################
package Net::Whois::RIPE::Iterator;

use strict;
use Carp;
use Net::Whois::RIPE::Object;
use Net::Whois::RIPE::Object::Template;

our $VERSION = '1.30';

# class wide debug flag 0=off,1=on,2=on for IO::Socket
my $DEBUG = 0;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    unless ( @_ == 2 ) {
        carp "new: expecting Net::Whois::RIPE object and a query string"
            if $DEBUG;
        return undef;
    }
    my $self = bless {
        WHOIS => shift,
        QUERY => shift,
        DEBUG => 0,
    }, $class;

    unless ( ref( $self->{WHOIS} ) =~ /^Net::Whois::RIPE$/ ) {
        carp "new: first parameter must be a Net::Whois::RIPE object"
            if $DEBUG;
        return undef;
    }

    if ( $self->{QUERY} =~ /^\s*$/ ) {
        carp "new: second parameter must be a whois query string" if $DEBUG;
        return undef;
    }

    my $sock = $self->{SOCKET} = $self->{WHOIS}->_connect;
    unless ( print $sock $self->{QUERY} ) {
        carp "new: unable to print to socket:\n" . $self->{QUERY} if $DEBUG;
        return undef;
    }

    return $self;
}

sub next {
    my $self = shift;

    my $sock = $self->{SOCKET};
    unless ( $sock and $sock->connected ) {
        carp 'no socket connection' if $DEBUG || $self->debug;
        return undef;
    }

    my $obj = Net::Whois::RIPE::Object->new($sock);
    return $obj if $obj;
    $self->{WHOIS}->_disconnect();
    return undef;
}

sub debug {
    my $self = shift;
    if (@_) {
        ref($self) ? $self->{DEBUG} = shift : $DEBUG = shift;
    }
    return ref($self) ? ( $DEBUG || $self->{DEBUG} ) : $DEBUG;
}

sub DESTROY {
    my $self = shift;
    carp "Destroying ", ref($self) if $self->debug;
}

END {
    carp "All Net::Whois::RIPE::Iterator objects are going away now."
        if $DEBUG;
}

###############################################################################
##            P R I V A T E   M E T H O D S
###############################################################################
1;

