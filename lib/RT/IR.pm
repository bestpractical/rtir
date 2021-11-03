# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2021 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
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
# END BPS TAGGED BLOCK }}}

package RT::IR;
use 5.008003;
use strict;
use warnings;

our $VERSION = '5.0.2';

use Scalar::Util qw(blessed);


# XXX: we push config metadata into RT, but we need
# need interface to load config options metadata from
# extensions in RT core

use RT::IR::Config;
use RT::IR::Web;
use RT::IR::ConstituencyManager;
RT::IR::Config::Init();



sub lifecycle_report {'incident_reports'}
sub lifecycle_incident {'incidents'}
sub lifecycle_investigation {'investigations'}
sub lifecycle_countermeasure {'countermeasures'}


my @LIFECYCLES = (RT::IR->lifecycle_incident, RT::IR->lifecycle_report, RT::IR->lifecycle_investigation, RT::IR->lifecycle_countermeasure);

my %TYPE = (
    RT::IR->lifecycle_incident       => 'Incident',
    RT::IR->lifecycle_report         => 'Report',
    RT::IR->lifecycle_investigation  => 'Investigation',
    RT::IR->lifecycle_countermeasure => 'Countermeasure',

    'incident reports' => 'Report',
);

# these are used by initialdata to form the default queue names
my %FRIENDLY_LIFECYCLE = (
    RT::IR->lifecycle_incident       => 'Incidents',
    RT::IR->lifecycle_report         => 'Incident Reports',
    RT::IR->lifecycle_investigation  => 'Investigations',
    RT::IR->lifecycle_countermeasure => 'Countermeasures',

);

sub DutyTeamAllQueueRights {
    return (
        qw( CreateTicket
            ShowTemplate
            OwnTicket
            CommentOnTicket
            SeeQueue
            ShowTicket
            ShowTicketComments
            StealTicket
            TakeTicket
            Watch
            ShowOutgoingEmail
            ForwardMessage
            ));

}

sub OwnerAllQueueRights {
    return (qw(ModifyTicket));
}

sub EveryoneIncidentReportRights {
    return (qw(CreateTicket ReplyToTicket));
}

sub EveryoneIncidentRights {
    return ();
}

sub EveryoneCountermeasureRights {
    return (qw(ReplyToTicket));
}

sub EveryoneInvestigationRights {
    return (qw(ReplyToTicket));
}

use Parse::BooleanLogic;
my $ticket_sql_parser = Parse::BooleanLogic->new;

RT->AddJavaScript('jquery.uncheckable-radio-0.1.js');
RT->AddStyleSheets( 'rtir-styles.css' );

# Add the RTIR search result page to the whitelist to allow
# bookmarks to work without CSRF warnings, similar to the RT
# search result page. As noted in the similar RT configuration,
# whitelisted search links can be used for denial-of-service against RT
# (construct a very inefficient query and trick lots of users into
# running them against RT). This is offset by the general usefulness of
# bookmarking search links.

$RT::Interface::Web::is_whitelisted_component{'/RTIR/Search/Results.html'} = 1;

=head1 FUNCTIONS

=head2 IsStaff

Is the user id passed in a member of one of the DutyTeam groups

Useful for differentiating between actions by a user of the system vs
actions by someone flagged to work on RTIR.

=cut

sub IsStaff {
    my $self = shift;
    my $actor_id = shift;

    my $cgm = RT::CachedGroupMembers->new( RT->SystemUser );
    $cgm->Limit(FIELD => 'MemberId', VALUE => $actor_id );
    my $group_alias = $cgm->Join(
        FIELD1 => 'GroupId', TABLE2 => 'Groups', FIELD2 => 'id'
    );
    $cgm->Limit(
        ALIAS    => $group_alias,
        FIELD    => 'Name',
        OPERATOR => 'LIKE',
        VALUE    => 'DutyTeam',
        CASESENSITIVE => 0,
    );
    $cgm->RowsPerPage(1);
    return $cgm->First? 1 : 0;
}

=head2 OurQueue

Takes queue name or L<RT::Queue> object and returns its type
(see L</TicketType>). Returns undef if argument is not valid.
Returns empty string if queue is not one of RTIR's.

=cut

