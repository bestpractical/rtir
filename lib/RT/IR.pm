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

our $VERSION = '2.6.0';

use 5.008003;
use warnings;
use strict;

use Business::Hours;
use Business::SLA;


# XXX: we push config metadata into RT, but we need
# need interface to load config options metadata from
# extensions in RT core

use RT::IR::Config;
RT::IR::Config::Init();

my @QUEUES = ('Incidents', 'Incident Reports', 'Investigations', 'Blocks');
my %QUEUES = map { lc($_) => $_ } @QUEUES;
my %TYPE = (
    'incidents'        => 'Incident',
    'incident reports' => 'Report',
    'investigations'   => 'Investigation',
    'blocks'           => 'Block',
);
my %STATES = (
    'incidents'        => { Active => ['open'], Inactive => ['resolved', 'abandoned'] },
    'incident reports' => { Active => ['new', 'open'], Inactive => ['resolved', 'rejected'] },
    'investigations'   => { Active => ['open'], Inactive => ['resolved'] },
    'blocks'           => {
        Active => ['pending activation', 'active', 'pending removal'],
        Inactive => ['removed'],
    },
);

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

See also the following options: SLAModule, RTIR_CustomFieldsDefaults and SLA.

=cut

sub SLAInit {

    my $class = RT->Config->Get('SLAModule') || 'Business::SLA';

    my $SLAObj = $class->new();
    $SLAObj->SetInHoursDefault( RT->Config->Get('RTIR_CustomFieldsDefaults')->{'SLA'}{'InHours'} );
    $SLAObj->SetOutOfHoursDefault( RT->Config->Get('RTIR_CustomFieldsDefaults')->{'SLA'}{'OutOfHours'} );

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

=head2 OurQueue

=cut

sub OurQueue {
    my $self = shift;
    my $queue = shift;
    $queue = $queue->Name if ref $queue;
    return undef unless $queue;
    return '' unless $QUEUES{ lc $queue };
    return $TYPE{ lc $queue };
}

=head2 TicketType

Returns type of a ticket. Takes either Ticket or Queue argument.
Both arguments could be objects or IDs, however, name of a queue
works too for Queue argument. If the queue argument is defined then
the ticket is ignored even if it's defined too.

=cut

sub TicketType {
    my %arg = ( Queue => undef, Ticket => undef, @_);

    if ( defined $arg{'Ticket'} && !defined $arg{'Queue'} ) {
        my $obj = RT::Ticket->new( $RT::SystemUser );
        $obj->Load( ref $arg{'Ticket'} ? $arg{'Ticket'}->id : $arg{'Ticket'} );
        $arg{'Queue'} = $obj->QueueObj->Name if $obj->id;
    }
    return undef unless defined $arg{'Queue'};

    return $TYPE{ lc $arg{'Queue'} } if !ref $arg{'Queue'} && $arg{'Queue'} !~ /^\d+$/;

    my $obj = RT::Queue->new( $RT::SystemUser );
    $obj->Load( ref $arg{'Queue'}? $arg{'Queue'}->id : $arg{'Queue'} );
    return $TYPE{ lc $obj->Name } if $obj->id;

    return undef;
}

=head2 States

Return sorted list of unique states for one, many or all RTIR queues.

Takes arguments 'Queue', 'Active' and 'Inactive'. By default returns
only active states. Queue can be an array reference to list several
queues.

Examples:

    States()
    States( Queue => 'Blocks' );
    States( Queue => [ 'Blocks', 'Incident Reports' ] );
    States( Active => 0, Inactive => 1 );

=cut

sub States {
    my %arg = ( Queue => undef, Active => 1, Inactive => 0, @_ );

    my @queues = !$arg{'Queue'} ? (@QUEUES)
        : ref $arg{'Queue'}? @{ $arg{'Queue'} } : ( $arg{'Queue'} );
    
    my @states;
    foreach ( @queues ) {
        push @states, @{ $STATES{ lc $_ }->{'Active'} || [] } if $arg{'Active'};
        push @states, @{ $STATES{ lc $_ }->{'Inactive'} || [] } if $arg{'Inactive'};
    }

    my %seen = ();
    return sort grep !$seen{$_}++, @states;
}

sub GetCustomField {
    my $field = shift or return;
    return (__PACKAGE__->CustomFields( $field ))[0];
}

{ my %cache;
sub CustomFields {
    my $self = shift;
    my %arg = (
        Field => undef,
        Queue => undef,
        Ticket => undef,
        @_%2 ? (Field => @_) : @_
    );

    unless ( keys %cache ) {
        foreach my $qname ( @QUEUES ) {
            my $type = TicketType( Queue => $qname );
            $cache{$type} = [];

            my $queue = RT::Queue->new( $RT::SystemUser );
            $queue->Load( $qname );
            unless ($queue->id) {
                $RT::Logger->error("Couldn't load queue '$qname'");
                delete $cache{$type};
                return;
            }

            my $cfs = RT::CustomFields->new( $RT::SystemUser );
            $cfs->LimitToLookupType( 'RT::Queue-RT::Ticket' );
            $cfs->LimitToQueue( $queue->id );
            while ( my $cf = $cfs->Next ) {
                push @{ $cache{$type} }, $cf;
            }
        }

        $cache{'Global'} = [];
        my $cfs = RT::CustomFields->new( $RT::SystemUser );
        $cfs->LimitToLookupType( 'RT::Queue-RT::Ticket' );
        $cfs->LimitToGlobal;
        while ( my $cf = $cfs->Next ) {
            push @{ $cache{'Global'} }, $cf;
        }
    }

    my $type = TicketType( %arg );

    my @list;
    if ( $type ) {
        @list = (@{ $cache{'Global'} }, @{ $cache{$type} });
    } else {
        @list = (@{ $cache{'Global'} }, map @$_, @cache{values %TYPE});
    }

    if ( my $field = $arg{'Field'} ) {
        if ( $field =~ /\D/ ) {
            @list = grep lc $_->Name eq lc $field, @list;
        } else {
            @list = grep $_->id == $field, @list;
        }
    }

    return wantarray? @list : $list[0];
}

sub _FlushCustomFieldsCache {
    %cache = ()
} }

{ my $cache;
sub HasConstituency {
    return $cache if defined $cache;

    my $self = shift;
    return $cache = $self->CustomFields('Constituency');
} }

sub DefaultConstituency {
    my $queue = shift;
    my $name = $queue->Name;

    my @values;

    my $queues = RT::Queues->new( $RT::SystemUser );
    $queues->Limit( FIELD => 'Name', OPERATOR => 'STARTSWITH', VALUE => "$name - " );
    while ( my $pqueue = $queues->Next ) {
        next unless $pqueue->HasRight( Principal => $queue->CurrentUser, Right => "ShowTicket" );
        push @values, substr $pqueue->__Value('Name'), length("$name - ");
    }
    my $default = RT->Config->Get('RTIR_CustomFieldsDefaults')->{'Constituency'} || '';
    return $default if grep lc $_ eq lc $default, @values;
    return shift @values;
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
            $tickets->_CustomFieldLimit(
                $field, '<=', $end_ip, %rest,
                SUBKEY => $rest{'SUBKEY'}. '.Content',
            );
            $tickets->_CustomFieldLimit(
                $field, '>=', $start_ip, %rest,
                SUBKEY          => $rest{'SUBKEY'}. '.LargeContent',
                ENTRYAGGREGATOR => 'AND',
            );
            # as well limit borders so DB optimizers can use better
            # estimations and scan less rows
            $tickets->_CustomFieldLimit(
                $field, '>=', '000.000.000.000', %rest,
                SUBKEY          => $rest{'SUBKEY'}. '.Content',
                ENTRYAGGREGATOR => 'AND',
            );
            $tickets->_CustomFieldLimit(
                $field, '<=', '255.255.255.255', %rest,
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
            # TODO: as well limit borders so DB optimizers can use better
            # estimations and scan less rows, but it's harder to do
            # as we have OR aggregator
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
        my $cf = GetCustomField( 'IP' );
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
my $re_ip_sunit = qr/[0-1][0-9][0-9]|2[0-4][0-9]|25[0-5]/;
my $re_ip_serialized = qr/$re_ip_sunit(?:\.$re_ip_sunit){3}/;
my $obj;
wrap 'RT::ObjectCustomFieldValue::Content',
    pre  => sub { $obj = $_[0] },
    post => sub {
        return unless $_[-1];
        my $val = ref $_[-1]? \$_[-1][0]: \$_[-1];
        return unless $$val =~ /^\s*($re_ip_serialized)\s*$/o;
        $$val = sprintf "%d.%d.%d.%d", split /\./, $1;

        my $large_content = $obj->__Value('LargeContent');
        return if !$large_content
            || $large_content !~ /^\s*($re_ip_serialized)\s*$/o;
        my $eIP = sprintf "%d.%d.%d.%d", split /\./, $1;
        $$val .= '-'. $eIP unless $$val eq $eIP;
        return;
    };
}

# don't return LargeContent to avoid making angry RT's AddCFV logic
wrap 'RT::ObjectCustomFieldValue::LargeContent',
    pre  => sub {
        my $obj = $_[0];
        my $cf = GetCustomField( 'IP' );
        return unless $cf && $cf->id;
        return unless $obj->CustomField == $cf->id;
        $_[-1] = undef;
    };


if ( RT::IR->HasConstituency ) {
    # ACL checks for multiple constituencies

    require RT::Interface::Web::Handler;
    # flush constituency cache on each request
    wrap 'RT::Interface::Web::Handler::CleanupRequest', pre => sub {
        %RT::IR::ConstituencyCache = ();
        %RT::IR::HasNoQueueCache = ();
    };

    require RT::Record;
    # flush constituency cache on update of the custom field value for a ticket
    wrap 'RT::Record::_AddCustomFieldValue', pre => sub {
        return unless UNIVERSAL::isa($_[0] => 'RT::Ticket');
        $RT::IR::ConstituencyCache{$_[0]->id}  = undef;
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
            my $const = $RT::IR::ConstituencyCache{ $self->id };
            if (!$const || $const eq '_none' ) {
                my $systicket = RT::Ticket->new($RT::SystemUser);
                $systicket->Load( $self->id );
                $const = $RT::IR::ConstituencyCache{ $self->id } =
                    $systicket->FirstCustomFieldValue('Constituency')
                    || '_none';
            }
            return if $const eq '_none';
            return if $RT::IR::HasNoQueueCache{ $const };

            my $new_queue = RT::Queue->new($RT::SystemUser);
            $new_queue->LoadByCols(
                Name => $queue->Name . " - " . $const
            );
            unless ( $new_queue->id ) {
                $RT::IR::HasNoQueueCache{$const} = 1;
                return;
            }
            $_[-1] =  [$queue, $new_queue];
        } else {
            $RT::Logger->crit("$self is not a ticket object like I expected");
        }
    };
}


if ( RT::IR->HasConstituency ) {
    # Queue {Comment,Correspond}Address for multiple constituencies

    require RT::Ticket;
    wrap 'RT::Ticket::QueueObj', pre => sub {
        my $queue = RT::Queue->new($_[0]->CurrentUser);
        $queue->Load($_[0]->__Value('Queue'));
        $queue->{'_for_ticket'} = $_[0]->id;
        $_[-1] = $queue;
        return;
    };

    wrap 'RT::Queue::HasRight', pre => sub {
        return unless $_[0]->id;
        return if $_[0]->{'disable_constituency_right_check'};
        return if $_[0]->{'_for_ticket'};
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


    require RT::Queue;
    package RT::Queue;

    sub CorrespondAddress { GetQueueAttribute(shift, 'CorrespondAddress') }
    sub CommentAddress { GetQueueAttribute(shift, 'CommentAddress') }

    sub GetQueueAttribute {
        my $queue = shift;
        my $attr  = shift;
        if ( ( my $id = $queue->{'_for_ticket'} ) ) {
            my $const = $RT::IR::ConstituencyCache{$id};
            if (!$const || $const eq '_none' ) {
                my $ticket = RT::Ticket->new($RT::SystemUser);
                $ticket->Load($id);
                $const = $RT::IR::ConstituencyCache{$ticket->id}
                    = $ticket->FirstCustomFieldValue('Constituency') || '_none';
            }
            if ($const ne '_none' && !$RT::IR::HasNoQueueCache{$const} ) {
                my $new_queue = RT::Queue->new($RT::SystemUser);
                $new_queue->LoadByCols(
                    Name => $queue->Name . " - " . $const );
                if ( $new_queue->id ) {
                    my $val = $new_queue->_Value($attr) || $queue->_Value($attr);
                    $RT::Logger->debug("Overriden $attr is $val for ticket #$id according to constituency $const");
                    return $val;
                } else {
                    $RT::IR::HasNoQueueCache{$const} = 1;
                }
            }
        }
        return $queue->_Value($attr);
    }
}


if ( RT::IR->HasConstituency ) {
    # Set Constituency on Create

    require RT::Ticket;
    wrap 'RT::Ticket::Create', pre => sub {
        my $ticket = $_[0];
        my %args = (@_[1..(@_-2)]);

        # get out if there is constituency value in arguments
        my $cf = GetCustomField( 'Constituency' );
        return unless $cf && $cf->id;
        return if $args{ 'CustomField-'. $cf->id };

        # get out of here if it's not RTIR queue
        my $QueueObj = RT::Queue->new( $RT::SystemUser );
        if ( ref $args{'Queue'} eq 'RT::Queue' ) {
            $QueueObj->Load( $args{'Queue'}->Id );
        }
        elsif ( $args{'Queue'} ) {
            $QueueObj->Load( $args{'Queue'} );
        }
        else {
            return;
        }
        return unless $QueueObj->id;
        return unless $QueueObj->Name =~
            /^(Incidents|Incident Reports|Investigations|Blocks)$/i; 
        
        # fetch value
        my $value;
        if ( $args{'MIMEObj'} ) {
            my $tmp = $args{'MIMEObj'}->head->get('X-RT-Mail-Extension');
            if ( $tmp ) {
                chomp $tmp;
                $tmp = undef unless
                    grep lc $_->Name eq lc $tmp, @{ $cf->Values->ItemsArrayRef };
            }
            $value = $tmp;
            $RT::Logger->debug("Found Constituency '$tmp' in email") if $tmp;
        }
        $value ||= RT->Config->Get('RTIR_CustomFieldsDefaults')->{'Constituency'};
        return unless $value;

        my @res = $ticket->Create(
            %args,
            'CustomField-'. $cf->id => $value,
        );
        $_[-1] = \@res;
    };
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

    my $cf = RT::IR::GetCustomField( 'IP' );
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
