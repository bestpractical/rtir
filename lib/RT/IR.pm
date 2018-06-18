# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2018 Best Practical Solutions, LLC
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

use 5.008003;
use strict;
use warnings;

package RT::IR;

our $VERSION = '3.2.1';


use Scalar::Util qw(blessed);


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
    $queue = $queue->Name if ref $queue;
    return undef unless $queue;
    return '' unless $QUEUES{ lc $queue };
    return $TYPE{ lc $queue };
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

sub Queues {
    return @QUEUES;
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
        my $obj = RT::Ticket->new( RT->SystemUser );
        $obj->Load( ref $arg{'Ticket'} ? $arg{'Ticket'}->id : $arg{'Ticket'} );
        $arg{'Queue'} = $obj->QueueObj->Name if $obj->id;
    }
    return undef unless defined $arg{'Queue'};

    return $TYPE{ lc $arg{'Queue'} } if !ref $arg{'Queue'} && $arg{'Queue'} !~ /^\d+$/;

    my $obj = RT::Queue->new( RT->SystemUser );
    $obj->Load( ref $arg{'Queue'}? $arg{'Queue'}->id : $arg{'Queue'} );
    return $TYPE{ lc $obj->Name } if $obj->id;

    return;
}

=head2 Statuses

Return sorted list of unique statuses for one, many or all RTIR queues.

Takes arguments 'Queue', 'Active' and 'Inactive'. By default returns
initial and active statuses. Queue can be an array reference to list several
queues.

Examples:

    RT::IR->Statuses()
    RT::IR->Statuses( Queue => 'Blocks' );
    RT::IR->Statuses( Queue => [ 'Blocks', 'Incident Reports' ] );
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
    my %arg = ( Queue => undef, Initial => 1, Active => 1, Inactive => 0, @_ );

    my @queues = $flat->( $arg{'Queue'} || \@QUEUES );

    my (@initial, @active, @inactive);
    foreach my $queue (@queues) {
        unless ( blessed $queue ) {
            my $tmp = RT::Queue->new(RT->SystemUser);
            $tmp->Load( $queue );
            RT->Logger->error( "failed to load queue $queue" )
                unless $tmp->id;
            $queue = $tmp;
        }
        next unless $queue->id;

        my $cycle = $queue->LifecycleObj;
        push @initial, $cycle->Initial if $arg{'Initial'};
        push @active, $cycle->Active if $arg{'Active'};
        push @inactive, $cycle->Inactive if $arg{'Inactive'};
    }

    my %seen = ();
    return grep !$seen{$_}++, @initial, @active, @inactive;
}

sub ActiveQuery {
    return (shift)->Query( Initial => 1, Active => 1, @_ );
}