sub OurQueue {
    my $self = shift;
    my $queue = shift;

    my $lifecycle;

    if (ref $queue) {
        $lifecycle = $queue->Lifecycle;
    } else {
        my $temp_queue = RT::Queue->new(RT->SystemUser);
        $temp_queue->Load($queue);
        $lifecycle = $temp_queue->Lifecycle
    }

    return undef unless $lifecycle;
    return '' unless defined $TYPE{ $lifecycle };
    return $TYPE{ $lifecycle };
}


=head2 OurLifecycle LIFECYCLE

Takes a scalar lifecycle name or a lifecycle object.
Returns true if this lifecycle is an RTIR lifecycle. Returns undef otherwise

=cut

sub OurLifecycle {
    my $self = shift;
    my $lifecycle = shift;
    
    if (ref $lifecycle) {
        $lifecycle = $lifecycle->Name;
    }
    return defined  $FRIENDLY_LIFECYCLE{$lifecycle};

}


=head2 Types

Returns a list of valid L<TicketType>s

=cut

sub Types {
    my $self = shift;
    return values %TYPE;
}

=head2 Queues

Returns a list of the core RTIR Queue names

=cut

{ my @cache;
sub Queues {
    unless (@cache) {
        my $queues = RT::Queues->new( RT->SystemUser );

        $queues->Limit(
            FIELD => 'Lifecycle',
            OPERATOR => 'IN',
            VALUE => \@LIFECYCLES,
        );

        while (my $queue = $queues->Next) {
            push @cache, $queue->Name;
        }
    }
    return @cache;
}

sub FlushQueuesCache {
    @cache = ();
    return 1;
} }

=head2 GetRTIRDefaultQueue

Processes global and user-level configuration options to find the default
queue for the current user.

Accepts no arguments, returns the ID of the default RTIR queue, if found, or undef.

Mirrors GetDefaultQueue from RT.

=cut

sub GetRTIRDefaultQueue {
    my $queue;

    $queue = RT->Config->Get( "RTIR_DefaultQueue", $HTML::Mason::Commands::session{'CurrentUser'} );

    return $queue;
}

=head2 Lifecycles

Return a list of the core RTIR lifecycle names

=cut

sub Lifecycles {
    return @LIFECYCLES;
}

=head2 FriendlyLifecycle

XXX TODO 

=cut

sub FriendlyLifecycle {
    my $lifecycle = shift;
    return $FRIENDLY_LIFECYCLE{$lifecycle};

}

=head2 TicketType

Returns type of a ticket. Takes Ticket, Lifecycle or Queue as an argument.
Both arguments could be objects or IDs, however, name of a queue
works too for Queue argument. If the queue argument is defined then
the ticket is ignored even if it's defined too.

=cut

sub TicketType {
    my %arg = ( Lifecycle => undef, Queue => undef, Ticket => undef, @_);
    if ( defined $arg{'Lifecycle'}) {
        return $TYPE{$arg{'Lifecycle'}};
    }

    if ( defined $arg{'Ticket'} && !defined $arg{'Queue'} ) {
        my $obj = RT::Ticket->new( RT->SystemUser );
        $obj->Load( ref $arg{'Ticket'} ? $arg{'Ticket'}->id : $arg{'Ticket'} );
        return $TYPE{ $obj->QueueObj->Lifecycle } if $obj->id;
    }
    return undef unless defined $arg{'Queue'};

    my $obj = RT::Queue->new( RT->SystemUser );
    if (ref $arg{'Queue'}) {
        $obj->Load($arg{'Queue'}->id);
    }
    elsif ($arg{'Queue'} =~/^\d+$/) {
        $obj->Load($arg{'Queue'});
    } else {
        $obj->LoadByCols(Name => $arg{'Queue'});
    }

    return undef unless ($obj->id);

    return $TYPE{ $obj->Lifecycle };
}

=head2 Statuses

Return sorted list of unique statuses for one, many or all RTIR queues.

Takes arguments 'Lifecycle', 'Active' and 'Inactive'. By default returns
initial and active statuses. Lifecycle can be an array reference to list several
lifecycles.

