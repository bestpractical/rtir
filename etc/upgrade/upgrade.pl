#!/usr/bin/perl

use warnings;
use strict;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt3/local/lib /opt/rt3/lib);

use RT::Interface::CLI qw(CleanEnv GetCurrentUser GetMessageContent loc); 
use RT::Tickets; 
use RT::Template;
use RT::Queue;

#Clean out all the nasties from the environment
CleanEnv();

# Load the config file
RT::LoadConfig();

#Connect to the database and get RT::SystemUser and RT::Nobody loaded
RT::Init();

my $current_user = GetCurrentUser();

# Get the open incidents with no due dates
my $incidents = RT::Tickets->new( $current_user );
$incidents->FromSQL(
    "Queue = 'Incidents' AND Due <= '1970-01-02'"
    ." AND ( ". join( ' OR ', map "Status = '$_'", RT::Queue->ActiveStatusArray() ) ." )"
);

my $base_query = "( Queue = 'Incident Reports' OR Queue = 'Investigations' OR Queue = 'Blocks' )"
    ." AND ( ". join( ' OR ', map "Status = '$_'", RT::Queue->ActiveStatusArray() ) ." )"
    ." AND Due > '1970-01-02'";

# Get the children for each Incident
my $children = RT::Tickets->new( $current_user );

FetchNext( $incidents, 1 );
while ( my $inc = FetchNext( $incidents ) ) {
    $children->FromSQL( "( $base_query ) AND MemberOf = " . $inc->Id );
    $children->OrderBy( FIELD => 'Due', ORDER => 'ASC' );
    $children->RowsPerPage(1);
    my $child = $children->First or next;

    # Set the due date of the Incident to the due date of the child
    $inc->SetDue( $child->DueObj->ISO );
}

use constant PAGE_SIZE => 100;
sub FetchNext {
    my ($objs, $init) = @_;
    if ( $init ) {
        $objs->RowsPerPage( PAGE_SIZE );
        $objs->FirstPage;
        return;
    }

    my $obj = $objs->Next;
    return $obj if $obj;
    $objs->NextPage;
    return $objs->Next;
}

