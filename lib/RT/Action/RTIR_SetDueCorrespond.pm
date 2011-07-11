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
use strict;
use warnings;

package RT::Action::RTIR_SetDueCorrespond;
use base 'RT::Action::RTIR';

# {{{ sub Commit

=head2 Commit

Look up the SLA and set the Due date to the configured 
(on the queue or global) Due date, defaulting to 7 business
days from now.

=cut

sub Commit {
    my $self = shift;

    my $bizhours = RT::IR::BusinessHours();
	
    my $date = RT::Date->new( $RT::SystemUser );
    my $due = ( $self->TicketObj->QueueObj->DefaultDueIn || (RT->Config->Get('OverdueAfter')) || 7 ) ;
    $date->SetToNow;
    $date->AddDays( $due );

    $due = $bizhours->first_after( $date->Unix );
    $date->Set( Format => 'unix', Value => $due );
    $self->TicketObj->SetDue( $date->ISO );

    return 1;
}

RT::Base->_ImportOverlays;

1;