Examples:

    RT::IR->Statuses()
    RT::IR->Statuses( Lifecycle => 'countermeasures' );
    RT::IR->Statuses( Lifecycle => [ 'countermeasures', 'incident_reports' ] );
    RT::IR->Statuses( Active => 0, Inactive => 1 );

=cut

my $flat = sub {
    my ($arg, $method) = @_;
    my @list = blessed $arg ? ($arg) : ref $arg ? @$arg : ($arg);
    if ( $method ) {
        $_ = $_->$method() foreach grep blessed($_), @list;
    }
    return @list;
};

sub Statuses {
    my $self = shift;
    my %arg = ( Lifecycle => undef, Initial => 1, Active => 1, Inactive => 0, @_ );

    my (@initial, @active, @inactive);

        my @lifecycles = $flat->( $arg{'Lifecycle'} || \@LIFECYCLES );
    
        foreach my $cycle (@lifecycles) {
            unless ( blessed $cycle ) {
                my $tmp = RT::Lifecycle->Load( Name => $cycle);
                RT->Logger->error( "failed to load lifecycle $cycle" )
                    unless $tmp->Name;
                $cycle = $tmp;
            }
            next unless $cycle->Name;
    
            push @initial, $cycle->Initial if $arg{'Initial'};
            push @active, $cycle->Active if $arg{'Active'};
            push @inactive, $cycle->Inactive if $arg{'Inactive'};
        }
    my %seen = ();
    return grep !$seen{$_}++, @initial, @active, @inactive;
}

=head2 ActiveQuery ARGS

ActiveQuery is a wrapper around Query which automatically limits
results to tickets in active or initial states.

=cut

sub ActiveQuery {
    return (shift)->Query( Initial => 1, Active => 1, @_ );
}

sub Query {
    my $self = shift;
    my %args = (
        Lifecycle    => undef,
        Status       => undef,
        Active       => undef,
        Inactive     => undef,
        Exclude      => undef,
        HasMember    => undef,
        HasNoMember  => undef,
        MemberOf     => undef,
        NotMemberOf  => undef,
        And          => undef,
        Constituency => undef,
        @_
    );

    my @res;
    if ( $args{'Lifecycle'} ) {
        push @res, map "($_)", join ' OR ', map "Lifecycle = '$_'",
            $flat->( $args{'Lifecycle'});
    }
    if ( !$args{'Status'} && ( $args{'Initial'} || $args{'Active'} || $args{'Inactive'} ) ) {
        $args{'Status'} = [ $self->Statuses( Lifecycle => $args{'Lifecycle'}, Active => $args{'Active'}, Inactive => $args{'Inactive'}, Initial => $args{'Initial'})];
    }
    if ( my $s = $args{'Status'} ) {
        push @res, join ' OR ', map "Status = '$_'", $flat->( $s );
    }
    if ( my $t = $args{'Exclude'} ) {
        push @res, join ' AND ', map "id != '$_'", map int $_, $flat->( $t, 'id' );
    }
    if ( my $t = $args{'HasMember'} ) {
        push @res, join ' OR ', map "HasMember = $_", map int $_, $flat->( $t, 'id' );
    }
    if ( my $t = $args{'HasNoMember'} ) {
        push @res, join ' AND ', map "HasMember != $_", map int $_, $flat->( $t, 'id' );
    }
    if ( my $t = $args{'MemberOf'} ) {
        push @res, join ' OR ', map "MemberOf = $_", map int $_, $flat->( $t, 'id' );
    }
    if ( my $t = $args{'NotMemberOf'} ) {
        push @res, join ' AND ', map "MemberOf != $_", map int $_, $flat->( $t, 'id' );
    }
    if ( my $t = $args{'Constituency'} ) {
        push @res, "'QueueCF.{RTIR Constituency}' = '$t'";
    }
    if ( my $c = $args{'And'} ) {
        push @res, ref $c? @$c : ($c);
    }
    return join ' AND ', map { /\b(?:AND|OR)\b/? "( $_ )" : $_ } @res;
}

