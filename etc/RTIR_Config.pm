# Set the name of the RTIR application.

Set($rtirname , "RTIR for " . $rtname);


# Set the number of days a message awaiting an external response
# may be inactive before the ticket becomes overdue

Set($OverdueAfter, 7);


# Set the hash of whois servers
Set($whois, {1 => "localhost", 2 => "whois-demo.bestpractical.com"});


# Set the number of minutes for the SLA

Set($SLA, {'Full service' => 60, 
	   'Full service: out of hours' => 120, 
	   'Reduced service' => 120});


# Set the defaults for RTIR custom fields
# default values are case-sensitive

Set($_RTIR_SLA_inhours_default, "Full service");
Set($_RTIR_SLA_outofhours_default, "Full service: out of hours");
Set($_RTIR_HowReported_default, "Email");
#Set($_RTIR_ReporterType_default, "");
#Set($_RTIR_IP_default, "");
#Set($_RTIR_NetMask_default, "");
#Set($_RTIR_Port_default, "");
#Set($_RTIR_WhereBlocked_default, "");
Set($_RTIR_Constituency_default, "EDUNET");
#Set($_RTIR_Function_default, "");
#Set($_RTIR_Classification_default, "");


# Set the Business Hours for your organization
# if left unset, defaults are Monday through Friday 09:00 to 18:00

#Set($BusinessHours, {
#    0 => { Name => 'Sunday',
#           Start => undef,
#	   End => undef},
#
#    1 => { Name => 'Monday',
#           Start => '09:00',
#	   End => '18:00'},
#
#    2 => { Name => 'Tuesday',
#           Start => '09:00',
#	   End => '18:00'},
#
#    3 => { Name => 'Wednesday',
#           Start => '09:00',
#	   End => '18:00'},
#
#    4 => { Name => 'Thursday',
#           Start => '09:00',
#	   End => '18:00'},
#
#    5 => { Name => 'Friday',
#           Start => '09:00',
#	   End => '18:00'},
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

Set ($RTIRMergeSearchResultFormat, qq{___RTIR_Radio__,
'<B><A HREF="$RT::WebPath/Ticket/Display.html?id=__id__">__id__</a></B>/TITLE:#',
'<B><A HREF="$RT::WebPath/Ticket/Display.html?id=__id__">__Subject__</a></B>/Title:Subject',
__Requestors__,__OwnerName__,__CreatedRelative__,__DueRelative__});

1;
