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

package RT::Action::RTIR_SetBlockState;
use base 'RT::Action::RTIR_SetState';

=head1 GetState

Returns state of the C<Block>.

=cut

sub GetState {
    my $self = shift;

    my $txn = $self->TransactionObj;
    return unless $txn->Type eq 'Correspond';

    my $status = lc $self->TicketObj->Status;
    if ( $status =~ /^pending / && $txn->IsInbound ) {
        if ( my $re = RT->Config->Get('RTIR_BlockAproveActionRegexp') ) {
            my $content = $txn->Content;
            return '' if !$content || $content !~ /$re/;
        }

        if ( $status eq 'pending activation' ) {
            # switch to active state if it is reply from requestor(s)
            return 'active';
        } elsif ( $status eq 'pending removal' ) {
            # switch to removed state when requestor(s) replies
            return 'removed';
        }
        else {
            return '';
        }
    }

    return 'active' if $status eq 'removed';
}

RT::Base->_ImportOverlays;

1;