use Regexp::Common qw(RE_net_IPv4);
use Regexp::IPv6 qw($IPv6_re);
our @SIMPLE_SEARCH_GUESS = (
    [ 11 => sub { return "rtirrequestor" if /\@/ } ],
    [ 12 => sub {
        return "Rtirip" if /^\s*(?:$RE{net}{IPv4}|$IPv6_re)\s*$/o
            && RT::IR->CustomFields('IP')
    } ],
);
sub ParseSimpleSearch {
    my $self = shift;
    my %args = @_;

    local @RT::Search::Simple::GUESS = (
        @RT::Search::Simple::GUESS,
        @SIMPLE_SEARCH_GUESS,
    );

    my $search = RT::Search::Simple->new(
        Argument => $args{'Query'},
        TicketsObj => RT::Tickets->new( $args{'CurrentUser'} ),
    );
    my $res = $search->QueryToSQL;
    if ( $res && $res !~ /\bQueue\b/ && $res !~ /\bLifecycle\b/ ) {
        $res = "Lifecycle = 'incidents' AND ($res)";
    }
    return $res;
}

sub OurQuery {
    my $self = shift;
    my $query = shift;

    my ($has_our, $has_other, @lifecycles) = (0, 0);
    $ticket_sql_parser->walk(
        RT::SQL::ParseToArray( $query ),
        { operand => sub {
            return undef unless $_[0]->{'key'} =~ /^(Queue(?:\z|\.)|Lifecycle)/;
            my $key = $1;

            my ($negative) = ( $_[0]->{'op'} eq '!=' || $_[0]->{'op'} =~ /\bNOT\b/i );
            my ( $our, $lifecycle );

            if ( $key eq 'Lifecycle' ) {
                $our = $self->OurLifecycle( $_[0]->{'value'} );
                $lifecycle = $_[0]->{'value'};
            }
            else {
                my $queue = RT::Queue->new( RT->SystemUser );
                $queue->Load( $_[0]->{'value'} );
                $our = $self->OurQueue( $queue );
                $lifecycle = $queue->Lifecycle;
            }

            if ( $our && !$negative ) {
                $has_our = 1;
                push @lifecycles, $lifecycle;
            } else {
                $has_other = 1;
            }
        } },
    );
    return unless $has_our && !$has_other;
    return 1 unless wantarray;

    my %seen;
    @lifecycles = grep !$seen{ lc $_ }++, @lifecycles;

    return (1, @lifecycles);
}

=head2 Incidents

Takes a ticket and returns collection of all incidents this ticket
is member of.

=cut

sub Incidents {
    my $self = shift;
    my $ticket = shift;

    my $res = RT::Tickets->new( $ticket->CurrentUser );
    $res->FromSQL( $self->Query( Lifecycle => 'incidents', HasMember => $ticket ) );
    return $res;
}

=head2 RelevantIncidents

Takes a ticket and returns collection of incidents this ticket
is member of excluding abandoned incidents.

=cut

sub RelevantIncidentsQuery {
    my $self = shift;
    my $ticket = shift;

    return "Lifecycle = 'incidents' AND HasMember = ". $ticket->id
        ." AND Status != 'abandoned'"
    ;
}

sub RelevantIncidents {
    my $self = shift;
    my $ticket = shift;

    my $res = RT::Tickets->new( $ticket->CurrentUser );
    $res->FromSQL( $self->RelevantIncidentsQuery( $ticket, @_ ) );
    return $res;
}

sub IncidentChildren {
    my $self = shift;
    my $ticket = shift;
    my %args = (Lifecycle => \@LIFECYCLES, @_);

    my $res = RT::Tickets->new( $ticket->CurrentUser );
    $res->FromSQL( $self->Query( %args, MemberOf => $ticket->id ) );
    return $res;
}

=head2 IncidentHasActiveChildren

=cut

sub IncidentHasActiveChildren {
    my $self = shift;
    my $incident = shift;

    my $children = RT::Tickets->new( $incident->CurrentUser );
    $children->FromSQL( $self->ActiveQuery( Lifecycle => \@LIFECYCLES, MemberOf => $incident->id ) );
    while ( my $child = $children->Next ) {
        next if $self->IsLinkedToActiveIncidents( $child, $incident );
        return 1;
    }
    return 0;
}

=head2 IsLinkedToActiveIncidents $ChildObj [$IncidentObj]

Returns number of active incidents linked to child ticket
(IR, Investigation, Countermeasure or other). If second argument provided
then it's excluded from count.

