# Set the name of the RTIR application.

Set($rtirname , "RTIR for " . $Organization);

# Set the number of days a message awaiting an external response
# may be inactive before the ticket becomes overdue

Set($overdueafter, 7);

# Set the hash of whois servers
Set($whois, {1 => "localhost", 2=> "whois.fucknsi.com"});

# This is the string that indicates a reply, and which will be
# pre-pended to subjects when you reply to tickets.

# Set($ReplyString , "Re:");

1;