sub Query {
    my $self = shift;
    my %args = (
        Queue        => undef,
        Status       => undef,
        Active       => undef,
        Inactive     => undef,
        Exclude      => undef,
        HasMember    => undef,
        HasNoMember  => undef,
        MemberOf     => undef,
        NotMemberOf  => undef,
        Constituency => undef,
        And          => undef,
        @_
    );

    my @res;
    if ( $args{'Queue'} ) {
        push @res, map "($_)", join ' OR ', map "Queue = '$_'",
            $flat->( $args{'Queue'}, 'Name' );
    }
    if ( !$args{'Status'} && ( $args{'Initial'} || $args{'Active'} || $args{'Inactive'} ) ) {
        $args{'Status'} = [ $self->Statuses( %args ) ];
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
    if (
        my $t = $args{'Constituency'}
        and RT->Config->Get('_RTIR_Constituency_Propagation') eq 'reject'
    ) {
        unless ( ref $t ) {
            my $tmp = RT::Ticket->new( RT->SystemUser );
            $tmp->Load( $t );
            $t = $tmp;
        }
        push @res, "CustomField.{Constituency} = '". $t->FirstCustomFieldValue('Constituency') ."'";
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
    if ( $res && $res !~ /\bQueue\b/ ) {
        $res = "Queue = 'Incidents' AND ($res)";
    }
    return $res;
}

sub OurQuery {
    my $self = shift;
    my $query = shift;

    my ($has_our, $has_other, @queues) = (0, 0);
    $ticket_sql_parser->walk(
        RT::SQL::ParseToArray( $query ),
        { operand => sub {
            return undef unless $_[0]->{'key'} =~ /^Queue(?:\z|\.)/;
            my $queue = RT::Queue->new( RT->SystemUser );
            $queue->Load( $_[0]->{'value'} );
            my $our = $self->OurQueue( $queue );
            my ($negative) = ( $_[0]->{'op'} eq '!=' || $_[0]->{'op'} =~ /\bNOT\b/i );
            if ( $our && !$negative ) {
                $has_our = 1;
                push @queues, $queue->Name;
            } else {
                $has_other = 1;
            }
        } },
    );
    return unless $has_our && !$has_other;
    return 1 unless wantarray;

    my %seen;
    @queues = grep !$seen{ lc $_ }++, @queues;

    return (1, @queues);
}

=head2 Incidents

Takes a ticket and returns collection of all incidents this ticket
is member of.

=cut

sub Incidents {
    my $self = shift;
    my $ticket = shift;

    my $res = RT::Tickets->new( $ticket->CurrentUser );
    $res->FromSQL( $self->Query( Queue => 'Incidents', HasMember => $ticket ) );
    return $res;
}

=head2 RelevantIncidents

Takes a ticket and returns collection of incidents this ticket
is member of excluding abandoned incidents.

=cut

sub RelevantIncidentsQuery {
    my $self = shift;
    my $ticket = shift;

    return "Queue = 'Incidents' AND HasMember = ". $ticket->id
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
    my %args = (Queue => \@QUEUES, @_);

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
    $children->FromSQL( $self->ActiveQuery( Queue => \@QUEUES, MemberOf => $incident->id ) );
    while ( my $child = $children->Next ) {
        next if $self->IsLinkedToActiveIncidents( $child, $incident );
        return 1;
    }
    return 0;
}

=head2 IsLinkedToActiveIncidents $ChildObj [$IncidentObj]

Returns number of active incidents linked to child ticket
(IR, Investigation, Block or other). If second argument provided
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
        Queue     => 'Incidents',
        HasMember => $child,
        ($parent ? (Exclude   => $parent->id) : ()),
    ) );
    return $tickets->Count;
}

sub MapStatus {
    my $self = shift;
    my ($status, $from, $to) = @_;
    return unless $status;

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
            my $queue = RT::Queue->new( RT->SystemUser );
            $queue->Load( $e );
            $e = $queue->LifecycleObj;
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
    my $whois = Net::Whois::RIPE->new( $host, Port => $port, Debug => 1 );
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
        foreach my $qname ( @QUEUES ) {
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
    %cache = ();
} }


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

{ my $cache;
sub HasConstituency {
    return $cache if defined $cache;

    my $self = shift;
    return $cache = $self->CustomFields('Constituency');
}
sub _FlushHasConstituencyCache {
    undef $cache;
} }

sub DefaultConstituency {
    my $queue = shift;
    my $name = $queue->Name;

    my @values;

    my $queues = RT::Queues->new( RT->SystemUser );
    $queues->Limit( FIELD => 'Name', OPERATOR => 'STARTSWITH', VALUE => "$name - ", CASESENSITIVE => 0 );
    while ( my $pqueue = $queues->Next ) {
        next unless $pqueue->HasRight( Principal => $queue->CurrentUser, Right => "ShowTicket" );
        push @values, substr $pqueue->__Value('Name'), length("$name - ");
    }
    my $default = RT->Config->Get('RTIR_CustomFieldsDefaults')->{'Constituency'} || '';
    return $default if grep lc $_ eq lc $default, @values;
    return shift @values;
}