When function return zero that means that object has no active
parent incidents.

=cut

sub IsLinkedToActiveIncidents {
    my $self = shift;
    my $child = shift;
    my $parent = shift;

    my $tickets = RT::Tickets->new( $child->CurrentUser );
    $tickets->FromSQL( $self->ActiveQuery(
        Lifecycle     => 'incidents',
        HasMember => $child,
        ($parent ? (Exclude   => $parent->id) : ()),
    ) );
    return $tickets->Count;
}

sub MapStatus {
    my $self = shift;
    my ($status, $from, $to) = @_;
    return unless $status;

    # Validate that the from and to are legitimate
    foreach my $e ($from, $to) {
        if ( blessed $e ) {
            if ( $e->isa('RT::Queue') ) {
                $e = $e->LifecycleObj;
            }
            elsif ( $e->isa('RT::Ticket') ) {
                $e = $e->QueueObj->LifecycleObj;
            }
            elsif ( !$e->isa('RT::Lifecycle') ) {
                $e = undef;
            }
        }
        else {
            my $lifecycle = RT::Lifecycle->Load( Name => $e );
            $e = $lifecycle;
        }
        return unless $e;
    }
    my $res = $from->MoveMap( $to )->{ $status };
    unless ( $res ) {
        RT->Logger->warning(
            "No mapping for $status in ". $from->Name .' lifecycle'
            .' to status in '. $to->Name .' lifecycle'
        );
    }
    return $res;
}

sub FirstWhoisServer {
    my $self = shift;
    my $servers = RT->Config->Get('whois');
    my ($res) = map ref $servers->{$_}? $servers->{$_}->{'Host'}: $servers->{$_},
        (sort keys %$servers)[0];
    return $res;
}

sub WhoisLookup {
    my $self = shift;
    my %args = (
        Server => undef,
        Query  => undef,
        @_
    );

    my $server = $args{'Server'} || $self->FirstWhoisServer;
    return (undef, $args{'CurrentUser'}->loc("No whois servers configured"))
        unless $server;

    my ($host, $port) = split /\s*:\s*/, $server, 2;
    $port = 43 unless ($port || '') =~ /^\d+$/;

    use Net::Whois::RIPE;
    my $debug;
    for my $log_config ( qw/LogToSyslog LogToSTDERR LogToFile/ ) {
        if ( ( RT->Config->Get( $log_config ) // '' ) eq 'debug' ) {
            $debug = 1;
            last;
        }
    }
    my $whois = Net::Whois::RIPE->new( $host, Port => $port, Debug => $debug || 0 );
    my $iterator;
    $iterator = $whois->query_iterator( $args{'Query'} )
        if $whois;
    return (undef, $args{'CurrentUser'}->loc("Unable to connect to WHOIS server '[_1]'", $server) )
        unless $iterator;

    return $iterator;
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
        foreach my $qname ( Queues() ) {
            my $type = TicketType( Queue => $qname );
            $cache{$type} = [];

            my $queue = RT::Queue->new( RT->SystemUser );
            $queue->Load( $qname );
            unless ($queue->id) {
                RT->Logger->error("Couldn't load queue '$qname'");
                delete $cache{$type};
                return;
            }

            my $cfs = RT::CustomFields->new( RT->SystemUser );
            $cfs->LimitToLookupType( 'RT::Queue-RT::Ticket' );
            $cfs->LimitToQueue( $queue->id );
            while ( my $cf = $cfs->Next ) {
                push @{ $cache{$type} }, $cf;
            }
        }

        $cache{'Global'} = [];
        my $cfs = RT::CustomFields->new( RT->SystemUser );
        $cfs->LimitToLookupType( 'RT::Queue-RT::Ticket' );
        $cfs->LimitToGlobal;
        while ( my $cf = $cfs->Next ) {
            push @{ $cache{'Global'} }, $cf;
        }
    }

    my $type = TicketType( %arg );

    my @list;
    if ( $type ) {
        @list = (@{ $cache{'Global'} }, @{ $cache{$type} || [] });
    } else {
        @list = (@{ $cache{'Global'} }, map { @{ $_ || [] } } @cache{values %TYPE});
    }

    if ( my $field = $arg{'Field'} ) {
        if ( $field =~ /\D/ ) {
            @list = grep { lc $_->Name eq lc $field } @list;
        } else {
            @list = grep { $_->id == $field } @list;
        }
    }

    return wantarray? @list : $list[0];
}

