use warnings;
=head1 NAME

RT::IR::Config - RTIR specific options and defaults for RT

=head1 WARNING

NEVER EDIT RTIR_Config.pm.

Instead, create RTIR_SiteConfig.pm in /opt/rt5/etc and edit anything
you wish to change there.

=head1 Base Configuration

=over 4

=item C<$rtirname>

Set the name of the RTIR application.

=cut

Set( $rtirname, RT->Config->Get('rtname') );

=item C<%Lifecycles>

RTIR defines four lifecycles for each its queue: 'incidents',
'incident_reports', 'investigations' and 'countermeasures'.

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
                All => 1,
                SelectedReportsAll => 1, SelectedInvestigationsAll => 1, SelectedCountermeasuresAll => 1,
            },
            'open -> resolved'  => {
                label => 'Quick Resolve',
            },
            'open -> abandoned' => {
                label => 'Abandon', update => 'Comment',
                All => 1,
                SelectedReportsAll => 1, SelectedInvestigationsAll => 1, SelectedCountermeasuresAll => 1,
            },
            '* -> open'  => {
                label => 'Re-open',
                All => 1,
                SelectedReportsAll => 1, SelectedInvestigationsAll => 1, SelectedCountermeasuresAll => 1,
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
    countermeasures => {
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
        'incidents -> countermeasures' => {
            'open'      => 'active',
            'resolved'  => 'removed',
            'abandoned' => 'removed',
        },
        'incidents -> default' => {
            'open'      => 'open',
            'resolved'  => 'resolved',
            'abandoned' => 'rejected',
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
        'incident_reports -> countermeasures' => {
            'new'      => 'pending activation',
            'open'     => 'active',
            'resolved' => 'removed',
            'rejected' => 'removed',
        },
        'incident_reports -> default' => {
            'new'      => 'new',
            'open'     => 'open',
            'resolved' => 'resolved',
            'rejected' => 'rejected',
        },
        'investigations -> incidents' => {
            'open'     => 'open',
            'resolved' => 'resolved',
        },
        'investigations -> incident_reports' => {
            'open'     => 'open',
            'resolved' => 'resolved',
        },
        'investigations -> countermeasures' => {
            'open'     => 'active',
            'resolved' => 'removed',
        },
        'investigations -> default' => {
            'open'     => 'open',
            'resolved' => 'resolved',
        },
        'countermeasures -> incidents' => {
            'pending activation' => 'open',
            'active'             => 'open',
            'pending removal'    => 'open',
            'removed'            => 'resolved',
        },
        'countermeasures -> incident_reports' => {
            'pending activation' => 'new',
            'active'             => 'open',
            'pending removal'    => 'open',
            'removed'            => 'resolved',
        },
        'countermeasures -> investigations' => {
            'pending activation' => 'open',
            'active'             => 'open',
            'pending removal'    => 'open',
            'removed'            => 'resolved',
        },
        'countermeasures -> default' => {
            'pending activation' => 'new',
            'active'             => 'open',
            'pending removal'    => 'open',
            'removed'            => 'resolved',
        },
        'default -> incident_reports' => {
            'new'       => 'new',
            'open'      => 'open',
            'resolved'  => 'resolved',
            'rejected'  => 'rejected',
            'stalled'   => 'open',
        },
        'default -> incidents' => {
            'new'       => 'open',
            'open'      => 'open',
            'resolved'  => 'resolved',
            'rejected'  => 'abandoned',
            'stalled'   => 'open',
        },
        'default -> investigations' => {
            'new'       => 'open',
            'open'      => 'open',
            'resolved'  => 'resolved',
            'rejected'  => 'resolved',
            'stalled'   => 'open',
        },
        'default -> countermeasures' => {
            'new'       => 'active',
            'open'      => 'active',
            'resolved'  => 'removed',
            'rejected'  => 'removed',
            'stalled'   => 'pending activation',
        },
    },
);

=item C<%LinkedQueuePortlets>

C<%LinkedQueuePortlets> allows you to display links to tickets in
another queue in a stand-alone portlet on the ticket display page.
This makes it easier to highlight specific ticket links separate from
the standard Links portlet.

You can include multiple linked queues in each ticket and they are
displayed in the order you define them in the configuration. The values
are RT link types: 'DependsOn', 'DependedOnBy', 'HasMember'
(children), 'MemberOf' (parents), 'RefersTo', and 'ReferredToBy'.
'All' lists all linked tickets. You can include multiple link types.

=cut

Set( %LinkedQueuePortlets, (
    Incidents   => [
        { 'Incident Reports'  => [ 'All' ] },
        { Investigations      => [ 'All' ] },
        { Countermeasures     => [ 'All' ] },
    ],
));

=item C<%LinkedQueuePortletFormats>

C<%LinkedQueuePortletFormats> defines the format for displaying
linked tickets in each linked queue portlet defined by C<%LinkedQueuePortlets>.

The 'Default' format will be used by default.

To change the format for all 3 RTIR default linked queues, for
example:

    Set( %LinkedQueuePortletFormats,
        'Incident Reports' =>
            q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
            q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
            q{Status,OwnerName,LastUpdatedRelative},

        Investigations =>
            q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
            q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
            q{Status,OwnerName,LastUpdatedRelative},

        Countermeasures =>
            q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
            q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
            q{Status,OwnerName,LastUpdatedRelative},
    );

=cut

=item C<%RTIR_IncidentChildren>

Option controls relations between an incident and
reports, investigations and countermeasures. Each
entry of the hash is a pair where key is type of
child and value is hash with Multiple and Required
keys and boolean values, for example:

    Set(%RTIR_IncidentChildren,
        Report => {
            Multiple => 1,
            Required => 0,
        },
        ...
    );

So each entry defines if ticket of particular type
can be linked to Multiple incidents or only one.
Also, whether it's required to link ticket to
an Incident on creation in UI or it's optional.

By default IRs can be linked to many incident and
it's not required to link them right away.
Investigations can be linked only to one incident
and it can be done later. Countermeasures can not be created
without incident, however can be linked to many of
them.

=cut

Set(%RTIR_IncidentChildren,
    Report => {
        Multiple => 1,
        Required => 0,
    },
    Investigation => {
        Multiple => 0,
        Required => 0,
    },
    Countermeasure => {
        Multiple => 1,
        Required => 1,
    },
);

=item C<$RTIR_RedirectOnLogin>

If set to a true value, will redirect members of DutyTeam groups to
/RTIR/ upon login so that they immediately see the RTIR Homepage (rather
than their RT Homepage).  This does not change where Home in the menu
links to, since you can get to the RTIR homepage from RTIR at the top
level, and users may wish to have more custom searches stashed on their
Home page.

=cut

Set($RTIR_RedirectOnLogin, 1);

=item C<$RTIR_RedirectOnSearch>

If set to a true value, searches initiated on the RT search page
that contain RTIR-related queues will redirect to the RTIR search
page. The default is true.

=cut

Set($RTIR_RedirectOnSearch, 1);

=item C<$RTIR_DefaultQueue>

Starting in RT/RTIR 5.0, the queue selection dropdown is on the ticket
create page. RTIR has separate create pages from RT, so this allows you
to set a default queue for RT and a different one for RTIR.

This option defaults to C<Incident Reports>.

=cut

Set($RTIR_DefaultQueue, 'Incident Reports');

=back


=head1 Constituency Configuration

=over 4

=item C<$RTIR_StrictConstituencyLinking>


Set constituency enforcement algorithm.

Read more about constituencies in F<docs/Constituencies.pod>.
Algorithms are described in
L<Constituencies/Constituency Propagation>.

=cut

Set( $RTIR_StrictConstituencyLinking,  1  );


=back

=head1 Web Interface Configuration

=over 4

=item C<$MaxInlineBody>

By default, RT only displays text attachments inline up to
the first 12k; RTIR increases this to 25k.

=cut

Set($MaxInlineBody, 25 * 1024);

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

Controls what tickets (LastUpdated > "RTIR_OldestRelatedTickets days ago")
are returned for searches generated from the Lookup tools. This applies
to searches for IP addresses and Hostnames linked from Ticket histories
that are run against Lookup.html and any other custom code that links to
Lookup.html to run a query.

=cut

Set($RTIR_OldestRelatedTickets, 60);

=item C<%RTIRSearchResultFormats>

Default formats for RTIR search results

If you only want to override one entry, you can copy only part of this,
which will protect you during upgrades because other entries will be
merged from this configuration.  To change just the Investigation list you would do:

    Set(%RTIRSearchResultFormats, InvestigationDefault => 'modified configuration');

=cut

Set(%RTIRSearchResultFormats,
    Default =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{QueueName,Status,LastUpdatedRelative,CreatedRelative,__NEWLINE__,}.
        q{'',Requestors,OwnerName,ToldRelative,DueRelative,TimeLeft},
    ReportDefault =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Status,TimeLeft,DueRelative,CreatedRelative,__NEWLINE__,}.
        q{'',Requestors,QueueName,OwnerName,ToldRelative,LastUpdatedRelative},

    InvestigationDefault =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Status,TimeLeft,DueRelative,CreatedRelative,__NEWLINE__,}.
        q{'',Requestors,QueueName,OwnerName,ToldRelative,LastUpdatedRelative },

    CountermeasureDefault =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Status,TimeLeft,DueRelative,CreatedRelative,__NEWLINE__,}.
        q{'',Requestors,QueueName,OwnerName,ToldRelative,LastUpdateRelative},
    IncidentDefault =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Status,TimeLeft,DueRelative,CreatedRelative,__NEWLINE__,}.
        q{'',OwnerName,QueueName,Priority,ToldRelative,LastUpdatedRelative },

    Merge =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Requestors,OwnerName,CreatedRelative,DueRelative,QueueName},

    LinkChildren =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Requestors,OwnerName,QueueName,CreatedRelative,DueRelative},

    LinkIncident =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{OwnerName,QueueName,CreatedRelative},

    ListIncidents =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Status},

    RejectReports =>
        q{'<a href="__RTIRTicketURI__">__id__</a>/TITLE:#',}.
        q{'<a href="__RTIRTicketURI__">__Subject__</a>/TITLE:Subject',}.
        q{HasIncident,Requestors,OwnerName,CreatedRelative,DueRelative},

    BulkReply =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',
          '<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',
          KeyRequestors,KeyOwnerName,CreatedRelative,DueRelative,QueueName},

    DueIncidents =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',DueRelative,OwnerName,__Priority__,'UnreadMessages/TITLE:Updates'},

    AbandonIncidents =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{OwnerName,Priority,DueRelative},

    NewReports =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Requestors,OwnerName,DueRelative,QueueName,Take},

    ChildReport =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Status,DueRelative},

    ChildInvestigation =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Status,DueRelative},

    ChildCountermeasure =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Status,DueRelative},

    LookupTool =>
        q{'<b><a href="__RTIRTicketURI__">__id__</a></b>/TITLE:#',}.
        q{'<b><a href="__RTIRTicketURI__">__Subject__</a></b>/TITLE:Subject',}.
        q{Status,Priority,QueueName},

);

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
    RefreshHomepage
    Dashboards
    SavedSearches
    /RTIR/Elements/NewReports
    /RTIR/Elements/UserDueIncidents
    /RTIR/Elements/NobodyDueIncidents
    /RTIR/Elements/DueIncidents
    /RTIR/Elements/QueueSummary
    /RTIR/Elements/WorkWithConstituency
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

