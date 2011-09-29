=head1 NAME

RT::IR::Config - RTIR specific options and defaults for RT

=head1 WARNING

NEVER EDIT RTIR_Config.pm.

Instead, copy any sections you want to change to F<RT_SiteConfig.pm> and edit them there.

=head1 Base Configuration

=over 4

=item C<$rtirname>

Set the name of the RTIR application.

=cut

Set( $rtirname, RT->Config->Get('rtname') );

=item C<%Lifecycles>

RTIR defines four lifecycles for each its queue: 'incidents',
'incident_reports', 'investigations' and 'blocks'.

Note that all four lifecycles are mapped to each other, so
in theory it's possible to move tickets between queues, but
importantly it's required to perform certain operations.
For example when user abandons Incident all its children
should be inactivated as well, to figure out which status
set on a child the map is used.

Read F<etc/RT_Config.pm> which describes this option in details.

=cut

Set(
    %Lifecycles,
    incidents => {
        initial         => [],
        active          => ['open'],
        inactive        => ['resolved', 'abandoned'],

        defaults => {
            on_create => 'open',
            on_merge  => 'resolved',
        },

        transitions => {
            # from   => [ to list ],
            ''        => [qw(open)],
            open      => [qw(resolved abandoned)],
            resolved  => [qw(open)],
            abandoned => [qw(open)],
        },
        rights  => { '* -> *' => 'ModifyTicket', },
        actions => [
            'open -> resolved'  => {
                label => 'Resolve', update => 'Comment',
                All => 1, SelectAllTickets => 1,
            },
            'open -> resolved'  => {
                label => 'Quick Resolve',
            },
            'open -> abandoned' => {
                label => 'Abandon', update => 'Comment',
                All => 1, SelectAllTickets => 1,
            },
            '* -> open'  => {
                label => 'Re-open',
                All => 1, SelectAllTickets => 1,
            },
        ],
    },
    incident_reports => {
        initial         => [ 'new' ],
        active          => [ 'open' ],
        inactive        => [ 'resolved', 'rejected' ],

        defaults => {
            on_create => 'new',
            on_merge  => 'resolved',
            approved  => 'open',
            denied    => 'rejected',
        },

        transitions => {
            # from   => [ to list ],
            ''       => [qw(new open resolved)],
            new      => [qw(open resolved rejected)],
            open     => [qw(resolved rejected)],
            resolved => [qw(open)],
            rejected => [qw(open)],
        },
        rights  => { '* -> *' => 'ModifyTicket', },
        actions => [
            'new -> open'      => { label => 'Open It', update => 'Respond' },
            '* -> resolved'    => { label => 'Resolve', update => 'Comment' },
            '* -> resolved'    => { label => 'Quick Resolve' },
            '* -> rejected'    =>
                { label => 'Reject',  update => 'Respond', TakeOrStealFirst => 1 },
            '* -> rejected'    => { label => 'Quick Reject', TakeOrStealFirst => 1 },
            '* -> open'        => { label => 'Re-open' },
        ],
    },
    investigations => {
        initial         => [],
        active          => ['open'],
        inactive        => ['resolved'],

        defaults => {
            on_create => 'open',
            on_merge  => 'resolved',
            approved  => 'open',
            denied    => 'resolved',
        },

        transitions => {
            # from   => [ to list ],
            ''       => [qw(open resolved)],
            open     => [qw(resolved)],
            resolved => [qw(open)],
        },
        rights  => { '* -> *' => 'ModifyTicket', },
        actions => [
            '* -> resolved'    => { label => 'Resolve', update => 'Comment' },
            '* -> resolved'    => { label => 'Quick Resolve' },
            'resolved -> open' => { label => 'Re-open' },
        ],
    },
    blocks => {
        initial         => ['pending activation'],
        active          => [ 'active', 'pending removal' ],
        inactive        => ['removed'],

        defaults => {
            on_create => 'pending activation',
            on_merge  => 'removed',
            approved  => 'active',
            denied    => 'removed',
        },

        transitions => {
            ''                   => [ 'pending activation', 'active' ],
            'pending activation' => [ 'active', 'removed' ],
            active               => [ 'pending removal', 'removed' ],
            'pending removal'    => [ 'removed', 'active' ],
            removed              => [ 'active' ],
        },
        rights  => { '* -> *' => 'ModifyTicket', },
        actions => [
            '* -> active'  => { label => 'Activate', update => 'Comment' },
            '* -> removed' => { label => 'Remove', update => 'Comment' },
            '* -> removed' => { label => 'Quick Remove' },
            '* -> pending removal' =>
                { label => 'Pending Removal', update => 'Comment' },
        ],
    },
    __maps__ => {
        'incidents -> incident_reports' => {
            'open'      => 'open',
            'resolved'  => 'resolved',
            'abandoned' => 'rejected',
        },
        'incidents -> investigations' => {
            'open'      => 'open',
            'resolved'  => 'resolved',
            'abandoned' => 'resolved',
        },
        'incidents -> blocks' => {
            'open'      => 'active',
            'resolved'  => 'removed',
            'abandoned' => 'removed',
        },
        'incident_reports -> incidents' => {
            'new'      => 'open',
            'open'     => 'open',
            'resolved' => 'resolved',
            'rejected' => 'abandoned',
        },
        'incident_reports -> investigations' => {
            'new'      => 'open',
            'open'     => 'open',
            'resolved' => 'resolved',
            'rejected' => 'resolved',
        },
        'incident_reports -> blocks' => {
            'new'      => 'pending activation',
            'open'     => 'active',
            'resolved' => 'removed',
            'rejected' => 'removed',
        },
        'investigations -> incidents' => {
            'open'     => 'open',
            'resolved' => 'resolved',
        },
        'investigations -> incident_reports' => {
            'open'     => 'open',
            'resolved' => 'resolved',
        },
        'investigations -> blocks' => {
            'open'     => 'active',
            'resolved' => 'removed',
        },
        'blocks -> incidents' => {
            'pending activation' => 'open',
            'active'             => 'open',
            'pending removal'    => 'open',
            'removed'            => 'resolved',
        },
        'blocks -> incident_reports' => {
            'pending activation' => 'new',
            'active'             => 'open',
            'pending removal'    => 'open',
            'removed'            => 'resolved',
        },
        'blocks -> investigations' => {
            'pending activation' => 'open',
            'active'             => 'open',
            'pending removal'    => 'open',
            'removed'            => 'resolved',
        },
    },
);