if ( RT::IR->HasConstituency ) {

    # lots of wrapping going on
    no warnings 'redefine';

    # flush constituency caches on each request
    require RT::Interface::Web::Handler;
    my $orig_CleanupRequest = RT::Interface::Web::Handler->can('CleanupRequest');
    *RT::Interface::Web::Handler::CleanupRequest = sub {
        %RT::IR::ConstituencyCache = ();
        %RT::IR::HasNoQueueCache = ();
        RT::Queue::_FlushQueueHasRightCache();
        RT::IR::_FlushCustomFieldsCache();
        RT::IR::_FlushHasConstituencyCache();
        $orig_CleanupRequest->();
    };

    require RT::Ticket;
    # flush constituency cache for a ticket when the Constituency CF is updated
    # RT::Ticket currently uses RT::Record::_AddCustomFieldValue so we just insert not wrap
    # I wonder what happens when you Delete an OCFV, since it doesn't hit this code path.
    # This also clears the constituency cache when updating the IP Custom Field, intentional?
    sub RT::Ticket::_AddCustomFieldValue {
        my $self = shift;
        $RT::IR::ConstituencyCache{$self->id}  = undef;
        return $self->RT::Record::_AddCustomFieldValue(@_);
    };

    # Tickets with Constituencies CF values that point to a Constituency
    # Queue such as Incidents - EDUNET should return multiple Queues as
    # EquivalenceObjects for checking rights. Constituency DutyTeams
    # have their rights granted on the relevant Constituency Queues, so
    # RT needs to know to check in both places for the combination of
    # their rights.
    my $orig_ACLEquivaluenceObjects = RT::Ticket->can('ACLEquivalenceObjects');
    *RT::Ticket::ACLEquivalenceObjects = sub {
        my $self = shift;

        my $queue = RT::Queue->new(RT->SystemUser);
        $queue->Load($self->__Value('Queue'));

        # For historical reasons, the System just returned a System Queue on this Ticket
        # rather than delve into the overridden QueueObj.  It's possible this is no longer needed.
        # The biggest thing that $self->QueueObj would do is return a queue with _for_ticket set
        # which causes a lot of code to skip Constituency checks, so we'd need to duplicate that.
        # We punt early on non-IR queues because otherwise we try to look for constituency Queues
        # and the negative cache (_none) is disabled, leading to perf problems.
        # It's also somewhat concerning that we return a SystemUser queue outside IR queues.
        if ( ( $self->CurrentUser->id == RT->SystemUser->id ) ||
             ( ! RT::IR->OurQueue( $queue ) ) ) {
            return $queue;
        }

        # Old old bulletproofing, can probably delete.
        unless ( UNIVERSAL::isa( $self, 'RT::Ticket' ) ) {
            RT->Logger->crit("$self is not a ticket object like I expected");
            return;
        }

        # We check both uncached constituencies and those explicitly negatively cached
        # The commit that introduced this doesn't say what bug it was fixing, but it's definitely
        # a perf hit.
        my $const = $RT::IR::ConstituencyCache{ $self->id };
        if (!$const || $const eq '_none' ) {
            my $systicket = RT::Ticket->new(RT->SystemUser);
            $systicket->Load( $self->id );
            $const = $RT::IR::ConstituencyCache{ $self->id } =
                $systicket->FirstCustomFieldValue('Constituency') || '_none';
        }

        # If this ticket still has no constituency, or the constituency it is assigned
        # doesn't have a corresponding Constituency queue, return the default Queue.
        if ( $const eq '_none' || $RT::IR::HasNoQueueCache{ $const } ) {
            return $orig_ACLEquivaluenceObjects->($self,@_);
        }

        # Track that there is no Constituency queue for the Constituency recorded in the CF on this ticket.
        my $constituency_queue = RT::Queue->new(RT->SystemUser);
        $constituency_queue->LoadByCols( Name => $queue->Name . " - " . $const );
        unless ( $constituency_queue->id ) {
            $RT::IR::HasNoQueueCache{$const} = 1;
            return $orig_ACLEquivaluenceObjects->($self,@_);
        }

        # If a constituency queue such as 'Incidents - EDUNET' exists, we want to check
        # ACLs on both of them.
        return $queue, $constituency_queue;
    };
}

