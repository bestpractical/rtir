# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2016 Best Practical Solutions, LLC
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

package RT::IR::ConstituencyManager;
use strict;
use warnings;

our @RO_QUEUE_RIGHTS = (
    'ShowTicket',
    'ShowTicketComments',
    'Watch',
    'SeeQueue',
    'ShowTemplate',
);

our @DUTYTEAM_CF_RIGHTS = ( 'SeeCustomField', 'ModifyCustomField' );
our @RO_CF_RIGHTS = ('SeeCustomField');

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );
    $self->_Init(@_);
    return $self;
}

sub _Init {
    my $self = shift;
    my %args = (
        Constituency => undef,
        @_,
    );

    $self->{Constituency} = $self->SanitizeValue($args{Constituency});
}

sub Constituency {
    my $self = shift;
    return $self->{Constituency};
}

sub QueueNames {
    my $self = shift;
    my $constituency = $self->Constituency;

    return map { "$_ - $constituency" }
           map { RT::IR::FriendlyLifecycle($_) } RT::IR->Lifecycles;
}

sub WhoisCustomField {
    my $self = shift;

    my $whois_cf = RT::CustomField->new( RT->SystemUser );
    $whois_cf->LoadByName(
        Name       => 'RTIR default WHOIS server',
        LookupType => 'RT::Queue'
    );
    die "Couldn't find 'RTIR default WHOIS server' custom field"
        unless ( $whois_cf->id );

    return $whois_cf;
}

sub ConstituencyCustomField {
    my $self = shift;
    my $cf = RT::CustomField->new($RT::SystemUser);
    $cf->Load( "RTIR Constituency", LookupType => 'RT::Queue' );
    unless ( $cf->id ) {
        die "Couldn't load the constituency custom field";
    }
    return $cf;
}

sub CustomFieldValueExists {
    my $self = shift;
    my $value = shift;

    RT->Logger->debug("Check that constituency '$value' exists");

    my $cf     = $self->ConstituencyCustomField;
    my $values = $cf->Values;
    $values->Limit( FIELD => 'Name', VALUE => $value );
    my $value_obj = $values->First;
    if   ( $value_obj && $value_obj->id ) { return $value_obj }
    else                                  { return undef; }
}

sub AddCustomFieldValue {
    my $self = shift;
    my $value = shift;

    RT->Logger->debug("Adding the value to the constituency CF");

    my $cf = $self->ConstituencyCustomField;
    if ( $self->CustomFieldValueExists($value) ) {
        RT->Logger->debug("Value '$value' already exists");
    } else {
        my ( $val, $msg ) = $cf->AddValue( Name => $value );
        die $msg unless $val;
        RT->Logger->info("Added '$value' to the constituency field");
    }
    return $cf;
}

# load the first queue with the lifecycle we're after, which is meant
# a proxy for the "original" RTIR queue of that lifecycle. we can't rely
# on the name because the base countermeasures queue may be named Blocks
# due to historical reasons
sub BaseQueueForLifecycle {
    my $self = shift;
    my $lifecycle = shift;

    my $queues = RT::Queues->new(RT->SystemUser);
    $queues->Limit(FIELD => 'Lifecycle', VALUE => $lifecycle);
    $queues->OrderByCols({
        ALIAS => 'main',
        FIELD => 'id',
        ORDER => 'ASC',
    });

    return $queues->First;
}

