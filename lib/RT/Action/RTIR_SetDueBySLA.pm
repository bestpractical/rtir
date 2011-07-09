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
package RT::Action::RTIR_SetDueBySLA;

use strict;
use warnings;
use RT::Action::RTIR;
use base qw'RT::Action::RTIR';

=head2 Prepare

Always run this.

=cut


sub Prepare {
    my $self = shift;

    return 1;
}

# {{{ sub Commit

=head2 Commit

Look up the SLA and set the Due date accordingly.

=cut

sub Commit {
    my $self = shift;
    my $time = time;

    # TODO: return if it isn't an Incident Report

    # now that we know the SLA, set the value of the CF
    unless ( $self->TicketObj->FirstCustomFieldValue('SLA') ) {
        my $cf = RT::CustomField->new( $self->CurrentUser );
        $cf->LoadByNameAndQueue( Queue => $self->TicketObj->Queue, Name => 'SLA' );
        return unless $cf->id;

        my $SLAObj = RT::IR::SLAInit();
        my $sla = $SLAObj->SLA( $time );

        $self->TicketObj->AddCustomFieldValue( Field => $cf->id, Value => $sla );

    }

    # set the due date
    my $SLAObj = RT::IR::SLAInit();

    # TODO: specify a start date, but default to now
    my $due = $SLAObj->Due( $time, $SLAObj->SLA( $time ) );

    my $date = RT::Date->new( $RT::SystemUser );
    $date->Set( Format => 'unix', Value => $due );
    $self->TicketObj->SetDue( $date->ISO );

    return 1;
}

RT::Base->_ImportOverlays;

1;
