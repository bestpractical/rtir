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
RT->Config->Set( LogToScreen => 'warning' );

#Connect to the database and get RT::SystemUser and RT::Nobody loaded
RT::Init();

my $current_user = GetCurrentUser();

# Get the open incidents with no due dates
my $incidents = RT::Tickets->new( $current_user );
my $incidents_query = 
    "Queue = 'Incidents' AND Due <= '1970-01-02'"
    ." AND ( ". join( ' OR ', map "Status = '$_'", RT::Queue->ActiveStatusArray() ) ." )";
$incidents->FromSQL( $incidents_query );

print "\n\nGoing to update due dates of Incidents where it's not set\n";

print "Query for incidents: $incidents_query\n\n";

my $base_query = "( Queue = 'Incident Reports' OR Queue = 'Investigations' OR Queue = 'Blocks' )"
    ." AND ( ". join( ' OR ', map "Status = '$_'", RT::Queue->ActiveStatusArray() ) ." )"
    ." AND Due > '1970-01-02'";

print "Base query for children: $base_query\n\n";

# Get the children for each Incident
my $children = RT::Tickets->new( $current_user );

require File::Temp;
my $tmp = new File::Temp; # croak on error

FetchNext( $incidents, 1 );
while ( my $inc = FetchNext( $incidents ) ) {
    $children->FromSQL( "( $base_query ) AND MemberOf = " . $inc->Id );
    $children->OrderBy( FIELD => 'Due', ORDER => 'ASC' );
    $children->RowsPerPage(1);
    my $child = $children->First or next;

    print $tmp $inc->id ." ". $child->DueObj->ISO ."\n";
}

seek $tmp, 0, 0;
while ( my $str = <$tmp> ) {
    chomp $str;
    my ($id, $date) = split /\s/, $str, 2;
    my $inc = RT::Ticket->new( $RT::SystemUser );
    $inc->Load( $id );
    unless ( $inc->id ) {
        print STDERR "Couldn't load incident #$id\n";
        next;
    }
    my ($status, $msg) = $inc->SetDue( $date );
    unless ( $status ) {
        print STDERR "Couldn't set due date of the incident #$id: $msg\n";
        next;
    }
    print "Updated inc #$id, due is $date\n";
}
print "done.\n";

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