sub FlushCustomFieldsCache {
    %cache = ();
    return 1;
} }

{
    no warnings 'redefine';

    # flush caches on each request
    require RT::Interface::Web::Handler;
    my $orig_CleanupRequest = RT::Interface::Web::Handler->can('CleanupRequest');
    *RT::Interface::Web::Handler::CleanupRequest = sub {
        RT::IR::FlushCustomFieldsCache();
        RT::IR::FlushQueuesCache();
        $orig_CleanupRequest->();
    };
}

sub FilterRTAddresses {
    my $self = shift;
    my %args = (ARGSRef => undef, Fields => {}, results => [], @_);

    my $cu = do { no warnings 'once'; $HTML::Mason::Commands::session{'CurrentUser'} };

    my $found = 0;
    while ( my ($field, $display) = each %{ $args{'Fields'} } ) {
        my $value = $args{'ARGSRef'}{ $field };
        next unless defined $value && length $value;

        if ( ref $value ) {
            RT->Logger->warning("FilterRTAddresses received a reference for $field".ref $value);
            if ( ref $value eq 'ARRAY' ) {
                $value = join(", ",@$value);
            } else {
                RT->Logger->warning("Not an arrayref, nothing good can come from this, bailing");
                next;
            }
        }

        my @emails = Email::Address->parse( $value );
        foreach my $email ( grep RT::EmailParser->IsRTAddress($_->address), @emails ) {
            push @{ $args{'results'} }, $cu->loc("[_1] is an address RT receives mail at. Adding it as a '[_2]' would create a mail loop", $email->format, $cu->loc($display) );
            $found = 1;
            $email = undef;
        }
        $args{'ARGSRef'}{ $field } = join ', ', map $_->format, grep defined, @emails;
    }
    return $found;
}

# Skip the global AutoOpen and AutoOpenInactive scrip on Countermeasures and Incident Reports
# This points to RTIR wanting to muck with the global scrips using the 4.2 scrips
# organization, although it possibly messes with Admins expectations of 'contained Queues'
# We have to hit both because the first is installed on upgraded RTs while the latter is
# installed on fresh 4.2 installs and Admins are free to configure either.
require RT::Action::AutoOpen;
{
    no warnings 'redefine';
    my $prepare = RT::Action::AutoOpen->can('Prepare');
    *RT::Action::AutoOpen::Prepare = sub {
        my $self = shift;
        my $type = $self->TicketObj->QueueObj->Lifecycle;
        return 0 if $type && ( $type eq RT::IR->lifecycle_countermeasure || $type eq RT::IR->lifecycle_report);
        return $self->$prepare(@_);
    };
}
require RT::Action::AutoOpenInactive;
{
    no warnings 'redefine';
    my $prepare = RT::Action::AutoOpenInactive->can('Prepare');
    *RT::Action::AutoOpenInactive::Prepare = sub {
        my $self = shift;
        my $type = $self->TicketObj->QueueObj->Lifecycle;
        return 0 if $type && ( $type eq RT::IR->lifecycle_countermeasure || $type eq RT::IR->lifecycle_report);
        return $self->$prepare(@_);
    };
}

# Because you can't (easily/cleanly/prettily) merge two
# RT::Ticket entries in %CustomFieldGroupings, add a new
# RTIR::Ticket option.
require RT::CustomField;
{
    RT::CustomField->RegisterBuiltInGroupings(
            'RTIR::Ticket'    => [ qw(Basics Dates People) ],
    );

    no warnings 'redefine';
    my $orig_GroupingClass = RT::CustomField->can('_GroupingClass');
    *RT::CustomField::_GroupingClass = sub {
        my $self        = shift;
        my $record      = shift;

        my $record_class = $orig_GroupingClass->($self,$record);

        # we're only doing shenanigans on Tickets, which might be RTIR::Ticket
        unless ($record_class eq 'RT::Ticket') {
            return $record_class;
        }

        my $queue = undef;
        # on Create we can get an empty RT::Ticket here
        if ( ref $record && $record->Id ) {
            $queue = $record->QueueObj->Name;
        # if we have an empty ticket, but a real CustomField,
        # we can pull the Queue out of the ACLEquivalenceObjects
        } elsif ( ref $self ) {
            for my $obj ($self->ACLEquivalenceObjects) {
                next unless (ref $obj eq 'RT::Queue');
                $queue = $obj->Name;
                last;
            }
        }

        if (RT::IR->OurQueue($queue)) {
            return 'RTIR::Ticket';
        } else {
            return $record_class;
        }
    };
}


