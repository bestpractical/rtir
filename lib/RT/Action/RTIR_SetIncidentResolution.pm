# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2021 Best Practical Solutions, LLC
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

package RT::Action::RTIR_SetIncidentResolution;
use strict;
use warnings;
use base 'RT::Action::RTIR';

=head2 Commit

Set the resolution if there is no value.

=cut

sub Commit {
    my $self = shift;

    my $t = $self->TicketObj;
    my $cf = RT::CustomField->new( $self->TransactionObj->CurrentUser );
    $cf->LoadByNameAndQueue( Queue => $t->QueueObj->Id, Name => 'Resolution' );
    return 1 unless $cf->Id;

    my $status = $t->Status;
    if ( $t->QueueObj->IsActiveStatus( $status ) ) {
        # on re-open, drop resolution
        my $txn = $self->TransactionObj; my $type = $txn->Type;
        return 1 unless $type eq "Status" || ( $type eq "Set" && $txn->Field eq "Status" );
        return 1 unless $t->QueueObj->IsInactiveStatus( $txn->OldValue );
        return 1 unless my $value = $t->FirstCustomFieldValue( $cf->id );
        $t->DeleteCustomFieldValue( Field => $cf->id, Value => $value );
        return 1;
    }

    return 1 unless $t->QueueObj->IsInactiveStatus( $status );

    my $value = RT->Config->Get('RTIR_CustomFieldsDefaults')->{'Resolution'}{$status};
    return 1 unless $value;

    return 1 if $t->FirstCustomFieldValue( $cf->id );

    my ($res, $msg) = $t->AddCustomFieldValue( Field => $cf->id, Value => $value );
    RT->Logger->warning("Couldn't add custom field value: $msg") unless $res;
    return 1;
}

RT::IR->ImportOverlays;

1;
