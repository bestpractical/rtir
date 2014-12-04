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

package RT::CustomFieldValues::Constituency;

use strict;
use warnings;

use base qw(RT::CustomFieldValues::External);

#Constituencies are only usable as a single value
$RT::CustomField::FieldTypes{Constituency} = {
        sort_order => 10,
        selection_type => 1,

        labels => [ 'Select one value' ],                   # loc

        render_types => {
            single => [ 'Select box',              # loc
                        'Dropdown',                # loc
                        'List',                    # loc
                      ]
        },
};


=head1 NAME

RT::CustomFieldValues::Constituency - Provide's RTIR's Constituencies

=head1 SYNOPSIS

Visit the RTIR Admin Constituencies page to manage constituencies.

=head1 METHODS


=head2 SourceDescription

Returns a brief string describing this data source.

=cut

sub SourceDescription {
    return "RTIR's special Constituency Field";
}

=head2 ExternalValues

Returns an arrayref containing a hashref for each possible value in this data
source, where the value name is the group name.

=cut

sub ExternalValues {
    my $self = shift;

    my @res;
    my $i = 0;
    my $cfvs = RT::CustomFieldValues->new( $self->CurrentUser );
    my $cf = $self->CustomFieldObject;
    unless ($cf->Id) {
        RT->Logger->error("Tried to load an External Custom Field without providing a CF");
    }
    $cfvs->Limit( FIELD => 'CustomField', VALUE => $cf->Id );

    my $main_queue = RT::Queue->new($self->CurrentUser);
    for my $obj ($cf->ACLEquivalenceObjects) {
        next unless (ref $obj eq 'RT::Queue');
        $main_queue->Load( $obj->Id );
        last;
    }
    unless ($main_queue->Id) {
        RT->Logger->debug("Unable to find Queue from Custom Field, loading Incidents");

        $main_queue->Load( 'Incidents' );
    }

    # Only needed until we don't override RT::Queue->HasRight in RT::IR as much
    $main_queue->{'disable_constituency_right_check'} = 1;
    my $show_all = $main_queue->CurrentUserHasRight('OwnTicket') ? 1 : 0;

    while( my $cfv = $cfvs->Next ) {
        unless ($show_all) {
            my $name = $cfv->Name;
            my $subqueue = RT::Queue->new($self->CurrentUser);
            next unless ($subqueue->LoadByCols(Name => $main_queue->Name . " - ".$name) && $subqueue->id && $subqueue->CurrentUserHasRight('OwnTicket'))
        }
        push @res, {
            name        => $cfv->Name,
            sortorder   => $i++,
        };
    }
    return \@res;
}

1;