Set the default value for Resolution if there is no value when an RTIR ticket
is set to resolved or rejected.

=cut

Set(
    %RTIR_CustomFieldsDefaults,
    Resolution      => {
        resolved => "successfully resolved",
        rejected => "no resolution reached",
    },
);

=item C<%CustomFieldGroupings>

All of the configuration rules for RT CustomFieldGroupings apply and you
should review the documentation in F<etc/RT_Config.pm>

RTIR provides a separate 'object' that groupings are applied to,
RTIR::Ticket. Groupings for this object type will only be applied to
Custom Fields on Tickets in RTIR Queues. This allows you to
logically separate your Custom Field configuration between RTIR Queues
and standalone Queues in your RT instance.

We do not provide the Links core grouping because no RTIR tickets display
the Links box.  Basics, People and Dates will work as they do in core, but
keep in mind that Incidents do not display a People box, so CFs in the People
group will not render on Incidents.  Additionally, People and Dates are not always
available in all screens in RTIR so may not be the best place for Custom Fields.

=cut

Set(%CustomFieldGroupings,
    'RTIR::Ticket' => [
        'Networking'     => ['IP', 'Domain'],
        'Details' => ['How Reported','Reporter Type','Customer',
                      'Description', 'Resolution', 'Function', 'Classification', 'CVE ID',
                      'Customer',
                      'Netmask','Port','Where Blocked'],
    ],
);

