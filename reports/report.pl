# of new reports outstanding at month start
my $outstanding = RT::Tickets->new($session{'CurrentUser'});
$outstanding->Query("Queue = 'Incident Reports' AND Created <= '$monthstart' AND ( Resolved >= '$monthstart' OR Resolved IS NULL)");


# of new reports created during the month
my $tix_created = RT::Tickets->new($session{'CurrentUser'});
$tix_created->Query("Queue = 'Incident Report' AND Created >= '$monthstart' AND Created <= '$monthend');


# of new reports resolved/closed/deleted during the month
# does this mean "number of reports closed during the month or number of reports created during the month that were also closed during the month?

my $tix_resolved = RT::Tickets->new($session{'CurrentUser'});
$tix_resolved->Query("Queue = 'Incident Report' AND Created >= '$monthstart' AND Created <= '$monthend' AND Resolved >= '$monthstart' AND Resolved <= '$monthend'");


# of new reports oustanding at month end 
# same question: does this mean "number of reports closed during the month or number of reports created during the month that were also closed during the month?

my $tix_unresolved = RT::Tickets->new($session{'CurrentUser'});
$tix_unresolved->Query("Queue = 'Incident Report' AND Created >= '$monthstart' AND Created <= '$monthend' AND (Resolved >= '$monthend' OR Resolved IS NULL");





         # of new reports created during the month broken down by
         classification
         my $windows  = { 'full service serious' => (within 1 hour),
                          'full service minor' =>  (within 2 hours),  
                         'reduced service emergency'=> (call out n/a)
                         'requests for information' =>  (1 day)
                         };
   
	 
 
          foreach my $service_level (@$Classifications) {
		my $class_tix = RT::Tickets->new($session{'CurrentUser'});
		$class_tix->Query("Queue = 'Incident Reports' AND Created >= '$monthstart' AND Created <= $monthend AND Created <= $monthend AND SLA = '$service_level'");

         }

                 All tickets created in queue IncidentReport created after
                 monthstart and before monthend where 
                 there was outbound correspondence within $windows{$Classification};

No need to break down incident type against response time.
classification (eg response time) needs to be calculated somehow, and to 
take account of nwh. (eg the clock stops tickets at 1800 and starts 
again at 0800 and reports received at 8am on a Saturday are not measured 
until 0800 Monday ownwards...etc)

eg
 All tickets created in queue IncidentReport created after monthstart and
 before monthend where there was outbound correspondence within
 $windows{$Classification};

my $sla_check = RT::Tickets->new($session{'CurrentUser'});
        $sla_check->Limit(FIELD => 'Created', OPERATOR => '>=', VALUE => $monthstart);
        $sla_check->Limit(FIELD => 'Created', OPERATOR => '<=', VALUE => $monthstart);

while (my $t = $sla_check->Next) {
       
}


         # of email messages created by CERT staff, broken down by Queue (incident, incident report, investigation)
         # of email messages received by CERT, broken down by Queue (incident, incident report, investigation)
        my $txns = RT::Transactions->new($session{'CurrentUser'});
        $txns->Limit(FIELD => 'Created', OPERATOR => '>=', VALUE => $monthstart);
        $txns->Limit(FIELD => 'Created', OPERATOR => '<=', VALUE => $monthstart);
        while (my $txn = $txns->Next) {
                my $q = $txn->TicketObj->QueueObj->Name;
                my $inbound = ($txn->IsInbound || 0);
                $created{$q}{$inbound}++;
        } 




#         Average time from creation to close for incidents for all incidents
#         closed within this time period
# 	This doesn't currently take into account "business hours"


        my $avgtime = RT::Tickets->new($session{'CurrentUser'});
	$avgtime->Query(Queue = 'Incident Reports' AND Resolved >= '$monthstart' AND Resolved <= '$monthend');

        
        my $i;
        my $total_diff;
        while (my $t = $avgtime->Next) {
                $i++;
                my $ctime = $t->CreatedObj->Unix;
                my $rtime = $t->ResolvedObj->Unix;
                
                my $diff = $rtime - $ctime;
                $total_diff += $diff;

        }
        my $average_secs = $total_diff/$i;



use Time::Local qw/timelocal_nocheck/;

=head2 BusinessHours

Takes a paramhash with the following parameters
	
	Start => The start of the period in question in seconds since the epoch
	End => The end of the period in question in seconds since the epoch

Returns a Set::IntSpan of business hours for this period of time.

=cut


sub BusinessHours {
	my %args = ( Start => undef,
		     End => undef,
	             @_);


    my $bizdays = {
        0 => { Name  => 'Sunday',
               Start => undef,
               End   => undef, },
        1 => { Name  => 'Monday',
               Start => '9:00',
               End   => '18:00', },
        2 => { Name  => 'Tuesday',
               Start => '9:00',
               End   => '18:00', },
        3 => { Name  => 'Wednesday',
               Start => '9:00',
               End   => '18:00', },
        4 => { Name  => 'Thursday',
               Start => '9:00',
               End   => '18:00', },
        5 => { Name  => 'Friday',
               Start => '9:00',
               End   => '18:00', },
        6 => { Name  => 'Saturday',
               Start => undef,
               End   => undef, };
      };

    # Split the Start and End times into hour/minute specifications
    foreach my $day ( keys %$bizdays ) {
        my $day_href = $bizdays{$day};
        foreach my $which qw(Start End) {
            if (    $day_href->{$which}
                 && $day_href->{$which} =~ /^(\d+)\D(\d+)$/ ) {
                $day_href->{ $which . 'Hour' }   = $1;
                $day_href->{ $which . 'Minute' } = $2;
            }
        }
    }

    # now that we know what the business hours are for each day in a week,
    # we need to find all the business hours in the period in question.

    # Create an intspan of the period in total.
    my $business_period = Set::IntSpan->new($args{'Start'}."-".$args{'End'});

    my @start = localtime($args{'Start'});
    my $start[3] = $start[3] - $start[6];
    my $week_start = timelocal_nocheck(@start);


    # jump back to the first day (Sunday) of the last week before the period 
    # began. 

    # create an empty intspan of "business hours"

    # for each week until the end of the week in seconds since the epoch
    # is outside the business period in question
        # add the business seconds in that week to the business hours intspan.
        # (Be careful to use timelocal to convert times in the week into actual
        # seconds, so we don't lose at DST transition)

    # find the intersection of the business period intspan and the  business
    # hours intspan. (Because we want to trim any business hours that fall 
    # outside the business period)

    # TODO: Remove any holidays from the business hours

    # TODO: Add any special times to the business hours

    # Return the intspan of business hours.

    


}

