# {{{ BEGIN BPS TAGGED BLOCK
# 
# COPYRIGHT:
#  
# This software is Copyright (c) 1996-2004 Best Practical Solutions, LLC 
#                                          <jesse@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
# 
# }}} END BPS TAGGED BLOCK
#
package RT::Action::RTIR_SetIncidentReportState;
require RT::Action::Generic;

use strict;
use vars qw/@ISA/;
@ISA = qw(RT::Action::Generic);

=head2 Prepare

Always run this.

=cut


sub Prepare {
    my $self = shift;

    return 1;
}

# {{{ sub Commit

=head2 Commit

Set the Block state.

=cut

sub Commit {
    my $self = shift;

    my $State;
    my $cf = RT::CustomField->new($self->TransactionObj->CurrentUser);
    $cf->LoadByNameAndQueue(Queue => $self->TicketObj->QueueObj->Id, Name => '_RTIR_State');
    unless ($cf->Id) { 
        return(1);
    }
    if ($self->TicketObj->Status eq 'new' or $self->TicketObj->Status eq 'open' or $self->TicketObj->Status eq 'stalled') {
	$State = 'new';
        my $parents = RT::Tickets->new($self->TransactionObj->CurrentUser);
        $parents->LimitHasMember($self->TicketObj->id);
        $parents->LimitQueue(VALUE => 'Incidents');
	if ($parents->First) {
	    $State = 'open';
        }
    } elsif ($self->TicketObj->Status eq 'resolved') {
	$State = 'resolved';
    } elsif ($self->TicketObj->Status eq 'rejected') {
	$State = 'rejected';
    } else {
	return 0;
    }
    $self->TicketObj->AddCustomFieldValue(Field => $cf->id, Value => $State);
    return 1;
}

# }}}

eval "require RT::Action::RTIR_SetIncidentReportState_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetIncidentReportState_Vendor.pm});
eval "require RT::Action::RTIR_SetIncidentReportState_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetIncidentReportState_Local.pm});

1;
