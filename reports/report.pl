# of new reports outstanding at month start
my $outstanding = RT::Tickets->new($session{'CurrentUser'});
$outstanding->FromSQL("Queue = 'Incident Reports' AND Created <= '$monthstart' AND ( Resolved >= '$monthstart' OR Resolved IS NULL)");


# of new reports created during the month
my $tix_created = RT::Tickets->new($session{'CurrentUser'});
$tix_created->FromSQL("Queue = 'Incident Report' AND Created >= '$monthstart' AND Created <= '$monthend');


# of new reports resolved/closed/deleted during the month
# does this mean "number of reports closed during the month or number of reports created during the month that were also closed during the month?

my $tix_resolved = RT::Tickets->new($session{'CurrentUser'});
$tix_resolved->FromSQL("Queue = 'Incident Report' AND Created >= '$monthstart' AND Created <= '$monthend' AND Resolved >= '$monthstart' AND Resolved <= '$monthend'");


# of new reports oustanding at month end 
# same question: does this mean "number of reports closed during the month or number of reports created during the month that were also closed during the month?

my $tix_unresolved = RT::Tickets->new($session{'CurrentUser'});
$tix_unresolved->FromSQL("Queue = 'Incident Report' AND Created >= '$monthstart' AND Created <= '$monthend' AND (Resolved >= '$monthend' OR Resolved IS NULL");



print "At the start of the month (".localtime($monthstart)."):\n";
print "\n\n";
print "Outstanding incident reports: ".$outstanding->Count."\n";
print "Reports closed between ".localtime($monthstart). " and ". localtime($monthend).": " $tix_resolved->Count;
print "Reports created between ".localtime($monthstart). " and ". localtime($monthend)." which were unresolved as of ". localtime($monthend).": " $tix_unresolved->Count;



         # of new reports created during the month broken down by
         classification
         my $windows  = { 'full service serious' => (within 1 hour),
                          'full service minor' =>  (within 2 hours),  
                         'reduced service emergency'=> (call out n/a)
                         'requests for information' =>  (1 day)
                         };

	 
 
          foreach my $service_level (@$Classifications) {
		my $class_tix = RT::Tickets->new($session{'CurrentUser'});
		    $class_tix->FromSQL("Queue = 'Incident Reports' AND Created >= '$monthstart' AND Created <= $monthend AND 'Incident Reports.{SLA}' = '$service_level'");
            print "$service_level Incident Reports created between ".localtime($monthstart). " and ".localtime($monthend).": ".$class_tix->Count."\n";
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

$sla_check->FromSQL("Created >= $monthstart AND Created <= $monthend AND Queue='Incident Reports'");


# Get a Business::Hours object for the period in question

my $business_hours = Business::Hours->new();
$business_hours->set_business_hours(%working_hours);
$business_hours->for_timespan(Start => $monthstart, End => $monthend);

while (my $t = $sla_check->Next) {
    # XXX: is this bug? we don't use this variables
    my $sla = $t->FirstCustomFieldValue('SLA');
    my $time_on_clock = $business_hours->between($t->CreatedObj->Unix, $t->ResolvedObj->Unix);
 


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
	$avgtime->FromSQL(Queue = 'Incident Reports' AND Resolved >= '$monthstart' AND Resolved <= '$monthend');

        
        my $i;
        my $total_diff;
        while (my $t = $avgtime->Next) {
                $i++;
                my $ctime = $t->CreatedObj->Unix;
                my $rtime = $t->ResolvedObj->Unix;
                
                my $diff = $rtime - $ctime;
                $total_diff += $diff;

        }
        # XXX: we don't use this. What this code for
        my $average_secs = $total_diff/$i;



}

