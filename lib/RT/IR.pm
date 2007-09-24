# {{{ BEGIN BPS TAGGED BLOCK
# 
# COPYRIGHT:
#  
# This software is Copyright (c) 1996-2004 Best Practical Solutions, LLC 
#                                          <jesse@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
# 
# }}} END BPS TAGGED BLOCK
#
package RT::IR;

our $VERSION = '2.3.7';

use warnings;
use strict;

use Business::Hours;
use Business::SLA;


=head1 FUNCTIONS

=head2 BusinessHours

Returns L<Business::Hours> object initilized with information from
the config file. See option 'BusinessHours'.

=cut

sub BusinessHours {
    my $bizhours = new Business::Hours;
    if ( RT->Config->Get('BusinessHours') ) {
        $bizhours->business_hours( %{ RT->Config->Get('BusinessHours') } );
    }

    return $bizhours;
}

=head2 DefaultSLA

TODO: Not yet described.

=cut

sub DefaultSLA {
    my $SLAObj = SLAInit();
    return $SLAObj->SLA( time );
}

=head2 SLAInit

Returns an object of L<Business::SLA> class or class defined in SLAModule
config option.

See also the following options: SLAModule, _RTIR_SLA_inhours_default,
_RTIR_SLA_outofhours_default and SLA.

=cut

sub SLAInit {

    my $class = RT->Config->Get('SLAModule') || 'Business::SLA';

    my $SLAObj = $class->new();

    $SLAObj->SetInHoursDefault( RT->Config->Get('_RTIR_SLA_inhours_default') );
    $SLAObj->SetOutOfHoursDefault( RT->Config->Get('_RTIR_SLA_outofhours_default') );

    my $bh = RT::IR::BusinessHours();
    $SLAObj->SetBusinessHours($bh);

    my $SLA = RT->Config->Get('SLA');
    foreach my $key( keys %$SLA ) {
        if ( $SLA->{ $key } =~ /^\d+$/ ) {
            $SLAObj->Add( $key, ( BusinessMinutes => $SLA->{ $key } ) );
        } else {
            $SLAObj->Add( $key, %{ $SLA->{ $key } } );
        }
    }

    return $SLAObj;
}

=head2 TicketType

Returns type of a ticket. Takes either Ticket or Queue argument.
Both arguments could be objects or IDs, however, name of a queue
works too for Queue argument. If the queue argument is defined then
the ticket is ignored even if it's defined too.

=cut

my %TYPE = (
    'incidents'        => 'Incident',
    'incident reports' => 'Report',
    'investigations'   => 'Investigation',
    'blocks'           => 'Block',
);

sub TicketType {
    my %arg = ( Queue => undef, Ticket => undef, @_);

    if ( defined $arg{'Ticket'} && !defined $arg{'Queue'} ) {
        my $obj;
        if ( ref $arg{'Ticket'} ) {
            $obj = $arg{'Ticket'};
        }
        else {
            $obj = RT::Ticket->new( $RT::SystemUser );
            $obj->Load( $arg{'Ticket'} );
        }
        $arg{'Queue'} = $obj->QueueObj if $obj->id;
    }
    return undef unless defined $arg{'Queue'};

    return $TYPE{ lc $arg{'Queue'}->Name } if ref $arg{'Queue'};
    return $TYPE{ lc $arg{'Queue'} } unless $arg{'Queue'} =~ /^\d+$/;

    my $obj = RT::Queue->new( $RT::SystemUser );
    $obj->Load( $arg{'Queue'} );
    return $TYPE{ lc $obj->Name } if $obj->id;

    return undef;
}