sub CreateOrLoadQueue {
    my $self = shift;
    my %args = (
        Name       => undef,
        Lifecycle  => undef,
        Correspond => undef,
        Comment    => undef,
        @_,
    );
    my $name = $args{Name};

    my $basequeue = $self->BaseQueueForLifecycle($args{Lifecycle});

    my $queue = RT::Queue->new($RT::SystemUser);
    $queue->LoadByCols( Name => $name );
    unless ( $queue->id ) {
        my ( $val, $msg ) = $queue->Create(
            Name              => $name,
            CommentAddress    => $args{Comment},
            CorrespondAddress => $args{Correspond},
            Lifecycle         => $args{Lifecycle},
            SLADisabled       => $basequeue->SLADisabled,
        );
        RT->Logger->info("Created new queue '$name': $msg");
        RT->Logger->debug("Comment address: $args{Comment}") if $args{Comment};
        RT->Logger->debug("Correspond address: $args{Correspond}")
            if $args{Correspond};
    } else {
        RT->Logger->debug("Queue '$name' already exists");
        foreach my $type (qw(Comment Correspond)) {
            next unless $args{$type};
            my $method  = $type . 'Address';
            my $current = $queue->$method();
            next if $current eq $args{$type};

            $method = 'Set' . $method;
            my ( $status, $msg ) = $queue->$method( $args{$type} );
            unless ($status) {
                RT->Logger->error("Couldn't set $type address of '$name' queue");
            } else {
                RT->Logger->debug("new $type address: " . $args{$type});
            }
        }
        if ( $queue->SLADisabled != $basequeue->SLADisabled ) {
            my ( $status, $msg ) = $queue->SetSLADisabled( $basequeue->SLADisabled );
            if ($status) {
                RT->Logger->debug("SLADisabled: " . $queue->SLADisabled);
            }
            else {
                RT->Logger->error("Couldn't set SLADisabled of '$name' queue: $msg");
            }
        }
    }

    my $basecfs = RT::CustomFields->new( RT->SystemUser );
    $basecfs->SetContextObject($basequeue);
    $basecfs->LimitToObjectId( $basequeue->id );
    $basecfs->LimitToLookupType('RT::Queue-RT::Ticket');

    while ( my $basecf = $basecfs->Next ) {
        RT->Logger->debug("Adding Ticket CustomField "
            . $basecf->Name
            . " to queue "
            . $queue->Name);
        $basecf->AddToObject($queue);
    }

    my $base_txncfs = RT::CustomFields->new( RT->SystemUser );
    $base_txncfs->SetContextObject($basequeue);
    $base_txncfs->LimitToObjectId( $basequeue->id );
    $base_txncfs->LimitToLookupType('RT::Queue-RT::Ticket-RT::Transaction');

    while ( my $base_txncf = $base_txncfs->Next ) {
        RT->Logger->debug("Adding Ticket Transaction CustomField "
            . $base_txncf->Name
            . " to queue "
            . $queue->Name);
        $base_txncf->AddToObject($queue);
    }

    my $constituency_cf = $self->ConstituencyCustomField;
    $constituency_cf->AddToObject($queue);
    $queue->AddCustomFieldValue(
        Field => $constituency_cf->id,
        Value => $self->Constituency,
    );

    my $whois_cf = $self->WhoisCustomField;
    $whois_cf->AddToObject($queue);

    my $templates = RT::Templates->new( RT->SystemUser );
    $templates->LimitToQueue( $basequeue->id );
    while ( my $template = $templates->Next ) {
        my $new_template = RT::Template->new( RT->SystemUser );
        $new_template->Create(
            Queue => $queue->id,
            map { $_ => $template->$_ } qw/Name Description Type Content /,
        );
    }

    my $scrips = RT::Scrips->new( RT->SystemUser );
    $scrips->LimitToQueue( $basequeue->id );
    while ( my $scrip = $scrips->Next ) {
        unless ( $scrip->IsAdded( $queue->id ) ) {
            $scrip->AddToObject( $queue->id );
        }
    }

    die "Failed to create queue $name." unless $queue->id;

    return $queue;
}

sub CreateOrLoadQueues {
    my $self = shift;
    my %args = @_;

    my $constituency = $self->Constituency;
    my %queues;

    foreach my $lifecycle (RT::IR->Lifecycles) {
        my $name = RT::IR::FriendlyLifecycle($lifecycle) . " - " . $constituency;
        $queues{$lifecycle} = $self->CreateOrLoadQueue(
            Name       => $name,
            Lifecycle  => $lifecycle,
            %args,
        );
    }

    return %queues;
}

sub CreateOrLoadGroup {
    my $self = shift;
    my $name = shift;
    my $group = RT::Group->new($RT::SystemUser);
    $group->LoadUserDefinedGroup($name);
    unless ( $group->id ) {
        my ( $val, $msg ) = $group->CreateUserDefinedGroup( Name => $name );
        RT->Logger->info("Created new group $name: $msg");
    } else {
        RT->Logger->debug("Group '$name' already exists");
    }

    die "Failed to create group $name." unless $group->id;

    return $group;
}

