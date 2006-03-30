#!/usr/bin/perl -w

# 
# sometimes &nbsp; is printable. Ex. http://{BASE_URL}/RTIR/Merge.html?id=18&
# 
# when IR has quite big size then field "Message" while creating incident is 
# empty.
# 
# "Resolve" is absent in Investigation window. State is open and we can't 
# change it.
# 
# RTIR > Incident Reports > Refine 
# Hmmm... in previous version search fields were on the results page.  It was 
# better.
# 
# no values in "owner" field ( Ticket > Search )
# 
# IR doesn't change state when is linked to incident. State is "new" so we 
# won't click "resolve".
# 
# RT > Search > searching is succesfule, but no ticket is displayed
# 
# In Global we can only add privilages to user. Revoke isn't working. One-way 
# change :-)
# 
# state isn't changing after taking IR - stay "new".
# 
# The install process should warn about:
# You have to install DBIx::SearchBuilder >= 1.40
# You have to install Module::Install::RTx
# make testdeps should run with --with-modperl[1|2]
# README -> configuration for apache doesn't work with version 2.0
# make fixdeps doesn't work properly in RT, at the end we used the cpan shell 
#   directly.
# SeLinux, you should be awared about SeLinux in RedHat and Fedora, the default 
#   root folder (/opt) doesn't work due to SeLinux
# the file RT.log in /rootRT/var/log/ is not created in installation time, and 
#   at least it should be created.
# it should have a fixdeps in RTIR like in RT, at least it would be desirable.
# add-rtfm-objects: you should warn that we have to change the  path of this 
#   script for running.

# It seems that it's not possible to remove group rights from a queue. I did 
# the following:
# Start in RT.
# Click on 'Configuration'.
# Click on 'Queues'.
# Click on any Queue. For example 'Blocks'.
# Click on 'Group Rights'.
# Under 'User defined groups', check any box. For example, 'Watch'.
# Click on button 'Modify Group Rights'.
# The result is that the right 'Watch' is still in the list of current rights. 
# It seems that this issue is only dealing with removing. Adding new rights 
# works fine.
# 
# RTIR at a glance, we should see the ten IRs, not all of them.
# There is no way to change it.
# 
# Not possible action take from RTIR at a glance.
# 
# Not possible action steal from RTIR at a glance.
# 
# We SHOULD be able to "quick reject" without taking the ticket.
# 
# Incident main screen.
# We can't see the IRs or Inv or Block what are resolved, we want to see this 
#   ticket by default.
# When we create a Incident, the IR which is linked to the new Incident, is new 
#   (wrong), it has to be open. In fact, to change the state we have to edit 
#   the IR, there is no tab to do that. Nevertheless it's working properly when #   we link a IR  to an created Incident.
# When we create a new block, we must quote the text of the incident.
# There is no tab to resolve the block, we can see just the reply one.
# There is no tab to resolve a investigation, just the reply one.
# When we are resolving an Incident, all the IRs, Inv, Block should be clicked 
#   by default.
# There is a thing what confuses me a lot, when we do an action, we can see all 
#   the action took by RT. I.e. When a IR changes, RT shows the State 
#   modification and the RTIR_Status modification. We want to see just the 
#   action took by RTIR
# If a IR is linked to several Incidents, this IR should be resolved when all 
#   the Incidents are resolved, this IR shouldn't be resolved meanwhile there 
#   are open Incidents.
# The right "ModifySelf" for the members of Duty Team should be granted by 
#   default.
# D.3.1.1 is partly done, why? Because when we close an Incident, this action 
#   resolves all the IRs, even whether there is an IRs which is linked to 
#   another open Incident.
# D.3.1.1. the problem now is when we abandon a ticket, all the IRs are 
#   rejected, but this action should be care about IRs which are linked to 
#   other incidents, because those one shouldn't be rejected. I don't know what 
#   to do here, the best probably would be to delete the link in the Incident, 
#   and reflect in any way that this IRs was linked in that Incident.
# D.3.1.2. How can we do it??? We couldn't see any way to do it.
# D.3.1.3 We can see this custom field in the Incident home, neither in the 
#   basics.
# D.3.3.4. doesn't work, when we move the ticket from general to IR, it should 
#   have, at least, the due, starts. Filled out.
# When we are in Bulk Reject, there are no tabs of navigation through the IRs 
#   if there are more than i.e. 50.
# When we are looking at the body of a mail in the history of a 
#   IR/Incident/Inv, we realise that long URLs are not wrapped. And the subject 
#   too. So you should modify it to be able to wrap everything
# When we refine a query, and we go to Results, and we go to get the graphic, 
#   the query sql appears in the middle of page, it shouldn't see.
# It should appear a RTFM tab in RTIR at a glance.
# When we have a Incident/IR/Inv, and we create a RTFM article, but this new 
#   article is not linked to the Incident/IR/Inv.
# When I'm creating an Interface by the interface web, and I want to attache a 
#   file, it crash down
#   error:   
#   context:  
#   ...  
#   665:00:00
#   666:00:00
#   667:00:00
#   668:00:00
#   669:00:00
#   670:00:00
#   671:00:00
#   672:00:00
#   673:00:00
#   ...  
#   code stack:  
#   /usr/local/rt37/lib/RT/Interface/Web.pm:586
#   /usr/local/rt37/share/html/RTIR/Create.html:433
#   /usr/local/rt37/share/html/RTIR/Incident/Create.html:197
#   /usr/local/rt37/share/html/RTIR/Create.html:338
#   /usr/local/rt37/share/html/autohandler:244
#   raw error
# 
# 
# Comment on ticket via the toolbar works, but comment using the link in the 
#   ticket items displays: Not Found The requested URL /RTIR/RTIR/Update.html 
#   was not found on this server.

