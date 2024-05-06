# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2024 Best Practical Solutions, LLC
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

package RT::Action::RTIR_SetHowReported;
use strict;
use warnings;
use base 'RT::Action::RTIR';

=head1 NAME

RT::Action::RTIR_SetHowReported

=head1 DESCRIPTION

Sets the "How Reported" custom field based on the interface RT reports
was used to create the ticket. See L<RT/CurrentInterface> for the list of
interfaces RT can detect.

This action does nothing if the interface is not in the list of values
for "How Reported", so you can safely remove values in the custom field
configuration if some don't make sense for your reporting.

This action also does nothing if a value is already set.

=cut

sub Commit {
    my $self = shift;

    my $cf = RT::CustomField->new($self->TransactionObj->CurrentUser);
    $cf->LoadByNameAndQueue(Queue => $self->TicketObj->QueueObj->Id, Name => 'How Reported');
    return unless $cf->Id;

    # Get the current values of this CF
    my $Values = $self->TicketObj->CustomFieldValues( $cf->id );

    # Don't overwrite if it's already set
    return 1 if $Values->Count;

    # Get acceptable values for this CF
    my $ValuesObj = $cf->ValuesObj();

    # Verify that the current interface is a valid value
    while ( my $Value = $ValuesObj->Next ) {
        if ( $Value->Name eq RT->CurrentInterface() ) {
            my ($ok, $msg) = $self->TicketObj->AddCustomFieldValue( Field => $cf->id, Value => RT->CurrentInterface() );

            if ( not $ok ) {
                RT->Logger->error("Unable to set custom field " . $cf->Name . ": $msg");
                return 0;
            }

            return 1;
        }
    }

    return 1;
}

RT::IR->ImportOverlays;

1;
