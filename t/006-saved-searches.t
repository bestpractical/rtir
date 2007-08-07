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

$agent->form_name("BuildQuery");
is($agent->value('SavedSearchDescription'), $search1, "name is correct");
ok_and_content_like($agent, qr{Privacy:\s*My saved searches}s, "privacy is fixed");

# add some other random clause in order to change the search, so we can save it again

$agent->form_name("BuildQuery");
$agent->field(ValueOfid => 200);
$agent->click("AddClause");
ok_and_content_like($agent, qr/AND id &lt; 200/, "added another clause");

$agent->form_name("BuildQuery");
is($agent->value('SavedSearchDescription'), $search1, "name is correct");
ok_and_content_like($agent, qr{Privacy:\s*My saved searches}s, "privacy is fixed");

# copy query
$agent->form_name("BuildQuery");
$agent->click("SavedSearchCopy");

$agent->form_name("BuildQuery");
is($agent->field('SavedSearchDescription'), "$search1 copy", "copied search");

# figure out how to change the privacy popup. (can't use like, since that ends up clobbering $1)
$agent->content =~ qr{<option value="RT::User-\d+">My saved searches</option>\s*<option value="RT::Group-(\d+)">DutyTeam's saved searches</option>}s;
my $DT_id = $1;
ok($DT_id, "found dutyteam ID");

$agent->select(SavedSearchOwner => "RT::Group-$DT_id");
my $search2 = "saved".rand();
$agent->field(SavedSearchDescription => $search2);
$agent->click("SavedSearchSave");
ok_and_content_like($agent, 
                    qr{<option value="">DutyTeam's saved searches</option>.*<option value="RT::Group[^"]+"> -$search2</option>}s,
                    "saved DT search");


# ... should also do tests for the RTIR "refine" thing, which is like QB.