=head2 HREFTo

XXX TODO this wants a better name.


=cut

sub HREFTo {
    my $self = shift;
    my $page = shift;
    my %args = (
        IncludeWebPath => 1,
        Constituency   => $HTML::Mason::Commands::m->{'RTIR_ConstituencyFilter'},
        @_
    );
    # XXX TODO - this code has a dependency on the implementation
    # of the mason UI. It might want to be either in a web handler
    # related namespace or to have a better abstraction
    my $c = '';
    if ($args{'Constituency'}) {  
        $c = 'c/'.$args{'Constituency'}."/";
    }
    return ($args{IncludeWebPath} ? RT->Config->Get('WebPath') : '') .'/RTIR/'.$c.$page;
}



=head2 URL

XXX TODO

=cut

=head2 ConstituencyFor $Ticket|$Queue

Returns the textual constituency name for any RTIR ticket or queue
Returns undef for non-RTIR tickets and queues.

Dies if handed something that's not a ticket or queue

=cut


sub ConstituencyFor {
    my $self = shift;
    my $object = shift;
    if ($object->isa('RT::Queue')) {
        return $object->FirstCustomFieldValue('RTIR Constituency');
    }

    die "$object is not a ticket object" unless ref($object) && $object->isa('RT::Ticket');
    return $object->QueueObj->FirstCustomFieldValue('RTIR Constituency');
}

sub IsReportQueue {
    my $self  = shift;
    my $queue = shift;
    return $queue->Lifecycle eq $self->lifecycle_report;
}

sub IsIncidentQueue {
    my $self  = shift;
    my $queue = shift;
    return $queue->Lifecycle eq $self->lifecycle_incident;
}

sub IsInvestigationQueue {
    my $self  = shift;
    my $queue = shift;
    return $queue->Lifecycle eq $self->lifecycle_investigation;
}

sub IsCountermeasureQueue {
    my $self  = shift;
    my $queue = shift;
    return $queue->Lifecycle eq $self->lifecycle_countermeasure;
}


sub StrictConstituencyLinking {
    my $self = shift;
    return RT->Config->Get('RTIR_StrictConstituencyLinking');
}


require RT::Search::Simple;
package RT::Search::Simple;

sub HandleRtirip {
    return 'RTIR IP' => RT::IR->Query(
        Lifecycle => \@LIFECYCLES,
        And => "'CustomField.{IP}' = '$_[1]'",
    );
}

sub HandleRtirrequestor {
    my $self = shift;
    my $value = shift;

    my $children = RT::Tickets->new( $self->TicketsObj->CurrentUser );
    $children->FromSQL(
        "( Lifecycle = '".RT::IR->lifecycle_report."' OR
           Lifecycle = '".RT::IR->lifecycle_investigation."' OR
           Lifecycle = '".RT::IR->lifecycle_countermeasure."'
         ) AND Requestor LIKE '$value'"
    );
    my $query = '';
    while ( my $child = $children->Next ) {
        $query .= " OR " if $query;
        $query .= "HasMember = " . $child->Id;
    }
    $query ||= 'id = 0';
    return 'RTIR Requestor' => "Lifecycle = '".RT::IR->lifecycle_incident."' AND ($query)";
}

package RT::IR;

sub ImportOverlays {
    my $class = shift;
    my ($package,undef,undef) = caller();
    $package =~ s|::|/|g;
    for my $type (qw(Overlay Vendor Local)) {
        my $filename = $package."_".$type.".pm";
        eval { require $filename };
        die $@ if ($@ && $@ !~ qr{^Can't locate $filename});
    }
    return;
}

__PACKAGE__->ImportOverlays();

1;