=back

=head1 Web Interface Configuration

=over 4

=item C<$WebNoAuthRegex>

RTIR serves URLs with F</RTIR/NoAuth/> paths that shouldn't
be protected by authentication. If you customize this option
make sure to include this path as well.

=cut

my $rt_no_auth = RT->Config->Get('WebNoAuthRegex');
Set($WebNoAuthRegex, qr{ (?: $rt_no_auth | ^/+RTIR/+NoAuth/ ) }x);

=item C<$MaxInlineBody>

By default, RT only displays text attachments inline up to
the first 16k. RTIR will display them no matter how long
they are.

=cut

Set($MaxInlineBody, 0);

=item C<$OverdueAfter>

Set the number of days a message awaiting an external response
may be inactive before the ticket becomes overdue

=cut

Set($OverdueAfter, 7);

=item C<$ReplyString>

This is the string that indicates a reply, and which will be
pre-pended to subjects when you reply to tickets, for example:

    Set($ReplyString, 'Re:');

=cut

Set($ReplyString , '');

=item C<$RTIR_OldestRelatedTickets>

Controls how far back, in days, RTIR should look for tickets which
might contain a specific string, such as an IP address. Sixty
days by default.

=cut

Set($RTIR_OldestRelatedTickets, 60);

=item C<$RTIRSearchResultFormats>

Default formats for RTIR search results

=cut

