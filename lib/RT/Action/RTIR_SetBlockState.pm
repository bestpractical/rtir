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
package RT::Action::RTIR_SetBlockState;

use strict;
use base 'RT::Action::RTIR_SetState';

=head1 GetState

Returns state of the C<Block>.

=cut

sub GetState {
    my $self = shift;
    my %state = (
        new      => 'pending activation',
#        open     => 'active',
        stalled  => 'pending removal',
        resolved => 'removed',
        rejected => 'removed',
    );
    my $t = $self->TicketObj;
    my $txn = $self->TransactionObj;
    my $status = $t->Status;
    my $old_state = $t->FirstCustomFieldValue('State');

    if ( $status eq 'new' && $txn->Type eq 'Correspond' && $txn->IsInbound && $old_state eq 'pending activation' ) {
        if ( my $re = RT->Config->Get('RTIR_BlockAproveActionRegexp') ) {
            my $content = $txn->Content;
            return '' if !$content || $content !~ /$re/;
        }
        my ($val, $msg) = $t->SetStatus( 'open' );
        $RT::Logger->error("Couldn't change status: $msg") unless $val;
        return 'active';
    }

    return $state{ $status } if $state{ $status };
    # all code below is related to open status

    # if block was removed (resolved/rejected) we reactivate it
    return 'active' if $old_state eq 'removed';

    if ( $txn->Creator != $RT::SystemUser->id ) {
        # if a duty team member changes Status directly then we want to activate
        if ( ($txn->Type eq 'Status' || ($txn->Type eq 'Set' && $txn->Field eq 'Status')) &&
                $self->CreatorCurrentUser->PrincipalObj->HasRight(
                    Right => 'ModifyTicket', Object => $t
                )
        ) {
            return 'active';
        }
    }

    # next code related to requestor's correspondents
    return '' unless $txn->Type eq 'Correspond';
    return '' unless $t->Requestors->HasMember( $txn->CreatorObj->PrincipalObj );

    if ( my $re = RT->Config->Get('RTIR_BlockAproveActionRegexp') ) {
        my $content = $txn->Content;
        return '' if !$content || $content !~ /$re/;
    }

    if ( $old_state eq 'pending activation' ) {
        # switch to active state if it is reply from requestor(s)
        return 'active';
    } elsif ( $old_state eq 'pending removal' ) {
        # switch to removed state when requestor(s) replies
        # but do it via changing status!
        my ($val, $msg) = $t->SetStatus( 'resolved' );
        $RT::Logger->error("Couldn't change status: $msg") unless $val;
        return '';
    }

    return '';
}

eval "require RT::Action::RTIR_SetBlockState_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetBlockState_Vendor.pm});
eval "require RT::Action::RTIR_SetBlockState_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/RTIR_SetBlockState_Local.pm});

1;
