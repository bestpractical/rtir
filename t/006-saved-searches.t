#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';

require "t/rtir-test.pl";

my $agent = default_agent();

$agent->follow_link_ok({text => "RT"}, "went to main RT page");

$agent->follow_link_ok({text => "Tickets"}, "went to query builder");

$agent->form_name("BuildQuery");

my $subj1 = "something".rand();
# This is the "subject matches"
$agent->field(ValueOfAttachment => $subj1);

$agent->click("AddClause");
ok_and_content_like($agent, qr/Subject LIKE &#39;$subj1/, "added new clause");

$agent->form_name("BuildQuery");
my $search1 = "saved".rand();
$agent->field(SavedSearchDescription => $search1);
$agent->click("SavedSearchSave");
ok_and_content_like($agent, 
                    qr{<option value="">My saved searches</option>.*<option value="RT::User[^"]+"> -$search1</option>}s,
                    "saved my search");

# add some other random clause in order to change the search, so we can save it again

$agent->form_name("BuildQuery");
$agent->field(ValueOfid => 200);
$agent->click("AddClause");
ok_and_content_like($agent, qr/AND id &lt; &#39;200/, "added another clause");

# figure out how to change the privacy popup. (can't use like, since that ends up clobbering $1)
$agent->content =~ qr{<select name="SavedSearchOwner">\s*<option value="RT::User-\d+">My saved searches</option>\s*<option value="RT::Group-(\d+)">DutyTeam's saved searches</option>}s;
my $DT_id = $1;

ok($DT_id > 0, "found dutyteam ID");

$agent->form_name("BuildQuery");
$agent->select(SavedSearchOwner => "RT::Group-$DT_id");
my $search2 = "saved".rand();
$agent->field(SavedSearchDescription => $search2);
$agent->click("SavedSearchSave");

# Note: this currently FAILS!  Probably an RT bug.  Basically, the
# issue is that if you save a search, it changes the UI to the
# delete/copy/save thing instead of just save, and gets rid of the
# privacy popup... however, if you then add a clause or whatever, it
# goes into a funky UI which has delete/copy/save but also a somewhat
# ignored popup... I think the bug might be that there's a popup at
# all. Anyway, really weird an needs fixing

ok_and_content_like($agent, 
                    qr{<option value="">DutyTeam's saved searches</option>.*<option value="RT::User[^"]+"> -$search2</option>}s,
                    "saved DT search");


# ... should also do tests for the RTIR "refine" thing, which is like QB.
