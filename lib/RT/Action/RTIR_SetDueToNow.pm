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
package RT::Action::RTIR_SetDueToNow;

use strict;
use warnings;

use RT::IR;
use base 'RT::Action::RTIR';

=head1 NAME

RT::Action::RTIR_SetDueToNow - set due date to now

=head1 DESCRIPTION

Set Due date of a ticket to now.

=head1 METHODS

=head2 Prepare

Always commit action.

=cut

sub Prepare { return 1 }

=head2 Commit

Set the Due date based on your SLA_Response settings

=cut

sub Commit {
    my $self = shift;

    my $SLAObj = RT::IR::SLAInit();
    $SLAObj->SetInHoursDefault(RT->Config->Get('SLA_Response_InHours'));
    $SLAObj->SetOutOfHoursDefault(RT->Config->Get('SLA_Response_OutOfHours'));
    $SLAObj->SetBusinessHours( RT::IR::BusinessHours() );

    # get the due date
    my $time = time;
    my $due = $SLAObj->Due( $time, $SLAObj->SLA( $time ) );

    my $date = RT::Date->new($RT::SystemUser);
    $date->Set( Format => 'unix', Value => $due );
    my ($status, $msg) = $self->TicketObj->SetDue( $date->ISO );
    $RT::Logger->error($msg) unless $status;

    $RT::Logger->debug( "Set Due to now: ". $date->ISO );

    return 1;
}

eval "require RT::Action::RTIR_SetDueToNow_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetDueToNow_Vendor.pm});
eval "require RT::Action::RTIR_SetDueToNow_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetDueToNow_Local.pm});

1;
