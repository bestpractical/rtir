#!/usr/bin/perl

use warnings;
use strict;

use lib ("/opt/rt3/lib", "/opt/rt3/local/lib");

use RT::Interface::CLI qw(CleanEnv GetCurrentUser GetMessageContent loc); 
use RT::Tickets; 
use RT::Template;

#Clean out all the nasties from the environment
CleanEnv();

# Load the config file
RT::LoadConfig();

#Connect to the database and get RT::SystemUser and RT::Nobody loaded
RT::Init();

# Get the open incidents with no due dates
my $incidents = new RT::Tickets(GetCurrentUser());
$incidents->FromSQL("Queue = 'Incidents' AND Due <= '1970-01-01' AND (Status = 'new' OR Status = 'open')");

# Get the children for each Incident
my $children = new RT::Tickets(GetCurrentUser());
while (my $inc = $incidents->Next) {
    $children->FromSQL("MemberOf = " . $inc->Id . " AND (Queue = 'Incident Reports' OR Queue = 'Investigations' OR Queue = 'Blocks') AND (Status = 'new' OR Status = 'open')");
    $children->OrderBy(FIELD => 'Due', ORDER => 'ASC');

    # Find the most due child
    my $child = $children->First;
    next unless $child;

    # Set the due date of the Incident to the due date of the child
    $inc->SetDue($child->DueObj->ISO);
}