Set($RTIRSearchResultFormats, {
    Default =>
        q{'<b><a HREF="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __QueueName__,
          __Status__,
          __LastUpdatedRelative__,
          __CreatedRelative__,
          __NEWLINE__,
          '',__Requestors__,__OwnerName__,__ToldRelative__,__DueRelative__,__TimeLeft__},
    ReportDefault =>
        q{'<b><a HREF="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Status__,
          __LastUpdatedRelative__,
          __CreatedRelative__,
          __NEWLINE__,
          '',__Requestors__,__OwnerName__,__ToldRelative__,__DueRelative__,__TimeLeft__},
    InvestigationDefault =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Status__,
          __LastUpdatedRelative__,
          __CreatedRelative__,
          __NEWLINE__,
          '', __Requestors__, __OwnerName__, __ToldRelative__, __DueRelative__, __TimeLeft__},

    BlockDefault =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Status__,
          __LastUpdatedRelative__,
          __CreatedRelative__,
          __NEWLINE__,
          '', __Requestors__, __OwnerName__, __ToldRelative__, __DueRelative__, __TimeLeft__},

    IncidentDefault =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Status__,
          __LastUpdatedRelative__,
          __CreatedRelative__,
          __Priority__,
          __NEWLINE__,
          '', '', __OwnerName__, __ToldRelative__, __DueRelative__, __TimeLeft__},

    Merge =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Requestors__, __OwnerName__, __CreatedRelative__, __DueRelative__},

    LinkChildren =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Requestors__, __OwnerName__, __CreatedRelative__, __DueRelative__},

    LinkIncident =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __OwnerName__, __CreatedRelative__},

    RejectReports =>
        q{'<a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a>/TITLE:#',
          '<a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a>/TITLE:Subject',
          __HasIncident__, __Requestors__, __OwnerName__, __CreatedRelative__, __DueRelative__},

    BulkReply =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __KeyRequestors__, __KeyOwnerName__, __CreatedRelative__, __DueRelative__},

    DueIncidents =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __OwnerName__, __Priority__, __DueRelative__, __UpdateStatus__},

    AbandonIncidents =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __OwnerName__, __Priority__, __DueRelative__},

    NewReports =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Requestors__, __OwnerName__, __DueRelative__, __Take__},

    ChildReport =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Status__,
          __DueRelative__},

    ChildInvestigation =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Status__,
          __DueRelative__},

    ChildBlock =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Status__,
           __DueRelative__},

    LookupTool =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Status__,
          __Priority__},

} );

=item C<$DisplayAfterEdit>

Enable this option if you want jump to display screen after saving changes
on the edit screen.

=cut

Set($DisplayAfterEdit, 1);

=item C<$SimplifiedRecipients>

Set to show list of recipients above reply box.

=cut

Set( $SimplifiedRecipients, 1 );

=item C<@RTIR_HomepageComponents>

Components that available to add on the first page of the RTIR.

=cut

Set(@RTIR_HomepageComponents, qw(
    QuickCreate
    Quicksearch
    MyAdminQueues
    MySupportQueues
    MyReminders
    RefreshHomepage
    Dashboards
    SavedSearches
    /RTIR/Elements/NewReports
    /RTIR/Elements/UserDueIncidents
    /RTIR/Elements/NobodyDueIncidents
    /RTIR/Elements/DueIncidents
));

=item C<@Active_MakeClicky>

Define list of enabled MakeClicky extensions; RTIR extends the
default 'httpurl', and additionally provides 'ip', 'ipdecimal',
'email', 'domain' and 'RIPE'.

It is possible to add your own types of clicky links using callbacks;
see F<html/Callbacks/RTIR/Elements/MakeClicky/Default> for an example.

B<NOTE> that list is order-sensetive, when one action matches text
other actions don't apply to the same matched text.

By default RTIR enables 'httpurl_overwrite', 'ip', 'email' and 'domain'.

=cut

Set(@Active_MakeClicky, qw(httpurl_overwrite ip email domain));

=back

=head1 Custom Fields

=over 4

=item C<%RTIR_CustomFieldsDefaults>

Set the defaults for RTIR custom fields. Values are case-sensitive.

=cut

Set(
    %RTIR_CustomFieldsDefaults,
    SLA => {
        InHours    => 'Full service',
        OutOfHours => 'Full service: out of hours',
    },
    'How Reported'  => "",
    'Reporter Type' => "",
    IP              => "",
    Netmask         => "",
    Port            => "",
    'Where Blocked' => "",
    Function        => "",
    Classification  => "",
    Description     => "",
    Resolution      => {
        resolved => "successfully resolved",
        rejected => "no resolution reached",
    },
    Constituency => 'EDUNET',
);

=item C<$_RTIR_Constituency_Propagation>

Set constituency propagation algorithm. Valid values are 'no',
'inherit' and 'reject', by default 'no' propagation happens.

Read more about constituencies in F<lib/RT/IR/Constituency.pod>.
Algorithms are described in 'Changing the value' chapter.

=cut

Set( $_RTIR_Constituency_Propagation,    'no' );

=back

=head1 Blocks

=over 4

=item C<$RTIR_DisableBlocksQueue>

If true then Blocks queue functionality inactive and disabled.

=cut

Set($RTIR_DisableBlocksQueue, 0);

=item C<$RTIR_BlockAproveActionRegexp>

When requestor replies on the block in pending state RTIR
changes state, you can set regular expresion so state would
be changed only when content matches the regexp.

=cut

Set($RTIR_BlockAproveActionRegexp, undef);

=back

=head1 Research Tools

RTIR comes with a few research tools available at F<Tools/Lookup.html>.

=over 4

