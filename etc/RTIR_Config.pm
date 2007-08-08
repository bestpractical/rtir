# XXX: we push config metadata into RT, but we need
# need interface to load config options metadata from
# extensions in RT core

use RT::IR::Config;
RT::IR::Config::Init();


# Set the name of the RTIR application.

Set($rtirname , "RTIR for " . RT->Config->Get('rtname') );

# By default, RT only displays text attachments inline up to the first 16k
# RTIR will display them no matter how long they are
#
Set($MaxInlineBody,0);

# Set the number of days a message awaiting an external response
# may be inactive before the ticket becomes overdue

Set($OverdueAfter, 7);


# Set the hash of whois servers
# Host is of the form "hostname:port"
Set($whois, {
    1 => { Host => "localhost", },
    2 => {
        Host         => "whois-demo.bestpractical.com",
        FriendlyName => "BPS Demo Server",
    },
} );


# Set the name of the Business::SLA class
# Use this if you have a custom SLA module
# Set($SLAModule, "Business::MySLA");

# Set the number of minutes for the SLA

Set($SLA, {
    'Full service'               => { BusinessMinutes => 60,    RealMinutes => 0 },
    'Full service: out of hours' => { BusinessMinutes => 120,   RealMinutes => 0 },
    'Reduced service'            => { BusinessMinutes => 120,   RealMinutes => 0 },
    'Now (in business hours)'    => { BusinessMinutes => 0,     RealMinutes => 0 },
#   '60 Real Minutes'            => { BusinessMinutes => undef, RealMinutes => 60 },
} );

# Set the SLA for responses
Set($SLA_Response_InHours,    'Now (in business hours)');
Set($SLA_Response_OutOfHours, 'Now (in business hours)');

# Set the SLA for re-opened tickets
Set($SLA_Reopen_InHours,    'Full service');
Set($SLA_Reopen_OutOfHours, 'Full service: out of hours');

# Set the defaults for RTIR custom fields
# default values are case-sensitive

Set($_RTIR_SLA_inhours_default,         "Full service");
Set($_RTIR_SLA_outofhours_default,      "Full service: out of hours");
Set($_RTIR_HowReported_default,         "Email");
Set($_RTIR_ReporterType_default,        "");
Set($_RTIR_IP_default,                  "");
Set($_RTIR_Netmask_default,             "");
Set($_RTIR_Port_default,                "");
Set($_RTIR_WhereBlocked_default,        "");
Set($_RTIR_Function_default,            "");
Set($_RTIR_Classification_default,      "");
Set($_RTIR_Description_default,         "");
Set($_RTIR_Resolution_resolved_default, "successfully resolved");
Set($_RTIR_Resolution_rejected_default, "no resolution reached");

# Constituency behaviour
# read more about constituencies in docs/Constituency.pod
#
# default value
Set( $_RTIR_Constituency_default,        "EDUNET" );

# Constituency propagation algorithm
# valid values are 'no', 'inherit', 'reject'
Set( $_RTIR_Constituency_Propagation,    'no' );

# Set the Business Hours for your organization
# if left unset, defaults are Monday through Friday 09:00 to 18:00

#Set($BusinessHours, {
#    0 => { Name => 'Sunday',
#           Start => undef,
#           End => undef},
#
#    1 => { Name => 'Monday',
#           Start => '09:00',
#           End => '18:00'},
#
#    2 => { Name => 'Tuesday',
#           Start => '09:00',
#           End => '18:00'},
#
#    3 => { Name => 'Wednesday',
#           Start => '09:00',
#           End => '18:00'},
#
#    4 => { Name => 'Thursday',
#           Start => '09:00',
#           End => '18:00'},
#
#    5 => { Name => 'Friday',
#           Start => '09:00',
#           End => '18:00'},
#
#    6 => { Name => 'Saturday',
#           Start => undef,
#           End => undef},
#} );


# This is the string that indicates a reply, and which will be
# pre-pended to subjects when you reply to tickets.

# Set($ReplyString , "Re:");

# RTIR_OldestRelatedTickets controls how far back, in days, RTIR
# should look for tickets which might contain a specific string,
# such as an IP address.

Set($RTIR_OldestRelatedTickets, 60);

# Default formats for RTIR search results
Set($RTIRSearchResultFormats, {
    ReportDefault =>
        q{'<b><a HREF="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          '__CustomField.{_RTIR_State}__/TITLE:State',
          __LastUpdatedRelative__,
          __CreatedRelative__,
          __NEWLINE__,
          '',__Requestors__,__OwnerName__,__ToldRelative__,__DueRelative__,__TimeLeft__},
    InvestigationDefault =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          '__CustomField.{_RTIR_State}__/TITLE:State',
          __LastUpdatedRelative__,
          __CreatedRelative__,
          __NEWLINE__,
          '', __Requestors__, __OwnerName__, __ToldRelative__, __DueRelative__, __TimeLeft__},
    
    BlockDefault =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          '__CustomField.{_RTIR_State}__/TITLE:State',
          __LastUpdatedRelative__,
          __CreatedRelative__,
          __NEWLINE__,
          '', __Requestors__, __OwnerName__, __ToldRelative__, __DueRelative__, __TimeLeft__},

    IncidentDefault =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          '__CustomField.{_RTIR_State}__/TITLE:State',
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
          '<a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a>',
          __Requestors__, __OwnerName__, __CreatedRelative__, __DueRelative__},

    BulkReply =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          __Requestors__, __OwnerName__, __CreatedRelative__, __DueRelative__},

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
          '__CustomField.{_RTIR_State}__</I>/TITLE:State',
          __DueRelative__},

    ChildInvestigation =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          '__CustomField.{_RTIR_State}__</I>/TITLE:State',
          __DueRelative__},

    ChildBlock =>
        q{'<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
          '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
          '__CustomField.{_RTIR_State}__</I>/TITLE:State',
           __DueRelative__},

} );


# Enable this option if you want jump to display screen after saving changes
# on the edit screen.
Set($DisplayAfterEdit, 1);

# path to traceroute command
Set($TracerouteCommand, '/usr/sbin/traceroute');


# Components that available to add on the first page of the RTIR
Set(@RTIR_HomepageComponents, qw(
    QuickCreate
    Quicksearch
    MyAdminQueues
    MySupportQueues
    MyReminders
    /RTIR/Elements/NewReports
    /RTIR/Elements/UserDueIncidents
    /RTIR/Elements/NobodyDueIncidents
    /RTIR/Elements/DueIncidents
    /RTIR/Elements/QueueSummary
    RefreshHomepage
));

# if true then Blocks queue functionality inactive and disabled
Set($RTIR_DisableBlocksQueue, 0);

# When requestor replies on the block in pending state RTIR
# changes state, you can set regular expresion so state would
# be changed only when it matches
Set($RTIR_BlockAproveActionRegexp, undef);

# Define list of enabled MakeClicky extensions; RTIR extends the
# default 'httpurl', and additionally provides 'ip', 'ipdecimal',
# 'email', 'domain' and 'RIPE'.  It is possible to add your own types
# of clicky links using callbacks; see
# html/Callbacks/RTIR/Elements/MakeClicky/Default for an example.
# NOTE that list is order-sensetive, when one action matches text
# other actions don't apply to the same matched text
Set(@Active_MakeClicky, qw(httpurl_overwrite ip email domain));

1;