# XXX TODO this should be looking at cfs on the new queues
sub GrantGroupCustomFieldRights {
    my $self   = shift;
    my $group  = shift;
    my @rights = (@_);

    my $cfs = RT::CustomFields->new($RT::SystemUser);
    for my $lifecycle (RT::IR->Lifecycles) {
        my $queue = $self->BaseQueueForLifecycle($lifecycle);
        $cfs->LimitToObjectId( $queue->Id );
    }

    while ( my $cf = $cfs->Next ) {
        $self->GrantGroupSingleCustomFieldRights( $cf, $group, @rights );
    }

    # explicitly grant rights on 'RTIR Constituency' cf as well
    my $rtir_constituency_cf = $self->ConstituencyCustomField();
    $self->GrantGroupSingleCustomFieldRights( $rtir_constituency_cf, $group, @rights );

    RT->Logger->info("Granted rights for custom fields to group " . $group->Name);

    return 1;
}

sub GrantGroupSingleCustomFieldRights {
    my $self   = shift;
    my $cf     = shift;
    my $group  = shift;
    my @rights = @_;

    RT->Logger->debug("Granting rights for custom field "
        . $cf->Name
        . " to group "
        . $group->Name);

    foreach my $right (@rights) {
        RT->Logger->debug("Granting right $right");
        if ($group->PrincipalObj->HasRight(
                Right  => $right,
                Object => $cf
            )
           )
        {
            RT->Logger->debug("...skipped, already granted");
            next;
        }
        my ( $val, $msg ) = $group->PrincipalObj->GrantRight(
            Right  => $right,
            Object => $cf
        );
        if ($val) {
            RT->Logger->debug("Granted right $right");
        } else {
            die "Failed to grant $right to "
                . $group->Name
                . " for Custom Field "
                . $cf->Name
                . ".\nError: $msg";
        }
    }
}

sub GrantRoleQueueRights {
    my $self   = shift;
    my $queues = shift;

    my $everyone = RT::Group->new( RT->SystemUser );
    $everyone->LoadSystemInternalGroup('Everyone');

    foreach my $queue ( values %$queues ) {
        RT->Logger->debug("Granting role rights to Everyone for queue " . $queue->Name);
        my @rights;

        if ( $queue->Lifecycle eq RT::IR->lifecycle_report ) {
            @rights = RT::IR->EveryoneIncidentReportRights();
        } elsif ( $queue->Lifecycle eq RT::IR->lifecycle_incident ) {
            @rights = RT::IR->EveryoneIncidentRights();

        }
        if ( $queue->Lifecycle eq RT::IR->lifecycle_investigation ) {
            @rights = RT::IR->EveryoneInvestigationRights();

        } elsif ( $queue->Lifecycle eq RT::IR->lifecycle_countermeasure ) {
            @rights = RT::IR->EveryoneCountermeasureRights();
        }
        # grant 'everyone' rights
        for my $right (@rights) {
            RT->Logger->debug("Granting right $right");

            if ( $everyone->PrincipalObj->HasRight(
                Object => $queue,
                Right  => $right)) {
                RT->Logger->debug("skipping, already granted");
            } else {
            my ( $val, $msg ) = $everyone->PrincipalObj->GrantRight(
                Object => $queue,
                Right  => $right
            );
            if ( !$val ) { die $msg }
            RT->Logger->debug("Granted right $right to Everyone for queue " . $queue->Name);
        }
        }
        RT->Logger->info("Granted role rights to Everyone for queue " . $queue->Name);

        # grant 'owner' rights
        RT->Logger->debug("Granting role rights to Owners on " . $queue->Name);
        for my $right ( RT::IR->OwnerAllQueueRights ) {
            RT->Logger->debug("Granting right $right...");
            my $owner = $queue->RoleGroup('Owner');
            if( $owner->PrincipalObj->HasRight(
                Object => $queue,
                Right  => $right
            )) {
                RT->Logger->debug("skipping, already granted");
            } else {
                my ( $val, $msg ) = $owner->PrincipalObj->GrantRight(
                    Object => $queue,
                    Right  => $right
                );

                if ( !$val ) { die $msg }
                RT->Logger->debug("Granted right $right...");
            }
        }
        RT->Logger->info("Granted role rights to Owners on " . $queue->Name);
    }
}