my %STATES = (
    'incidents'        => { Active => ['open'], Inactive => ['resolved', 'abandoned'] },
    'incident reports' => { Active => ['new', 'open'], Inactive => ['resolved', 'rejected'] },
    'investigations'   => { Active => ['open'], Inactive => ['resolved'] },
    'blocks'           => {
        Active => ['pending activation', 'active', 'pending removal'],
        Inactive => ['removed'],
    },
);
sub States {
    my %arg = ( Queue => undef, Active => 1, Inactive => 0, @_ );
    
    my @states;
    if ( $arg{'Queue'} ) {
        push @states, @{ $STATES{ lc $arg{'Queue'} }->{'Active'} || [] } if $arg{'Active'};
        push @states, @{ $STATES{ lc $arg{'Queue'} }->{'Inactive'} || [] } if $arg{'Inactive'};
    } else {
        foreach ( values %STATES ) {
            push @states, @{ $_->{'Active'} || [] } if $arg{'Active'};
            push @states, @{ $_->{'Inactive'} || [] } if $arg{'Inactive'};
        }
    }

    my %seen = ();
    return sort grep !$seen{$_}++, @states;
}

{
my %cache;
sub GetCustomField {
    my $field = shift or return;
    return $cache{ $field } if exists $cache{ $field };

    my $cf = RT::CustomField->new( $RT::SystemUser );
    $cf->Load( $field );
    return $cache{ $field } = $cf;
}
}


# IPs processing hooks
# in order too implement searches by IP ranges we
# store IPs in "%03d.%03d.%03d.%03d" format so ops
# like > and < make sense.
use Hook::LexWrap;
use Regexp::Common qw(RE_net_IPv4);
use Regexp::Common::net::CIDR;
require Net::CIDR;

sub ParseIPRange {
    my $arg = shift or return ();

    if ( $arg =~ /^\s*$RE{net}{CIDR}{IPv4}{-keep}\s*$/go ) {
        my $cidr = join( '.', map $_||0, (split /\./, $1)[0..3] ) ."/$2";
        $arg = (Net::CIDR::cidr2range( $cidr ))[0] || $arg;
    }

    my ($sIP, $eIP);
    if ( $arg =~ /^\s*($RE{net}{IPv4})\s*$/o ) {
        $sIP = $eIP = sprintf "%03d.%03d.%03d.%03d", split /\./, $1;
    }
    elsif ( $arg =~ /^\s*($RE{net}{IPv4})-($RE{net}{IPv4})\s*$/o ) {
        $sIP = sprintf "%03d.%03d.%03d.%03d", split /\./, $1;
        $eIP = sprintf "%03d.%03d.%03d.%03d", split /\./, $2;
    }
    else {
        return ();
    }
    ($sIP, $eIP) = ($eIP, $sIP) if $sIP gt $eIP;

    return $sIP, $eIP;
}


