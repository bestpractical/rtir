# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2017 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
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
# END BPS TAGGED BLOCK }}}

use strict;
use warnings;

package RT::Action::RTIR_SetCountermeasureStatus;
use base 'RT::Action::RTIR';

=head1 NAME

RT::Action::RTIR_SetCountermeasureStatus - sets status of the countermeasure according to a few rules

=head1 DESCRIPTION

If transaction is inbound and status is pending then
change it to corresponding not pending status. This
rule can be protected with C<$RTIR_CountermeasureApproveActionRegexp>
option. Content of the transaction should match the regexp
if it's defined. Statuses are hardcoded and can not be
changed or this will not work properly.

If countermeasure is in an inactive status (by default 'removed')
then status changed to first possible active status
for countermeasures's lifecycle (by default 'active').

In all other cases status left unchanged.

=head1

=head2 Commit

Applies rules described above in L</DESCRIPTION> section.

=cut

sub Commit {
    my $self = shift;

    my $t = $self->TicketObj;
    my $txn = $self->TransactionObj;

    my $new;

    my $current = lc $t->Status;
    if ( $current =~ /^pending / && $txn->IsInbound ) {
        if ( my $re = RT->Config->Get('RTIR_CountermeasureApproveActionRegexp') ) {
            my $content = $txn->Content;
            return 1 if !$content || $content !~ /$re/;
        }

        if ( $current eq 'pending activation' ) {
            # switch to active state if it is reply from requestor(s)
            $new = 'active';
        } elsif ( $current eq 'pending removal' ) {
            # switch to removed state when requestor(s) replies
            $new = 'removed';
        }
    }

    if ( !$new && $t->QueueObj->LifecycleObj->IsInactive( $current ) ) {
        $new = $t->FirstActiveStatus;
    }
    return 1 unless $new;

    my ( $res, $msg ) = $t->SetStatus( $new );
    RT->Logger->warning("Couldn't set status to $new: $msg")
        unless $res;
    return 1;

}

RT::Base->_ImportOverlays;

1;
