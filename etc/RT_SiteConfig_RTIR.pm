# Set the name of the RTIR application.

Set($rtirname , "RTIR for " . $Organization);

# Set the number of days a message awaiting an external response
# may be inactive before the ticket becomes overdue

Set($overdueafter, 7);

# Set the comma-delimited list of whois servers

Set($whois, {"localhost", "whois.fucknsi.com"});

1;
