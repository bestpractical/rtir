#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";
use RT::IR::Test tests => 19;

RT::Test->started_ok;
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
like($agent->value('SavedSearchOwner'), qr/^RT::User-\d+$/, "privacy is correct");

# add some other random clause in order to change the search, so we can save it again

$agent->form_name("BuildQuery");
$agent->field(ValueOfid => 200);
$agent->click("AddClause");
ok_and_content_like($agent, qr/AND id &lt; 200/, "added another clause");

$agent->form_name("BuildQuery");
is($agent->value('SavedSearchDescription'), $search1, "name is correct");
like($agent->value('SavedSearchOwner'), qr/^RT::User-\d+$/, "privacy is correct");

# copy query
$agent->form_name("BuildQuery");
$agent->click("SavedSearchCopy");

$agent->form_name("BuildQuery");
is($agent->field('SavedSearchDescription'), "$search1 copy", "copied search");

# figure out how to change the privacy popup. (can't use like, since that ends up clobbering $1)
my ($group_id) = grep defined && length,
    map { /^RT::Group-(\d+)$/ and $1 }
    $agent->current_form->find_input('SavedSearchOwner')->possible_values;

my $DT_id = $group_id;
ok($DT_id, "found dutyteam ID");

$agent->select(SavedSearchOwner => "RT::Group-$DT_id");
my $search2 = "saved".rand();
$agent->field(SavedSearchDescription => $search2);
$agent->click("SavedSearchSave");

$agent->form_name("BuildQuery");
is($agent->field('SavedSearchDescription'), $search2, "correct name of the search");
is($agent->value('SavedSearchOwner'), "RT::Group-$DT_id", "privacy is correct");


# ... should also do tests for the RTIR "refine" thing, which is like QB.
