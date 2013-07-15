package Net::Whois::RIPE::Object::Template;
use strict;
use Carp;

our $VERSION = '1.30';

our @ISA = qw(Net::Whois::RIPE::Object);

sub parse {
    my $self   = shift;
    my $handle = shift;

    local $/ = "\n";    # record separator

    my $not_a_template = 0;
    while ( $_ = <$handle> ) {    # walk through the response
        push @{ $self->{_content} }, $_;    # save the entire response
        next if $not_a_template;

        if (/^% (No (?:verbose )?template available for object .+$)/) {
            $not_a_template = 1;
            $self->__error($1);
            next;
        }

        chomp;
        my ( $attr, $value );
        next unless ( ( $attr, $value ) = /^([\w\-]+|\*\w\w):\s+(.*)$/ );
        $self->add( $attr, $value ) if $attr;
    }

    return ( scalar $self->content ) !~ /^\s*$/;
}
1;
__END__