# limit formatting "%03d.%03d.%03d.%03d"
# "= 'sIP-eIP'" => "( >=sIP AND <=eIP)"
# "!= 'sIP-eIP'" => "( <sIP OR >eIP)"
# two ranges intercect when ( eIP1 >= sIP2 AND sIP1 <= eIP2 )
require RT::Tickets;
wrap 'RT::Tickets::_CustomFieldLimit',
    pre => sub {
        return if $_[2] && $_[2] =~ /^[<>]=?$/;
        return unless $_[3] =~ /^\s*($RE{net}{IPv4})\s*(?:-\s*($RE{net}{IPv4})\s*)?$/o;
        my ($start_ip, $end_ip) = ($1, ($2 || $1));
        $_ = sprintf "%03d.%03d.%03d.%03d", split /\./, $_
            for $start_ip, $end_ip;
        ($start_ip, $end_ip) = ($end_ip, $start_ip) if $start_ip gt $end_ip;

        my ($tickets, $field, $op, $value, %rest) = @_[0..($#_-1)];
        $tickets->_OpenParen;
        unless ( $op =~ /NOT|!=|<>/i ) { # positive equation
            $tickets->_CustomFieldLimit($field, '<=', $end_ip, %rest);
            $tickets->_CustomFieldLimit(
                $field, '>=', $start_ip, %rest,
                SUBKEY          => $rest{'SUBKEY'}. '.LargeContent',
                ENTRYAGGREGATOR => 'AND',
            );
        }
        else { # negative equation
            $tickets->_CustomFieldLimit($field, '>', $end_ip, %rest);
            $tickets->_CustomFieldLimit(
                $field, '<', $start_ip, %rest,
                SUBKEY          => $rest{'SUBKEY'}. '.LargeContent',
                ENTRYAGGREGATOR => 'OR',
            );
        }
        $tickets->_CloseParen;
        # return right now as we did everything
        $_[-1] = ref $_[-1]? [1]: 1;
    };

# "[!]= 'CIDR'" => "op 'sIP-eIP'"
wrap 'RT::Tickets::_CustomFieldLimit',
    pre => sub {
        return unless $_[3] =~ /^\s*$RE{net}{CIDR}{IPv4}{-keep}\s*$/o;
        # convert incomplete 192.168/24 to 192.168.0.0/24 format
        my $cidr = join( '.', map $_||0, (split /\./, $1)[0..3] ) ."/$2";
        # convert to range and continue, it will be catched by next wrapper
        $_[3] = (Net::CIDR::cidr2range( $cidr ))[0] || $_[3];
    };
$RT::Tickets::dispatch{'CUSTOMFIELD'} = \&RT::Tickets::_CustomFieldLimit;

# on OCFV create format storage
require RT::ObjectCustomFieldValue;
wrap 'RT::ObjectCustomFieldValue::Create',
    pre => sub {
        my %args = @_[1..@_-2];
        my $cf = GetCustomField( '_RTIR_IP' );
        unless ( $cf && $cf->id ) {
            $RT::Logger->crit("Couldn't load IP CF");
            return;
        }
        return unless $cf->id == $args{'CustomField'};

        for ( my $i = 1; $i < @_; $i += 2 ) {
            next unless $_[$i] && $_[$i] eq 'Content';

            my ($sIP, $eIP) = ParseIPRange( $_[++$i] );
            unless ( $sIP && $eIP ) {
                $_[-1] = 0;
                return;
            }
            $_[$i] = $sIP;

            my $flag = 0;
            for ( my $j = 1; $j < @_; $j += 2 ) {
                next unless $_[$j] && $_[$j] eq 'LargeContent';
                $flag = $_[++$j] = $eIP;
                last;
            }
            splice @_, -1, 0, LargeContent => $eIP unless $flag;
            return;
        }
    };

# strip zero chars(deserialize)
{
my $obj;
wrap 'RT::ObjectCustomFieldValue::Content',
    pre  => sub { $obj = $_[0] },
    post => sub {
        return unless $_[-1];
        my $val = ref $_[-1]? \$_[-1][0]: \$_[-1];
        return unless $$val =~ /^\s*($RE{net}{IPv4})\s*$/;
        $$val = sprintf "%d.%d.%d.%d", split /\./, $1;

        my $large_content = $obj->__Value('LargeContent');
        return if !$large_content
            || $large_content !~ /^\s*($RE{net}{IPv4})\s*$/;
        my $eIP = sprintf "%d.%d.%d.%d", split /\./, $1;
        $$val .= '-'. $eIP unless $$val eq $eIP;
        return;
    };
}


# if (0) {
{
    require RT::Record;
    # flush constituency cache on update of the custom field value for a ticket
    wrap 'RT::Record::_AddCustomFieldValue', pre => sub {
        return unless UNIVERSAL::isa($_[0] => 'RT::Ticket');
        $RT::IR::ConstituencyCache->{$_[0]->id}  = undef;
    };

    require RT::Ticket;
    wrap 'RT::Ticket::ACLEquivalenceObjects', pre => sub {
        my $self = shift;

        my $queue = RT::Queue->new($RT::SystemUser);
        $queue->Load($self->__Value('Queue'));

        # We do this, rather than fall through to the orignal sub, as that
        # interacts poorly with our overloaded QueueObj below
        if ( $self->CurrentUser->id == $RT::SystemUser->id ) {
            $_[-1] =  [$queue];
            return;
        }
        if ( UNIVERSAL::isa( $self, 'RT::Ticket' ) ) {
            if (not defined $RT::IR::ConstituencyCache->{ $self->id }) {
                my $systicket = RT::Ticket->new($RT::SystemUser);
                $systicket->Load( $self->id );
                $RT::IR::ConstituencyCache->{$self->id}  = $systicket->FirstCustomFieldValue('_RTIR_Constituency') || '_none';
            }
            return if ( $RT::IR::ConstituencyCache->{ $self->id } eq '_none' );
            if ( not $self->{_constituency_queue} ) {
                my $new_queue = RT::Queue->new( $RT::SystemUser);
                $new_queue->LoadByCols( Name => $queue->Name . " - " . $RT::IR::ConstituencyCache->{ $self->id } );
                return unless ( $new_queue->id );
                $self->{_constituency_queue} = $new_queue;
            }
            $_[-1] =  [$queue, $self->{_constituency_queue}];
        } else {
            use YAML;
            $RT::Logger->crit( "$self is not a ticket object like I expected"
                    . YAML::Dump($self) );
        }
    };
}


{ 
    wrap 'RT::Ticket::QueueObj', pre => sub {
        my $queue = RT::Queue->new($_[0]->CurrentUser);
        $queue->Load($_[0]->__Value('Queue'));
        $queue->{'_for_ticket'} = $_[0]->id;
        $_[-1] = $queue;
        return;
    };

    wrap 'RT::Queue::HasRight', pre => sub {
        return if $_[0]->{'_for_ticket'} || !$_[0]->id;
        return unless $_[0]->__Value('Name') =~
            /^(Incidents|Incident Reports|Investigations|Blocks)$/i;

        my $name = $1;
        my %args = (@_[1..(@_-2)]);
        $args{'Principal'} ||= $_[0]->CurrentUser;

        my $queues = RT::Queues->new( $RT::SystemUser );
        $queues->Limit( FIELD => 'Name', OPERATOR => 'STARTSWITH', VALUE => "$name - " );
        my $has_right = $args{'Principal'}->HasRight(
            %args,
            Object => $_[0],
            EquivObjects => $queues->ItemsArrayRef,
        );
        $_[-1] = $has_right;
        return;
    };



    { 
        package RT::Queue;

        sub CorrespondAddress { GetQueueAttribute(shift, 'CorrespondAddress') }
        sub CommentAddress { GetQueueAttribute(shift, 'CommentAddress') }

    sub GetQueueAttribute {
        my $queue = shift;
        my $attr  = shift;

        if ( ( my $id = $queue->{'_for_ticket'} ) ) {
            my $const = $RT::IR::ConstituencyCache->{$id};
            unless ($const) {
                my $ticket = RT::Ticket->new($RT::SystemUser);
                $ticket->Load($id);
                $const = $RT::IR::ConstituencyCache->{$ticket->id}  = $ticket->FirstCustomFieldValue('_RTIR_Constituency') || '_none';
            }
            if ($const) {
                my $new_queue = RT::Queue->new($RT::SystemUser);
                $new_queue->LoadByCols(
                    Name => $queue->Name . " - " . $const );
                if ( $new_queue->id ) {
                    my $val = $new_queue->_Value($attr) || $queue->_Value($attr);
                    $RT::Logger->debug("Overriden $attr is $val for ticket #$id according to constituency $const");
                    return $val;
                }
            }
        }
        return $queue->_Value($attr);
    }
}
}


#
eval "require RT::IR_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IR_Vendor.pm});
eval "require RT::IR_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IR_Local.pm});

package RT::ObjectCustomFieldValue;

use strict;
use warnings;

sub LoadByCols {
    my $self = shift;
    my %args = @_;
    return $self->SUPER::LoadByCols( %args )
        unless $args{'CustomField'} && $args{'Content'};

    my $cf = RT::IR::GetCustomField( '_RTIR_IP' );
    unless ( $cf && $cf->id ) {
        $RT::Logger->crit("Couldn't load IP CF");
        return $self->SUPER::LoadByCols( %args )
    }
    return $self->SUPER::LoadByCols( %args )
        unless $cf->id == $args{'CustomField'};

    my ($sIP, $eIP) = RT::IR::ParseIPRange( $args{'Content'} );
    return $self->SUPER::LoadByCols( %args )
        unless $sIP && $eIP;

    return $self->SUPER::LoadByCols( %args, Content => $sIP, LargeContent => $eIP );
}


1;