=item C<%InlineEditPanelBehavior>

This configuration option is a core RT feature which accepts a
custom key for RTIR. The options are the same as those documented
in RT, but the key is C<RTIR::Ticket> as in this example:

    Set(%InlineEditPanelBehavior,
        'RTIR::Ticket' => {
            '_default'          => 'click',

            'Networking'        => 'link',
            'Details'           => 'click',
            'Dates'             => 'always',
            'People'            => 'link',
        },
    );

If no RTIR settings are defined, the settings for C<RT::Ticket>
are used. See C<etc/RT_Config.pm> for more information about
this configuration option.

=item C<$RTIR_StrictDomainTLD>

If true then RTIR will check if TLD is officially valid on domain
extraction. Set it to 0 if you need to support local TLDs or recent ones
that are not included in L<Net::Domain::TLD> yet. It's true by default.

=cut

Set($RTIR_StrictDomainTLD, 1);

=back

=head1 Countermeasures

=over 4

=item C<$RTIR_DisableCountermeasures>

If true then Countermeasure queue functionality inactive and disabled.

=cut

Set($RTIR_DisableCountermeasures, 0);

=item C<$RTIR_CountermeasureApproveActionRegexp>

When requestor replies on the countermeasure in pending state RTIR
changes state, you can set regular expresion so state would
be changed only when content matches the regexp.