# Skip the global AutoOpen and AutoOpenInactive scrip on Blocks and Incident Reports
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
        my $ticket = $self->TicketObj;
        my $type = RT::IR::TicketType( Ticket => $ticket );
        return 0 if $type && ( $type eq 'Block' || $type eq 'Report' );
        return $self->$prepare(@_);
    };
}
require RT::Action::AutoOpenInactive;
{
    no warnings 'redefine';
    my $prepare = RT::Action::AutoOpenInactive->can('Prepare');
    *RT::Action::AutoOpenInactive::Prepare = sub {
        my $self = shift;
        my $ticket = $self->TicketObj;
        my $type = RT::IR::TicketType( Ticket => $ticket );
        return 0 if $type && ( $type eq 'Block' || $type eq 'Report' );
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

if ( RT::IR->HasConstituency ) {
    # Queue {Comment,Correspond}Address for multiple constituencies

    no warnings 'redefine';

    # returns an RT::Queue that has _for_ticket set to indicate
    # that we're using this Queue to check something about a ticket
    # that may have a Constituency.
    require RT::Ticket;
    my $orig_QueueObj = RT::Ticket->can('QueueObj');
    *RT::Ticket::QueueObj = sub {
        my $self = shift;
        # RT::Ticket::QueueObj uses a cache
        my $queue = $orig_QueueObj->($self,@_);
        # used to know that this Queue was retrieved from a ticket
        # so we can skip a bunch of constituency checks...
        $queue->{'_for_ticket'} = $self->id;
        return $queue;
    };

    require RT::Queue;
    package RT::Queue;

    { my $queue_cache = {};
    # RT 4.2 removed RT::Queue's HasRight, meaning we can just stub one in
    sub HasRight {
        my $self = shift;
        my %args = @_;

        return $self->SUPER::HasRight(@_) unless $self->id;
        # currently only obviously used so that one right can be checked
        # on Incidents not Incidents - EDUNET during Constituency CF
        # editing.
        return $self->SUPER::HasRight(@_) if $self->{'disable_constituency_right_check'};
        # Not really convinced this is right, since it gets set on $ticket->QueueObj
        # commit messages that add it are vague about why it was added.
        return $self->SUPER::HasRight(@_) if $self->{'_for_ticket'};

        my $name = $self->__Value('Name');
        return $self->SUPER::HasRight(@_) unless $name =~
            /^(Incidents|Incident Reports|Investigations|Blocks)$/i;

        $args{'Principal'} ||= $self->CurrentUser->PrincipalObj;

        # Avoid going to the database on every Queue->HasRight('ModifyCustomField') or any
        # other Queue right, but in RTIR, CF rights checks at the Queue level are very heavy.
        my $equiv_objects;
        if ( $queue_cache->{$name} ) {
            $equiv_objects = $queue_cache->{$name};
        } else {
            my $queues = RT::Queues->new( RT->SystemUser );
            $queues->Limit( FIELD => 'Name', OPERATOR => 'STARTSWITH', VALUE => "$name - ", CASESENSITIVE => 0 );
            $equiv_objects = $queues->ItemsArrayRef;
            $queue_cache->{$name} = $equiv_objects;
        }

        my $has_right = $args{'Principal'}->HasRight(
            %args,
            Object => $self,
            EquivObjects => $equiv_objects,
        );
        return $has_right;
    };
    sub _FlushQueueHasRightCache { undef $queue_cache  };
    }


    # TODO SubjectTag and Encryption Keys need overriding also
    sub CorrespondAddress { GetQueueAttribute(shift, 'CorrespondAddress') }
    sub CommentAddress { GetQueueAttribute(shift, 'CommentAddress') }

    # dive down to get Queue Attributes from Incidents - EDUNET rather than Incidents
    # Populates ConstituencyCache and HasNoQueueCache, but has the same
    # bug around always over-checking the Constituency CF if we've
    # cached that a ticket has no Constituency.
    sub GetQueueAttribute {
        my $queue = shift;
        my $attr  = shift;

        if ( RT::IR->OurQueue($queue) ) {
            if ( ( my $id = $queue->{'_for_ticket'} ) ) {
                my $const = $RT::IR::ConstituencyCache{$id};
                if (!$const || $const eq '_none' ) {
                    my $ticket = RT::Ticket->new(RT->SystemUser);
                    $ticket->Load($id);
                    $const = $RT::IR::ConstituencyCache{$ticket->id}
                        = $ticket->FirstCustomFieldValue('Constituency') || '_none';
                }
                if ($const ne '_none' && !$RT::IR::HasNoQueueCache{$const} ) {
                    my $new_queue = RT::Queue->new(RT->SystemUser);
                    $new_queue->LoadByCols( Name => $queue->Name . " - " . $const );
                    if ( $new_queue->id && !$new_queue->Disabled ) {
                        my $val = $new_queue->_Value($attr) || $queue->_Value($attr);
                        RT->Logger->debug("Overriden $attr is $val for ticket #$id according to constituency $const");
                        return $val;
                    } else {
                        $RT::IR::HasNoQueueCache{$const} = 1;
                    }
                }
            }
        }
        return $queue->_Value($attr);
    }
}


if ( RT::IR->HasConstituency ) {
    # Set Constituency on Create

    no warnings 'redefine';

    require RT::Ticket;
    my $orig_Create = RT::Ticket->can('Create');
    *RT::Ticket::Create = sub {
        my $self = shift;
        my %args = @_;

        # get out if there is constituency value in arguments
        my $cf = GetCustomField( 'Constituency' );
        unless ($cf && $cf->id) {
            return $orig_Create->($self,%args);
        }
        if ($args{ 'CustomField-'. $cf->id }) {
            return $orig_Create->($self,%args);
        }

        # get out of here if it's not RTIR queue
        my $QueueObj = RT::Queue->new( RT->SystemUser );
        if ( ref $args{'Queue'} eq 'RT::Queue' ) {
            $QueueObj->Load( $args{'Queue'}->Id );
        }
        elsif ( $args{'Queue'} ) {
            $QueueObj->Load( $args{'Queue'} );
        }
        else {
            return $orig_Create->($self,%args);
        }
        unless ( $QueueObj->id &&
                 $QueueObj->Name =~ /^(Incidents|Incident Reports|Investigations|Blocks)$/i ) {
            return $orig_Create->($self,%args);
        }

        
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
            RT->Logger->debug("Found Constituency '$tmp' in email") if $tmp;
        }
        $value ||= RT->Config->Get('RTIR_CustomFieldsDefaults')->{'Constituency'};
        unless ($value) {
            return $orig_Create->($self,%args);
        }

        my @res = $orig_Create->(
            $self,
            %args,
            'CustomField-'. $cf->id => $value,
        );
        return @res;
    };
}

require RT::Search::Simple;
package RT::Search::Simple;

sub HandleRtirip {
    return 'RTIR IP' => RT::IR->Query(
        Queue => ['Incidents', 'Incident Reports', 'Investigations', 'Blocks'],
        And => "'CustomField.{IP}' = '$_[1]'",
    );
}

sub HandleRtirrequestor {
    my $self = shift;
    my $value = shift;

    my $children = RT::Tickets->new( $self->TicketsObj->CurrentUser );
    $children->FromSQL(
        "( Queue = 'Incident Reports' OR
           Queue = 'Investigations' OR
           Queue = 'Blocks'
         ) AND Requestor LIKE '$value'"
    );
    my $query = '';
    while ( my $child = $children->Next ) {
        $query .= " OR " if $query;
        $query .= "HasMember = " . $child->Id;
    }
    $query ||= 'id = 0';
    return 'RTIR Requestor' => "Queue = 'Incidents' AND ($query)";
}

package RT::IR;

RT::Base->_ImportOverlays;

1;
