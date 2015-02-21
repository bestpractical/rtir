# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2014 Best Practical Solutions, LLC
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
package RT::Action::RTIR_ChangeChildOwnership;
use strict;
use warnings;
use base 'RT::Action::RTIR';

=head2 Commit

Change the ownership of children.

=cut

sub Commit {
    my $self = shift;
    my $transaction = $self->TransactionObj;

    my $actor = $self->CreatorCurrentUser;

    my $action_cb;
    if ( $transaction->NewValue == $actor->id ) {
        $action_cb = sub {
            return $_[0]->Steal if $_[0]->Owner != $RT::Nobody->id;
            return $_[0]->Take;
        };
    } else {
        $action_cb = sub { return $_[0]->SetOwner( $transaction->NewValue ) }
    }

    # change owner of child Incident Reports, Investigations, Blocks
    my $query =  "(Lifecycle = '".RT::IR->lifecycle_report."'"
                ." OR Lifecycle ='". RT::IR->lifecycle_investigation."'"
                ." OR Lifecycle = '".RT::IR->lifecycle_countermeasure."'"
                .") AND MemberOf = ". $self->TicketObj->Id
                ." AND Owner != ". $transaction->NewValue;
    my $members = RT::Tickets->new( $actor );
    $members->FromSQL( $query );

    while ( my $member = $members->Next ) {
        my ($res, $msg) = $action_cb->( $member );
        RT->Logger->info( "Couldn't change owner: $msg" ) unless $res;
    }
    return 1;
}

RT::IR->ImportOverlays;

1;