sub GrantGroupQueueRights {
    my $self   = shift;
    my $group  = shift;
    my $queues = shift;
    my @rights = (@_);

    foreach my $queue ( values %$queues ) {
        RT->Logger->debug("Granting rights for queue "
            . $queue->Name
            . " to group "
            . $group->Name);

        foreach my $right (@rights) {
            RT->Logger->debug("Granting right $right");
            if ($group->PrincipalObj->HasRight(
                    Right  => $right,
                    Object => $queue
                )
               )
            {
                RT->Logger->debug("...skipped, already granted");
                next;
            }
            my ( $val, $msg ) = $group->PrincipalObj->GrantRight(
                Right  => $right,
                Object => $queue
            );
            if ($val) {
                RT->Logger->debug("Granted right $right for queue "
                    . $queue->Name
                    . " to group "
                    . $group->Name);
            } else {
                die "Failed to grant $right to "
                    . $group->Name
                    . " for Queue "
                    . $queue->Name;
            }
        }
    }

    RT->Logger->info("Granted rights for queues to group " . $group->Name);

    return 1;
}

sub AddConstituency {
    my $self = shift;
    my %args = (
        Correspond => undef,
        Comment    => undef,
        @_,
    );

    my $constituency = $self->Constituency;

    RT->Logger->info("Adding constituency $constituency");

    my $constituency_cf = $self->AddCustomFieldValue($constituency);

    # Create our four new queues
    my %queues = $self->CreateOrLoadQueues(%args);

    # Create a DutyTeam $constituency
    my $dutyteam = $self->CreateOrLoadGroup( 'DutyTeam ' . $constituency );
    my $ro       = $self->CreateOrLoadGroup( 'ReadOnly ' . $constituency );

    # Grant that new dutyteam rights to see and update the CFs
    $self->GrantGroupCustomFieldRights( $dutyteam, @DUTYTEAM_CF_RIGHTS );

    # Grant that new dutyteam all the regular dutyteam rights for the new constituency queues
    $self->GrantGroupQueueRights( $dutyteam, \%queues,
        RT::IR->DutyTeamAllQueueRights );

    # Create or load the group "ReadOnly $constituency"
    $self->GrantGroupCustomFieldRights( $ro, @RO_CF_RIGHTS );

    # Grant the new readonly group the rights to see the RTIR queues
    $self->GrantGroupQueueRights( $ro, \%queues, @RO_QUEUE_RIGHTS );

    $self->GrantRoleQueueRights( \%queues );

    return 1;
}

sub _GroupExists {
    my $self  = shift;
    my $name  = shift;
    my $group = RT::Group->new($RT::SystemUser);
    $group->LoadByCols( Name => $name );
    return $group && $group->id ? $group : undef;
}

sub RenameConstituency {
    my $self = shift;
    my $new = $self->SanitizeValue(shift);
    my $old = $self->Constituency;

    my $constituency_cf = $self->ConstituencyCustomField;

    {
        my $value_obj = $self->CustomFieldValueExists($old);
        my ( $status, $msg ) = $value_obj->SetName($new);
        die $msg unless $status;
        RT->Logger->info("Renamed constituency value '$old' -> '$new'.");
    }

    my $queues = RT::Queues->new( RT->SystemUser );
    $queues->UnLimit;
    while ( my $queue = $queues->Next ) {
        next
            unless (
            ( $queue->FirstCustomFieldValue('RTIR Constituency') || '' ) eq
            $old );
        my $oldname = $queue->Name;
        my $newname = $oldname;
        $newname =~ s/$old/$new/;
        $queue->AddCustomFieldValue(
            Field => $constituency_cf->id,
            Value => $new
        );
        my ( $status, $msg ) = $queue->SetName($newname);
        die $msg unless $status;

        RT->Logger->info("Renamed queue '$oldname' -> '$newname'");
    }

    foreach my $basename (qw(DutyTeam Readonly)) {
        my $old_name = "$basename $old";
        my $new_name = "$basename $new";

        my $group = $self->_GroupExists($old_name);
        unless ($group) {
            RT->Logger->debug("Group '$old_name' doesn't exist. Skipping...");
            next;
        }
        if ( $self->_GroupExists($new_name) ) {
            die
                "Couldn't rename group, target '$new_name' already exists.";
        }

        my ( $status, $msg ) = $group->SetName($new_name);
        die $msg unless $status;

        RT->Logger->info("Renamed group '$old_name' -> '$new_name'");
    }

    return 1;
}

sub SanitizeValue {
    my $self = shift;
    my $value = shift;

    # cleanup value
    $value = '' unless defined $value;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $value =~ s/\s+/ /gs;
    return $value;
}

1;

