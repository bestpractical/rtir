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
package RT::Action::RTIR_ChangeParentOwnership;
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

Change the ownership of parent incident.

=cut

sub Commit {
    my $self = shift;

    # change owner of parent Incident(s)
    my $query = "Queue = 'Incidents' AND HasMember = " . $self->TicketObj->Id;

    my $parents = new RT::Tickets($self->TransactionObj->CurrentUser);
    $parents->FromSQL($query);
    while (my $Incident = $parents->Next) {
	if ( $incident->OwnerObj->id != $self->TransactionObj->NewValue) {
	    my ($res, $msg); 
	    my $user = new RT::CurrentUser($self->TransactionObj->CurrentUser);
	    $user->Load($self->TransactionObj->Creator);
	    my $t = new RT::Ticket($user);
	    $t->Load($incident->id);
	    if ($self->TransactionObj->NewValue == $self->TransactionObj->Creator) {
		($res, $msg) = $t->Steal();
	    } else {
		($res, $msg) = $t->SetOwner($self->TransactionObj->NewValue);
	    }
	}
    }
    return 1;
}

# }}}

eval "require RT::Action::RTIR_ChangeParentOwnership_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_ChangeParentOwnership_Vendor.pm});
eval "require RT::Action::RTIR_ChangeParentOwnership_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_ChangeParentOwnership_Local.pm});

1;