=item C<@RTIRResearchTools>

Which research tools should RTIR display for address/domain lookups.

For each tool listed in this section, RTIR will attempt to display
using the following mason components:

    html/RTIR/Tools/Elements/ToolForm____
    html/RTIR/Tools/Elements/ToolResults____

=cut

Set( @RTIRResearchTools, (qw(Traceroute Whois Iframe)));

=item C<$RTIRIframeResearchToolConfig>

One of the research tools available in RTIR allows you to
configure a set of search URLs that incident handlers
can use to open searches in IFRAMES.

Entries are keyed by integer in the order you'd like to see
them in the dropdown on the research page. Each entry consists
of a hashref containing "FriendlyName" and "URL". The URLs will
be evaluated to replace __SearchTerm__ with the user's current
search term.

=cut

Set($RTIRIframeResearchToolConfig, {
    1 => { FriendlyName => 'Google', URL => 'https://encrypted.google.com/search?q=__SearchTerm__' },
    2 => { FriendlyName => 'CVE', URL => 'http://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=__SearchTerm__'},
    3 => { FriendlyName => 'TrustedSource.org', URL => 'http://www.trustedsource.org/query/__SearchTerm__'},
    4 => { FriendlyName => 'McAfee SiteAdvisor', URL => 'http://www.siteadvisor.com/sites/__SearchTerm__'},
    5 => { FriendlyName => 'BFK DNS Logger', URL => 'http://www.bfk.de/bfk_dnslogger.html?query=__SearchTerm__#result'}
} );

=item C<$TracerouteCommand>

Path to traceroute command.

=cut

Set($TracerouteCommand, '/usr/sbin/traceroute');

=item C<$whois>

Whois servers for the research tool.

Host is of the form "hostname:port"

=cut

Set($whois, {
    1 => {
        Host         => "whois.iana.org",
        FriendlyName => "IANA",
    },
    5 => {
        Host         => "whois.ripe.net",
        FriendlyName => "RIPE",
    },
    2 => {
        Host         => "whois.internic.net",
        FriendlyName => "INTERNIC",
    },
    3 => {
        Host         => "whois.arin.net",
        FriendlyName => "ARIN",
    },
} );

=item C<$RunWhoisRequestByDefault>

RTIR prior to 2.6.1 was running whois request by default on lookup.
Now it requires user interaction. Set C<$RunWhoisRequestByDefault>
to true value return back old behaviour.

=cut

Set($RunWhoisRequestByDefault, 0);

=back

=head1 Service Level Agreements (SLA)

RTIR comes with very basic SLA implementation. Depending on the following
options Due date of tickets is maintained.

=over 4

=item C<$SLAModule>

Set the name of the Business::SLA class. Use this if you have
a custom SLA module, for example:

    Set($SLAModule, 'Business::MySLA');

=cut

Set($SLAModule, '');

=item C<$SLA>

Define service levels and set the number of minutes.

=cut

Set($SLA, {
    'Full service'               => { BusinessMinutes => 60,    RealMinutes => 0 },
    'Full service: out of hours' => { BusinessMinutes => 120,   RealMinutes => 0 },
    'Reduced service'            => { BusinessMinutes => 120,   RealMinutes => 0 },
    'Now (in business hours)'    => { BusinessMinutes => 0,     RealMinutes => 0 },
    '60 Real Minutes'            => { BusinessMinutes => undef, RealMinutes => 60 },
} );

=item C<$BusinessHours>

Set the Business Hours for your organization, for example:

    Set($BusinessHours, {
        0 => { Name => 'Sunday', Start => undef, End => undef },
        1 => { Name => 'Monday', Start => '09:00', End => '18:00' },
        2 => { Name => 'Tuesday', Start => '09:00', End => '18:00' },
        ...
    } );

If left unset, defaults are Monday through Friday 09:00 to 18:00

=cut

Set( $BusinessHours, undef );

=item C<$SLA_Response_InHours> and C<$SLA_Response_OutOfHours>

Set service levels for responses in business hours and out,
correspondingly.

=cut

Set($SLA_Response_InHours,    'Now (in business hours)');
Set($SLA_Response_OutOfHours, 'Now (in business hours)');

=item C<$SLA_Reopen_InHours> and C<$SLA_Reopen_OutOfHours>

Set service levels for tickets re-opened in business hours and out,
correspondingly.

=cut

Set($SLA_Reopen_InHours,    'Full service');
Set($SLA_Reopen_OutOfHours, 'Full service: out of hours');

=back

=cut
1;