See also L<RT::Action::RTIR_SetCountermeasureStatus/DESCRIPTION>.

=cut

Set($RTIR_CountermeasureApproveActionRegexp, undef);

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
    3 => { FriendlyName => 'McAfee SiteAdvisor', URL => 'http://www.siteadvisor.com/sites/__SearchTerm__'}
} );

=item C<$TracerouteCommand>

Path to traceroute command.

=cut

Set($TracerouteCommand, '/usr/sbin/traceroute');

=item C<$whois>

Whois servers for the research tool.

The outer hash key is the order the entry should appear in the WHOIS
dropdown. Host is of the form "hostname:port" and FriendlyName is
the dropdown label.

Some of the resources provided here, like IANA, are thin WHOIS clients,
so the query results can point you to other sources of WHOIS information.
You can then add these additional servers to this configuration.

=cut

Set($whois, {
    1 => {
        Host         => "whois.verisign-grs.com",
        FriendlyName => "VERISIGN",
    },
    2 => {
        Host         => "whois.pir.org",
        FriendlyName => "PIR",
    },
    3 => {
        Host         => "whois.iana.org",
        FriendlyName => "IANA",
    },
    4 => {
        Host         => "whois.internic.net",
        FriendlyName => "INTERNIC",
    },
    5 => {
        Host         => "whois.arin.net",
        FriendlyName => "ARIN",
    },
    6 => {
        Host         => "whois.ripe.net",
        FriendlyName => "RIPE",
    },
} );

=item C<$RunWhoisRequestByDefault>

RTIR prior to 2.6.1 was running whois request by default on lookup.
Now it requires user interaction. Set C<$RunWhoisRequestByDefault>
to true value return back old behaviour.

=cut

Set($RunWhoisRequestByDefault, 0);

=item C<%ExternalFeeds>

Sources for the External Feeds tool, currently RSS is supported. Provide
a Name and URI for each source and you can also provide an optional
Description.

    Set(%ExternalFeeds,
        'RSS' => [
            {   Name        => 'US Cert Alerts',
                URI         => 'https://www.us-cert.gov/ncas/alerts.xml',
                Description => 'US Cert Alerts',
            },
            ...
        ],
    );

The initial list is "US Cert Alerts", "UK NCSC Security News", "Full Disclosure",
"Threatpost Vulnerability Alerts" and "Bugtraq".

=cut

Set(%ExternalFeeds,
    'RSS' => [
        {   Name        => 'US Cert Alerts',
            URI         => 'https://www.us-cert.gov/ncas/alerts.xml',
            Description => 'US Cert Alerts',
        },
        {   Name        => 'UK NCSC Security News',
            URI         => 'https://www.ncsc.gov.uk/api/1/services/v1/all-rss-feed.xml',
            Description => 'UK NCSC Security News',
        },
        {   Name        => 'Full Disclosure',
            URI         => 'https://seclists.org/rss/fulldisclosure.rss',
            Description => 'Full Disclosure',
        },
        {   Name        => 'Threatpost Vulnerability Alerts',
            URI         => 'https://threatpost.com/category/vulnerabilities/feed/',
            Description => 'Threatpost Vulnerability Alerts',
        },
        {   Name => 'Bugtraq',
            URI => 'https://seclists.org/rss/bugtraq.rss',
            Description => 'Bugtraq feed',
        },
    ],
);

=back

=head1 Service Level Agreements (SLA)

Read F<docs/AdministrationTutorial.pod>.

=cut

1;