# Blocks-> Block Ticket-> Merge: shows in colum '&nbsp;'

# This option is not available, but in previous versions this option was there

# RTIR should take the IR if it belongs to Nobody

# Got no mail, but also ticket Status changed from 'open' to 'stalled'

# Comment on items appear at the bottom of the ticket, maybe by design. Comment 
#   and reply buttoms  should be related to the message which you are replying 
#   or commenting.
# Remark: splitting an investigation sends an email to the original 
#   correspondent, By default RTIR shouldn't send anything to the original 
#   corresponde
# There is no button provided to resolve an investigation, when the state of 
#   that ticket is 'open'
# There is no button provided to resolve an investigation, when the state of 
#   that ticket is 'open'
# Impossible, as investigations can not be closed, see above.
# When splitting a Block-ticket and attaching a file, the file is not attached
# There is no button 'pending removal' provided for an block, when the state 
#   of that ticket is 'active'. Then, from the state 'pending removal', there 
#   should be button to change to state 'removal'
# This option is not available, but in previous versions this option was there
# Adding works fine. Removing of rights does not work
# RTIR includes a type of custom identifier, which can be applied to Incident 
#   Reports. For Investigations, the specified customer IDs do not appear. In 
#   the DB 2 identical _RTIR_Customer fields exist. One for Incident Reports, 
#   one for Investigations. Therefore not consistent in Q Incident Report and 
#   Q Investigation. If the two CF-fields are deliberate, it’s unclear, 
#   which field for which Q applies. Due to lack of documentation, it’s 
#   also unclear how this field should appear in the Incident report. ( Menu 
#   and Select Box available )
# Cannot be verified due to lack of documentation. It’s unclear how this 
#   is/was implemented.
# In an Incident Report zero or more values can be applied, but only one name 
#   appears when ticket redisplayed
# D.9.1.8 Qualification text, if not we don't know what 0 represents
# Section 'Quick search' via RT shows a summary of new, open and stalled 
#   tickets. Clicking on queue names, new, open or stalled in this section 
#   gives you an emtpy screen. Even if this queue contains tickets. 
# Bug:Saving queries does not work.
# Feature request reporting: We want to be able to create a reporting about 
#   multiple queues( number of tickets in queues incident reports, incidents 
#   and investigations etc). Therefore, we need an option to construct queries 
#   (via a refine search option) which extracts from a selection of queues
# 
# Wish: Database fsck / sanitize (eg. recovering the cachedgroupmembers
#   table)  - does RTx::Shredder help?
# 
# Session management: Must login several times before the session is
#   stable. Cause of the problem unclear
# 
# Documentation issue: RTFM install instructions require us to install:
#    perl -MCPAN -e'install HTML::Format'
# which doesnt exist.
# 
# RTFM couldn't be installed with Postgres because --dba is emptpy string,
#   defaulting to root which doesn't exist in Pg.
# 
# Customer: Two distinct CF, indistinguishable in CF-Edit-Page except for
#   the Id (17 vs. 18) visible in the URL
# 
# Link Report to multiple incidents:
#   Cannot unlink
#   Link Report page: No way back to Report (except back button)
# 
# bash-2.05b# make initdb
# include
# /usr/local/src/RTIR-Test/ms1/rtir-20060309/rtfm-2.1/inc/Module/Install.pm
# include inc/Module/Install/RTx/Factory.pm
# include inc/Module/Install/Base.pm
# /usr/local/bin/perl -Ilib -I/opt/rt3/lib
# /usr/local/rt3ms1/sbin/rt-setup-database --action schema --datadir etc
# #NAME?
# In order to create or update your RT database,this script needs to
# connect to your Pg instance on localhost as .
# Please specify that user's database password below. If the user has no
# database
# password, just press return.
# 
# Password:
# DBI connect('dbname=rt3ms1;host=localhost','',...) failed: FATAL:  role
# root does not exist
#  at /usr/local/rt3ms1/sbin/rt-setup-database line 166
# Failed to connect to dbi:Pg:dbname=template1;host=localhost as : FATAL: 
# role "root" does not exist
# ...returned with error: 65280
# *** Error code 255
# 
# Stop in /usr/local/src/RTIR-Test/ms1/rtir-20060309/rtfm-2.1.
# bash-2.05b
# 
# MOST IMPORTATNT: More documentation about the new requirements.
